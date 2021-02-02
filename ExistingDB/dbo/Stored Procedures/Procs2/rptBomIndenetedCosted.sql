-- =============================================    
-- Author:  Yelena Shmidt    
-- Create date: 03/20/2014    
-- Description: Procedure for the Bill of material indented and costed    
-- Modified:  09/03/2014 DRP:  needed to change the parameter from @lcUniqBomParent to @lcUniqKey so I could use the same Parameters that already existed for other Bom Reports.     
--         Also needed to change 'CostedBom' because it was not properly calculating the Total Cost for Sub-Assm that happen to not have any components.     
--         Added @tResults table so I could later come back and update the cost and TotalCost values for Sub-Assm when needed as far as the 3 Rules are concerned.    
--         Added @T table in order to populate the results with the parent detail     
--    09/08/2014 DRP:  declare @lcDate to be used to filter out the eff_dt and Term_dt     
--         needed to isnull to the cost values within the CostedSub and CostedBom sections    
--    10/10/14 YS replace invtmfhd table with 2 new tables    
-- 10/24/2014 DRP: If the users were able to get the Customer AVL to save blank (no avls at all) then the item would drop off of the results. Needed to make changes to display the part and indicate that there are no AVL's loaded    
-- 02/18/2015 DRP: Added one more parameter @lcStatus to show only Active parts or not    
--    09/22/15 DRP:  added the @lcDate to the <<INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,1,0,@UserId,@lcDate>> to make sure that it is pulling only the Active items from the BOM    
--    09/08/16 DRP: added @IncludeMakeBuy, @lcExplode , @showIndentation parameters per request to show Make/Buy items on the resulting report. also changed << INSERT INTO @tBom EXEC  [BomIndented]>> to use those new parameters    
--- 03/28/17 YS changed length of the part_no column from 25 to 35    
--- 08/14/17 YS added PR currency to BomIndented    
-- 05/24/2019 Shrikant added column Bom_note for assembly note  
-- 05/27/2019 The following 3 parameter not used in stimulsoft reports parameters due to this throwing string to bit conversion issue so I removed from parameter and declare with default value same as it is @IncludeMakeBuy@lcExplode@lcExplode  
-- 02/14/2020 Vijay G: increased size of custname column 
-- rptBomIndenetedCosted @lcUniqKey= '_1LR0NALBN', @userId ='49f80792-e15e-4b62-b720-21b360e3108a', @lcStatus'Active'  
-- =============================================    
CREATE PROCEDURE [dbo].[rptBomIndenetedCosted]     
 --@lcUniqBomParent char(10)=null, --09/03/2014 DRP:  replaced with the below @lcUniqKey    
 @lcUniqKey char(10) = null,    
 @lcStatus char(8) = 'Active' --02/18/2015 DRP: Added    
 ,@userId uniqueidentifier =null    
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;   
  
 -- 05/27/2019 The following 3 parameter not used in stimulsoft reports parameters due to this throwing string to bit conversion issue so I removed from parameter and declare with default value same as it is @IncludeMakeBuy@lcExplode@lcExplode  
 DECLARE  
  @IncludeMakeBuy bit = 1  --if the value is 1 will explode make/buy parts ; if 0 - will not (default 1) --09/08/16 DRP:  Added     
 ,@lcExplode char (3) = 'Yes'  --if left as No then the BOM will only display top level components.  If Yes, then the report will explode out components down to all sublevles --09/08/16 DRP:  Added    
 ,@showIndentation Bit = 1  --add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later) --09/08/16 DRP:  Added    
    
    -- Insert statements for procedure here    
 --- 03/28/17 YS changed length of the part_no column from 25 to 35    
 declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) ,    
  ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char (10),Dept_id char(8),Item_note varchar(max),Offset numeric(4,0),    
  Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),    
  Phantom_make bit,StdCost numeric(13,5),Make_buy bit,Status char(10),TopQty numeric(10,2),qty numeric(9,2),Level integer ,path varchar(max),sort varchar(max)    
  --- 03/28/17 YS changed length of the part_no column from 25 to 35    
  ,UniqBomNo char(10),Buyer char(3),    
  ---08/14/17 YS added PR currency     
  stdcostpr numeric(13,5),funcFcUsed_uniq char(10),PrFcUsed_uniq char(10),    
  CustPartNo char(35),CustRev char(8),CustUniqKey char(10)  
  -- 05/24/2019 Shrikant added column Bom_note for assembly note  
  ,Bom_note varchar(max)  
  )    
    
    
/*09/03/2014 DRP:  added the @t so I could get the Parent information*/     
--- 03/28/17 YS changed length of the part_no column from 25 to 35 
-- 02/14/2020 Vijay G: increased size of custname column    
DECLARE @t TABLE (ParentPartNo CHAR (35),ParentRev CHAR(8),Parent_Desc char (45),ParentUniqkey CHAR (10),ParentMatlType char(10),ParentBomCustNo char(10)    
     ,ParentCustName char(50),PUseSetScrap bit,PStdBldQty numeric(8),LaborCost numeric (14,6),Bom_Note text)     
      
INSERT @T select part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''),USESETSCRP,STDBLDQTY,LABORCOST, bom_note    
   from inventor     
     left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO     
   where UNIQ_KEY = @lcUniqKey    
     and PART_SOURC <> 'CONSG'     
    
declare @lcDate smalldatetime = null --09/08/2014 DRP:  ADDED THE @LCDATE TO BE USED TO FILTER OUT THE EFF_DT AND TERM_DT    
  select @lcDate = DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0)    
    
      -- get indented BOM do not explode make/Buy parts    
    INSERT INTO @tBom EXEC  [BomIndented] @lcUniqKey,@IncludeMakeBuy,@ShowIndentation,@UserId,@lcDate; --09/22/15 DRP:  Added    
    
/*09/03/2014 DRP:  added the @results table*/    
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int    
--- 03/28/17 YS changed length of the part_no column from 25 to 35    
declare @Results as table (Level integer,item_no numeric(4),part_no char(35),revision char(8),part_sourc char(10),viewPartNo varchar(max),ViewRevision char(8),Part_class char(8),part_type char(8)    
     ,Descript char (45),MATLTYPE char(10),Term_dt date,Eff_dt date,Used_inKit char(1),U_of_meas char(4),Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit    
     ,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5),Make_buy bit,Status char(10),TopQty numeric(10,2),qty numeric(9,2),sort varchar(max),Buyer char(3)    
     --- 03/28/17 YS changed length of the part_no column from 25 to 35    
     ,CustPartNo char(35),CustRev char(8),Cost numeric (13,5),totalCost numeric(13,5),PARTMFGR char(8),MFGR_PT_NO char(30),ORDERPREF int,UNIQMFGRHD char(10)    
     ,MfgrMatlType char(10),MATLTYPEVALUE char(20),UniqBomNo char(10),bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),mPriceNote varchar(max),    
     ---08/14/17 YS added PR currency     
     stdcostpr numeric(13,5),funcFcUsed_uniq char(10),PrFcUsed_uniq char(10),CostPr numeric (13,5),TotalCostPr numeric (13,5))    
     
 ;WITH CostedSub    
 as    
 -- find cost of the MAKE (excluding Make/Buy) and PHNATOM components based on their respective components (scrap is not taken into consideration)    
 ---08/14/17 YS added PR currency    
 (SELECT b.bomparent,isnull(SUM(ROUND(B.StdCost*B.Qty*B.TopQty,5)),0.00) as SumParent,    
   isnull(SUM(ROUND(B.StdCostPr*B.Qty*B.TopQty,5)),0.00) as SumParentPr    
  FROM @tBom B     
  WHERE bomParent IN     
  (SELECT Uniq_key from @tBom  where Part_sourc='PHANTOM' or (Part_sourc ='MAKE' and make_Buy=0))     
  GROUP BY b.bomparent    
 )    
 ,    
    
 /*******************************************************************************************/    
 /*find cost of each component (scrap is not taken into consideration) and total - totalCost*/    
 /*******************************************************************************************/    
 --09/03/2014 DRP:  replacement for the below, otherwise it was not properly calculating the total cost for Sub-Assm that happen to not have any components.    
 CostedBom    
 as (    
 ---08/14/17 YS added PR values    
 select b.*    
   ,CASE WHEN  b.Part_sourc='PHANTOM' or (b.Part_sourc ='MAKE' and b.make_Buy=0)     
    THEN ISNULL(CostedSub.SumParent,ROUND(B.StdCost*B.Qty*B.TopQty,5)) ELSE ROUND(B.StdCost*B.Qty*B.TopQty,5) END Cost,    
    CASE WHEN  b.Part_sourc='PHANTOM' or (b.Part_sourc ='MAKE' and b.make_Buy=0)     
    THEN ISNULL(CostedSub.SumParentPr,ROUND(B.StdCostPr*B.Qty*B.TopQty,5)) ELSE ROUND(B.StdCostPr*B.Qty*B.TopQty,5) END CostPr    
    ,isnull(s.totalCost,0.00)+isnull(nocomp.totalCost,0.00) as totalCost    
    ,isnull(s.totalCostpr,0.00)+isnull(nocomp.totalCostpr,0.00) as totalCostpr    
  from @tBom b     
    LEFT OUTER JOIN CostedSub ON b.UNIQ_KEY=CostedSub.bomParent      
    CROSS JOIN (SELECT SUM(ROUND(StdCost*Qty*TopQty,5)) as totalCost ,    
        SUM(ROUND(StdCostPr*Qty*TopQty,5)) as totalCostPr     
       from @tBom t2     
       where part_sourc='MAKE'     
         and Make_buy=0     
         and NOT exists (select 1 from CostedSub where CostedSub.bomparent= t2.uniq_key)) noComp    
    CROSS JOIN (SELECT SUM(ROUND(StdCost*Qty*TopQty,5)) as totalCost ,    
         SUM(ROUND(StdCostPr*Qty*TopQty,5)) as totalCostPr    
       from @tBom     
       where Part_sourc<>'PHANTOM'     
         AND (Part_sourc<>'MAKE' OR (part_sourc='MAKE' and make_Buy=1))) S    
 )    
     
 --select * from CostedBom    
 --09/03/2014 removed the below and replaced with the above    
 -- ;WITH CostedSub    
 --as    
 ---- find cost of the MAKE (excluding Make/Buy) and PHNATOM components based on their respective components (scrap is not taken into consideration)    
 --(SELECT b.bomparent,SUM(ROUND(B.StdCost*B.Qty*B.TopQty,5)) as SumParent     
 -- FROM @tBom B     
 -- WHERE bomParent IN     
 -- (SELECT Uniq_key from @tBom  where Part_sourc='PHANTOM' or (Part_sourc ='MAKE' and make_Buy=0))     
 -- GROUP BY b.bomparent    
 --),    
 /**/    
    
 ,    
 /***********************/    
 /*added AVL information*/    
 /***********************/    
 -- 10/10/14 YS replace invtmfhd table with 2 new tables    
 BomWithAvl    
 AS    
 (    
 -- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int    
 select B.* ,    
  M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE    
   FROM CostedBom B LEFT OUTER JOIN InvtMpnLink L ON B.CustUniqKey=L.UNIQ_KEY     
  -- 10/10/14 YS replace invtmfhd table with 2 new tables    
  --FROM CostedBom B LEFT OUTER JOIN Invtmfhd L ON B.CustUniqKey=Invtmfhd.UNIQ_KEY     
  LEFT OUTER JOIN MfgrMaster M ON L.MfgrMasterID=M.Mfgrmasterid    
  WHERE B.CustUniqKey<>' '    
  AND (L.IS_DELETED=0 OR l.Is_deleted is NULL)    
  and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =m.PARTMFGR and A.MFGR_PT_NO =m.MFGR_PT_NO )    
 UNION ALL    
  select B.*,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD ,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE    
  FROM CostedBom B LEFT OUTER JOIN InvtMpnLink L ON B.UNIQ_KEY=L.UNIQ_KEY     
  -- 10/10/14 YS replace invtmfhd table with 2 new tables    
  --FROM CostedBom B LEFT OUTER JOIN InvtMfhd L ON B.UNIQ_KEY=InvtMfhd.UNIQ_KEY     
  LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId    
  WHERE B.CustUniqKey=' '    
  AND (L.IS_DELETED =0 or L.is_deleted is null)     
  and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )    
  )    
    
---08/14/17 YS added PR values     
insert into @Results ([Level] ,item_no,part_no,revision,part_sourc ,viewPartNo ,ViewRevision,Part_class,part_type    
     ,Descript ,MATLTYPE ,Term_dt ,Eff_dt ,Used_inKit ,U_of_meas ,Scrap ,SetupScrap ,USESETSCRP    
     ,STDBLDQTY ,Phantom_make ,StdCost ,Make_buy ,[Status] ,TopQty ,qty ,sort ,Buyer     
     ,CustPartNo ,CustRev,Cost ,totalCost ,PARTMFGR ,MFGR_PT_NO ,ORDERPREF ,UNIQMFGRHD    
     ,MfgrMatlType ,MATLTYPEVALUE ,UniqBomNo ,bomParent ,bomcustno ,UNIQ_KEY,    
     stdcostpr ,funcFcUsed_uniq ,PrFcUsed_uniq ,CostPr ,TotalCostPr    
     )     
select  level,item_no,part_no,revision,part_sourc,viewPartNo,ViewRevision,Part_class,part_type,Descript,MATLTYPE,Term_dt,Eff_dt,Used_inKit,U_of_meas    
  ,Scrap,SetupScrap,USESETSCRP,STDBLDQTY,Phantom_make,StdCost,Make_buy,Status,TopQty,qty,sort,Buyer,CustPartNo,CustRev,Cost,totalCost,PARTMFGR,MFGR_PT_NO    
  ,ORDERPREF,UNIQMFGRHD,MfgrMatlType,MATLTYPEVALUE    
  ,UniqBomNo,bomParent,bomcustno,UNIQ_KEY,    
  stdcostpr ,funcFcUsed_uniq ,PrFcUsed_uniq ,CostPr ,TotalCostPr    
from BomWithAvl B1 order by Sort    
    
    
    
--09/03/2014 DRP:  added in the below rules in order to make sure that cost is correct for Phantoms,Sub-assm,etc. .     
/**************************/      
/*01/29/08 YS - New rules:*/    
/**************************/    
 -- 1. If one of the components Parts are MAKE and not MAKE_BUY and have components assign to it we will not show cost of the MAKE parts itself    
 -- we will only show cost of its subcomponents.    
 -- 2. If the component part is Make and not make_buy and has no parts assign to it we will show cost of the part itself.    
 -- 3. If the component part is MAKE and Make_Buy we will show price for the part and will show 0.00 cost for the subcomponents.    
    
/***********************************************************************************************************/    
/*this result applys to the rule #1 above - Make and Phantom parts in this SQL will have no cost of its own*/    
/***********************************************************************************************************/    
 ---08/14/17 YS added PR Values    
 ;    
 with    
 ZMakeWithSub as    
  (select * from @Results as R1 where ((Part_sourc='MAKE' AND  Make_buy = 0) OR Part_sourc='PHANT')     
  AND Uniq_key IN (SELECT BomParent FROM @Results))     
      
 UPDATE @Results     
 SET  StdCost = 0.00,Cost =0.00,mPriceNote = 'Standard price for this part is omitted, because the report will consider the cost of this part''s components.'    
 WHERE UniqBomNo IN (SELECT UniqBomNo from ZMakeWithSub)    
    
    
/**********************************************************************************************************************************************/    
/*This SQL applys to rule #2, but we do not really need to do anything--I brought it fwd from VFP code just in case we needed it as reference*/    
/**********************************************************************************************************************************************/    
 /*  SELECT * ;    
 *!*   FROM zBomRep ;    
 *!*   WHERE Part_sourc="MAKE" AND NOT Make_buy ;    
 *!*  AND Uniq_key NOT IN (SELECT BomParent FROM zBomRep) ;    
 *!*  INTO CURSOR ZMakeOnly    
 */    
     
    
/*******************************************************************************************************/    
/*this result applys to the rule #3 above and we will replace the cost of the subcomponents to be zero.*/    
/*******************************************************************************************************/    
 ---08/14/17 YS added PR Values    
 ;with    
 ZMakeBuyWithSub as     
  (SELECT * FROM @Results WHERE Part_sourc='MAKE' AND Make_buy = 1 AND Uniq_key IN (SELECT BomParent FROM @Results))     
    
 Update @Results     
 set  StdCost = 0.00,Cost =0.00,     
   StdCostPr = 0.00,CostPr =0.00,     
   mPriceNote = 'Standard price of the subcomponents of this part is omitted, because the part is marked as a MAKE/BUY and report will consider this part''s own cost.'     
 WHERE BomParent IN (SELECT Uniq_key from ZMakeBuyWithSub)    
    
--- 08/14/17 YS split the end result to remove PR values for the system were FC=0    
IF (dbo.fn_IsFCInstalled() = 0)    
 select R2.[Level] ,R2.item_no,R2.part_no,R2.revision,R2.part_sourc ,R2.viewPartNo ,R2.ViewRevision,R2.Part_class,R2.part_type    
     ,R2.Descript ,R2.MATLTYPE ,R2.Term_dt ,R2.Eff_dt ,R2.Used_inKit ,R2.U_of_meas ,R2.Scrap ,R2.SetupScrap ,R2.USESETSCRP    
     ,R2.STDBLDQTY ,R2.Phantom_make ,R2.StdCost ,R2.Make_buy ,R2.[Status] ,R2.TopQty ,R2.qty ,R2.sort ,R2.Buyer     
     ,R2.CustPartNo ,R2.CustRev,R2.Cost ,R2.totalCost ,R2.PARTMFGR ,R2.MFGR_PT_NO ,R2.ORDERPREF ,R2.UNIQMFGRHD    
     ,R2.MfgrMatlType ,R2.MATLTYPEVALUE ,R2.UniqBomNo ,R2.bomParent ,R2.bomcustno ,R2.UNIQ_KEY,R2.mPriceNote,    
     T.ParentPartNo,t.ParentRev,t.Parent_Desc,t.ParentMatlType,t.ParentCustName,t.PUseSetScrap,t.PStdBldQty     
 from @Results R2     
  cross join @t as T    
 --08/14/17 YS chnage were    
 where @lcStatus<>'Active' OR (@lcStatus='Active' and [Status] = 'Active')    
ELSE    
         
 select R2.[Level] ,R2.item_no,R2.part_no,R2.revision,R2.part_sourc ,R2.viewPartNo ,R2.ViewRevision,R2.Part_class,R2.part_type    
     ,R2.Descript ,R2.MATLTYPE ,R2.Term_dt ,R2.Eff_dt ,R2.Used_inKit ,R2.U_of_meas ,R2.Scrap ,R2.SetupScrap ,R2.USESETSCRP    
     ,R2.STDBLDQTY ,R2.Phantom_make ,R2.StdCost ,R2.Make_buy ,R2.[Status] ,R2.TopQty ,R2.qty ,R2.sort ,R2.Buyer     
     ,R2.CustPartNo ,R2.CustRev,isnull(ff.symbol,space(3)) as funcSymbol, R2.Cost ,R2.totalCost ,    
     isnull(PF.symbol,space(3)) as prSymbol, R2.CostPr ,R2.totalCostPr ,    
     r2.stdcostpr ,r2.funcFcUsed_uniq ,r2.PrFcUsed_uniq ,    
     R2.PARTMFGR ,R2.MFGR_PT_NO ,R2.ORDERPREF ,R2.UNIQMFGRHD    
     ,R2.MfgrMatlType ,R2.MATLTYPEVALUE ,R2.UniqBomNo ,R2.bomParent ,R2.bomcustno ,R2.UNIQ_KEY,R2.mPriceNote,    
     T.ParentPartNo,t.ParentRev,t.Parent_Desc,t.ParentMatlType,t.ParentCustName,t.PUseSetScrap,t.PStdBldQty     
 from @Results R2     
    OUTER APPLY (select FcUsed_Uniq,symbol from fcused where fcused.FcUsed_Uniq=r2.FUNCFCUSED_UNIQ) FF    
   OUTER APPLY (select FcUsed_Uniq,symbol from fcused where fcused.FcUsed_Uniq=r2.PRFCUSED_UNIQ) PF    
  cross join @t as T    
 --08/14/17 YS chnage were    
 where @lcStatus<>'Active' OR (@lcStatus='Active' and [Status] = 'Active')    
    
END