-- =============================================    
-- Author:  Debbie    
-- Create date: 09/03/2014    
-- Description: Bill of Material , Indented with AVL    
-- Reports:  bomrpt13.rpt    
-- Modifications: 09/11/2014 DRP:  changed the parameter @lcUniqBomPart to @lcUniqkey to work with already existing CloudManex Parameters.    
--     10/10/14 YS replace invtmfhd with 2 new files    
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int    
-- 02/18/2015 DRP: Added one more parameter @lcStatus to show only Active parts or not. needed to add Inventor table and the Status Field to the results so I could make sure that we could filter using the @lcStatus    
--    09/22/15 DRP:  added the @lcDate to the <<INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,1,0,@UserId,@lcDate>> to make sure that it is pulling only the Active items from the BOM    
--    09/08/16 DRP: added @IncludeMakeBuy, @lcExplode , @showIndentation parameters per request to show Make/Buy items on the resulting report. also changed << INSERT INTO @tBom EXEC  [BomIndented]>> to use those new parameters    
--- 03/28/17 YS changed length of the part_no column from 25 to 35    
--   08/14/17 YS added PR values stdcostpr ,funcFcUsed_uniq ,PrFcUsed_uniq   
-- 05/24/2019 Shrikant added column Bom_note for assembly note  
-- 02/14/2020 Vijay G: increased size of custname column 
-- 04/16/20 VL added AND (L.IS_DELETED =0 OR L.is_deleted is null) moved from WHERE clause so it show BOM item even it has no MPN
--  rptBomIndentedWAvl '_39P0RLDFH','Active', 1, 'Yes',1  
-- =============================================    
CREATE PROCEDURE [dbo].[rptBomIndentedWAvl]    
    
  --@lcUniqBomParent char(10)= null, --09/11/2014 DRP:  replaced this parameter with @lcUniqKey to work with already existing CloundManex Parameters    
   @lcUniqKey char(10) = null,    
   @lcStatus char(8) = 'Active' --02/18/2015 DRP: Added    
  ,@IncludeMakeBuy bit = 1  --if the value is 1 will explode make/buy parts ; if 0 - will not (default 1) --09/08/16 DRP:  Added     
  ,@lcExplode char (3) = 'Yes'  --if left as No then the BOM will only display top level components.  If Yes, then the report will explode out components down to all sublevles --09/08/16 DRP:  Added    
  ,@showIndentation Bit = 1  --add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later) --09/08/16 DRP:  Added    
  ,@userId uniqueidentifier =null    
      
as    
begin      
      
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
     
 -- list of parameters:    
 -- 1. @lcUniqBomParent - top level BOM Product unique key    
     
    
 -- declare some variables for now, they might be also be passed as parameters    
 --declare @IncludeMakeBuy bit = 0, @ShowIndentation bit =1, @lcDate smalldatetime = null --09/08/16 DRP:  replaced with the below    
 declare  @lcDate smalldatetime = null    
 select @lcDate = DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0) --09/22/15 DRP:  Added    
     
    
     
--This table will be used to find the Product, revision and uniq_key for the product entered by the user.  The uniq_key from this table will then be used to pull fwd from the [BomIndented] Yelena had created.     
-- 09/21/2012 DRP:  increased the descript char from (40) to (45)    
--- 03/28/17 YS changed length of the part_no column from 25 to 35  
-- 02/14/2020 Vijay G: increased size of custname column   
 DECLARE @t TABLE(PART_NO CHAR (35),REVISION CHAR(8),descript char (45),UNIQ_key CHAR (10),matltype char(10),bomcustno char(10),CustName char(50), Bom_Note text)     
      
 --INSERT @T select part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''), bom_note    
 --   from inventor     
 --   left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO     
 --   where part_no = @lcProd and REVISION = @lcRev AND PART_SOURC <> 'CONSG'    
    
 --04/01/14 YS modified to use @lcUniqBomParent as a parameter instead if @lcProd    
 INSERT @T SELECT part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,'') as CustName, bom_note    
    from inventor     
    left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO     
    where Uniq_key=@lcUniqKey  AND PART_SOURC <> 'CONSG'    
    
    --where part_no = @lcProd and REVISION = @lcRev AND PART_SOURC <> 'CONSG'    
    
        
--select * from @t    
--I am declaring the other parameters that would be needed in order to pull in the [BomIndented] procedure      
--04/01/.14 ys no need to declare this variables they are passed as a parametered now. using @lcUniqBomParent instead of @lcBomParent    
    
 --declare  @lcBomParent char(10)     
 --   ,@UserId uniqueidentifier=NULL     
  --  @UserId - for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.    
    
 --select  @lcBomParent = t1.uniq_key from @t as t1    
    
 --declaring the table to match exactly the fields/data from the [BomIndented] procedure     
 -- 03/19/14 YS added Buyer column to [BomIndented]    
 --- 03/28/17 YS changed length of the part_no column from 25 to 35    
  --   08/14/17 YS added PR values stdcostpr ,funcFcUsed_uniq ,PrFcUsed_uniq ,CostPr ,TotalCostPr    
declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10)     
     ,ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char(10),Dept_id char(8)    
     ,Item_note varchar(max),Offset numeric(4,0),Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4)    
     ,Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5),Make_buy bit,Status char(10)    
     --- 03/28/17 YS changed length of the part_no column from 25 to 35    
     ,TopQty numeric(9,2),qty numeric(9,2),Level integer, path varchar(max),sort varchar(max),UniqBomNo char(10),Buyer char(3),    
     --   08/14/17 YS added PR values     
     stdcostpr numeric(13,5),funcFcUsed_uniq char(10) ,PrFcUsed_uniq char(10),    
     CustPartNo char(35),CustRev char(8)    
     ,CustUniqKey char(10)  
  -- 05/24/2019 Shrikant added column Bom_note for assembly note  
    ,Bom_note varchar(max))    
     
 --04/01/14 YS use new parameters    
 -- INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,@IncludeMakeBuy,@ShowIndentation,@UserId    
    
 INSERT INTO @tBom EXEC  [BomIndented] @lcUniqKey,@IncludeMakeBuy,@ShowIndentation,@UserId,@lcDate    
    
  ;    
   WITH BomWithAvl    
   AS    
   (    
   --10/10/14 YS replace invtmfhd with 2 new files    
   -- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int    
   select case when I3.UNIQ_KEY <> @lcUniqKey and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'    
    when i3.UNIQ_KEY <> @lcUniqKey and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom'     
     when I3.UNIQ_KEY <> @lcUniqKey and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource    
   ,Level,item_no,b.Part_sourc,b.PART_NO,b.revision,b.Part_class,b.Part_type,b.Descript,b.Used_inKit,b.U_of_meas,b.qty,b.Buyer    
   ,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF,M.MATLTYPE as MfgrMatlType,M.MATLTYPEVALUE     
   ,case when t3.UNIQ_KEY = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(I4.revision) end as SubParent    
   ,t3.PART_NO as Prod,t3.REVISION as ProdRev,t3.descript as ProdDesc,t3.matltype as ProdMatlType, isnull(t3.CustName,'') as CustName,b.sort,i3.STATUS    
    FROM @tBom B LEFT OUTER JOIN InvtMPNLink L ON B.CustUniqKey=L.UNIQ_KEY    
  --10/10/14 YS replace invtmfhd with 2 new files    
  --FROM @tBom B LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY 
  -- 04/16/20 VL added AND (L.IS_DELETED =0 OR L.is_deleted is null) moved from WHERE clause
     LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId AND (L.IS_DELETED =0 OR l.is_deleted IS NULL)       
        left outer join DEPTS on b.Dept_id = depts.DEPT_ID    
   left outer join INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY    
   left outer join INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY     
   cross join @t as T3    
    WHERE B.CustUniqKey<>' '    
   -- 04/16/20 VL moved to LEFT OUTER JOIN above
   --AND (L.IS_DELETED =0 OR l.is_deleted IS NULL)    
   --AND 1 = CASE WHEN  @lcDate IS NULL THEN 1 WHEN  @lcDate IS NOT NULL AND (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END --09/22/15 DRP:  Removed    
   AND NOT EXISTS (SELECT bomParent,UNIQ_KEY     
       FROM   ANTIAVL A     
       where  A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )    
 UNION ALL    
  --10/10/14 YS replace invtmfhd with 2 new files    
  -- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int    
  select case when I3.UNIQ_KEY <> @lcUniqKey and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'    
    when i3.UNIQ_KEY <> @lcUniqKey and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom'     
     when I3.UNIQ_KEY <> @lcUniqKey and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource    
     ,Level,item_no,b.Part_sourc,B.PART_NO,b.revision,b.Part_class,b.Part_type,b.Descript,b.Used_inKit,b.U_of_meas,b.qty,b.Buyer    
     ,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF,M.MATLTYPE as MfgrMatlType,M.MATLTYPEVALUE     
     ,case when t4.UNIQ_KEY = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(I4.revision) end as SubParent    
     ,t4.PART_NO as Prod,t4.REVISION as ProdRev,t4.descript as ProdDesc,t4.matltype as ProdMatlType, isnull(t4.CustName,'') as CustName,b.sort,i3.status    
  FROM  @tBom B LEFT OUTER JOIN InvtMPNLink L ON B.UNIQ_KEY=L.UNIQ_KEY     
  --10/10/14 YS replace invtmfhd with 2 new files    
  --FROM  @tBom B LEFT OUTER JOIN Invtmfhd L ON B.UNIQ_KEY=InvtMfhd.UNIQ_KEY   
	-- 04/16/20 VL added AND (L.IS_DELETED =0 OR L.is_deleted is null) moved from WHERE clause
    LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId AND (L.IS_DELETED =0 OR L.is_deleted is null)    
     left outer join DEPTS on b.Dept_id = depts.DEPT_ID    
     left outer join INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY    
     left outer join INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY    
     cross join @t as t4    
  WHERE B.CustUniqKey=' '  
  -- 04/16/20 VL moved to LEFT OUTER JOIN above
  -- AND (L.IS_DELETED =0 OR L.is_deleted is null)    
     --AND 1 = CASE WHEN  @lcDate IS NULL THEN 1 WHEN  @lcDate IS NOT NULL AND (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END --09/22/15 DRP:  Removed    
     AND NOT EXISTS (SELECT bomParent,UNIQ_KEY     
         FROM  ANTIAVL A     
         where  A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =m.PARTMFGR and A.MFGR_PT_NO =m.MFGR_PT_NO )    
  )    
      
  --SELECT * from BomWithAvl order by sort    
  SELECT *    
  from BomWithAvl    
  where 1 = CASE @lcStatus WHEN 'Active' THEN CASE WHEN BomWithAvl.STATUS = 'Active' THEN 1 ELSE 0 END ELSE 1 END --02/18/2015 DRP: Added    
  order by sort    
    
  --SELECT  * from BomWithAvl where 0 = case when @lcExplode = 'Yes' then 0 else Level end  ORDER BY Sort     
END 