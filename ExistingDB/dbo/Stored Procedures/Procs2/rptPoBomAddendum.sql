-- =============================================  
-- Modifications:  05/22/2013 DRP:  there was a spot within the code where I was calling BomIndented procedure and I had incorrectly had the MatlType as char(8) when it should have been char(10).  It was causing truncating issues.   
--       11/07/2013 DRP:  RESULTS WERE PULLING IN ALL PURCHASE ORDERS THAT THE PRODUCT EXISTED ON.  Added the POMain to the @poMake declared table and the Ponum,conum & itemno to the results of that table  
--         Then remove the poitems and pomain from the last select statement in the procedure, because we were already calling it in the @poMake section.   
--     03/19/14 YS added Buyer column to [BomIndented]  
--     09/16/2014 DRP: added the Customer Table and customer.custname to the end results so that we could use that to display the customer name on the PO Bom Addendum report.   
--       10/13/14 YS : replaced invtmfhd table with 2 new tables  
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
--     03/20/2015 DRP: Added the @lcPoDate which will be populated with the PO Date.  The components on the BOM Addendums will then be filtered based off of this date.  
--     09/22/15 DRP:  added the @lcDate to the <<INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,1,0,@UserId,@lcDate = @lcPoDate>> to make sure that it is pulling only the Active items from the BOM  
--   08/14/17 YS added PR values   
-- 05/24/2019 Shrikant added column Bom_note for assembly note
-- rptPoBomAddendum null, null
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================  
  
CREATE PROCEDURE [dbo].[rptPoBomAddendum]  
  
-- Add the parameters for the stored procedure here  
  
  @lcPoNum char(15)=null  
  
 , @userId uniqueidentifier=null  
as  
begin  
  
--08/10/2012 DRP: added the Material Type to the BOMIndented procedure so I had to insert IT here within this table  
-- 03/19/14 YS added Buyer column to [BomIndented]  
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10)   
     ,ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char(10),Dept_id char(8)  
     ,Item_note varchar(max),Offset numeric(4,0), Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4)  
     ,Scrap numeric(6,2),SetupScrap numeric(4,0),usesetupscrp bit,stdbldqty numeric (9),Phantom_make bit,StdCost numeric(13,5),Make_buy bit,Status char(10)  
     ,TopQty numeric(9,2),qty numeric(9,2),Level integer ,path varchar(max),sort varchar(max),UniqBomNo char(10),Buyer char(3)  
     --   08/14/17 YS added PR values   
     ,stdcostpr numeric(13,5),funcFcUsed_uniq char(10) ,PrFcUsed_uniq char(10)  
     ,CustPartNo char(35),CustRev char(8),CustUniqKey char(10)
-- 05/24/2019 Shrikant added column Bom_note for assembly note
	 , Bom_note varchar(max) )  
  
declare @ncount as integer  
  ,@lcBomparent char(10)  
  ,@lcPoDate smalldatetime   --03/20/2015 DRP:  this will be populated with the PO date.  The components pulled fwd onto the BOM will be filtered based on the PO Date.  
  
--11/07/2013 drp:  added Ponum,conum & itemno to the @poMake table results  
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
declare @poMake Table (Uniq_key char(10),ponum char(15),conum numeric (3,0),PoItemNo varchar(max),Part_no char(35),Revision char(8),Part_sourc char(10),Make_buy bit,podate smalldatetime,nRec int)  
  
--11/07/2013 drp:  Had to also replace the insert into @pomake so in case where the user had the same product on multiple items on the po that it would list only once in the results and put each line item no into the poitemno field.   
 --insert into @poMake   
 -- select poitems.UNIQ_KEY,poitems.ponum,pomain.CONUM,poitems.ITEMNO as PoItemNo,inventor.PART_NO,inventor.REVISION,inventor.PART_SOURC,inventor.MAKE_BUY,ROW_NUMBER() OVER (order by inventor.part_no,inventor.revision) as nRec  
 -- from POITEMS  
 --   left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY  
 --   inner join POMAIN on poitems.PONUM = pomain.PONUM   
      
 -- where inventor.PART_SOURC = 'MAKE' and inventor.MAKE_BUY = 1  
 --   and LCANCEL <> 1  
 --   and POitems.PONUM = dbo.padl(@lcPoNum,15,'0')  
      
 insert into @poMake   
    select PO.*,ROW_NUMBER() OVER (order by part_no,revision) as nRec  
 from  
 (  
 select distinct poitems.UNIQ_KEY,poitems.ponum,pomain.CONUM,poitemno.itemno,inventor.PART_NO,inventor.REVISION,inventor.PART_SOURC,inventor.MAKE_BUY,pomain.podate  
 from POITEMS  
   cross apply   
    (SELECT CAST(stuff((select ','+i.ITEMNO from poitems I where i.ponum=poitems.ponum and i.uniq_key = poitems.uniq_key order by ITEMNO for XML path ('')),1,1,'') as varchar(max)) as itemno) as poitemno  
      left outer join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY  
      inner join POMAIN on poitems.PONUM = pomain.PONUM     --11/07/2013 DRP:  ADDED HERE TO GET THE PO INFO TO THE @poMAKE TABLE   
     where inventor.PART_SOURC = 'MAKE' and inventor.MAKE_BUY = 1  
      and LCANCEL <> 1  
      and POitems.PONUM = dbo.padl(@lcPoNum,15,'0')) PO  
--11/07/2013 DRP: End @pomake changes  
  
  
  
--select * from @poMake  
  
select @lcPoDate = podate from @poMake --03/20/2015 DRP:  Added  
  
set @ncount = 1  
WHILE (1=1)  
  
BEGIN  
 SELECT @lcBomParent =Uniq_key from @poMake where nRec=@ncount  
 IF @@ROWCOUNT =0  
  BREAK  
 ELSE -- IF @@ROWCOUNT =0  
BEGIN  
 INSERT INTO @tBom EXEC BomIndented @lcBomParent = @lcBomParent ,@IncludeMakeBuy=1 , @ShowIndentation=1,@lcDate = @lcPoDate  
 --INSERT INTO @tBom EXEC BomIndented @lcBomParent,1,1,@lcDate = @lcPoDate --09/22/15 DRP:  replaced by the above  
 SET @nCount=@ncount+1  
END-- IF @@ROWCOUNT =0  
END -- while  
--       10/13/14 YS : replaced invtmfhd table with 2 new tables  
;WITH BomWithAvl AS  
(  
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
select B.*,m.PARTMFGR ,m.MFGR_PT_NO,l.ORDERPREF ,l.UNIQMFGRHD,m.MATLTYPE as MfgrMatlType  
--       10/13/14 YS : replaced invtmfhd table with 2 new tables  
--FROM @tBom B LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY  
FROM @tBom B LEFT OUTER JOIN InvtMPNLink L ON B.CustUniqKey=L.UNIQ_KEY  
LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
WHERE B.CustUniqKey<>' '  
  AND l.IS_DELETED<> 1  
  and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )  
  
UNION ALL  
  
select B.*,M.PARTMFGR ,m.MFGR_PT_NO,l.ORDERPREF ,l.UNIQMFGRHD,m.MATLTYPE as MfgrMatlType  
--       10/13/14 YS : replaced invtmfhd table with 2 new tables  
--FROM @tBom B LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY  
FROM @tBom B LEFT OUTER JOIN InvtMPNLink L ON B.Uniq_Key=L.UNIQ_KEY  
LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
WHERE B.CustUniqKey=' '  
  AND L.IS_DELETED <> 1  
  and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =m.PARTMFGR and A.MFGR_PT_NO =m.MFGR_PT_NO )  
)  
  
--SELECT * from BomWithAvl ORDER BY Path,Sort  
  
select p.uniq_key as ParentLink,p.ponum,p.CONUM,p.PoItemNo as PoItemNo,t.bomParent,t.bomcustno,t.uniq_key,t.Item_no,t.PART_NO,t.Revision,t.Part_sourc  
  ,t.ViewPartNo,t.ViewRevision,t.Part_class,t.Part_type,t.Descript,t.MatlType,t.Dept_id,t.Item_note,t.Offset,t.Term_dt,t.Eff_dt,t.Used_inKit,t.custno,t.Inv_note,t.U_of_meas  
  ,t.Scrap,t.SetupScrap,t.Phantom_make,t.StdCost,t.Make_buy,t.Status,t.TopQty,t.qty,t.Level,t.path,t.sort,t.UniqBomNo,t.CustPartNo,t.CustRev,t.CustUniqKey,t.PARTMFGR  
  ,t.MFGR_PT_NO,t.MfgrMatlType,customer.custname --09/16/2014 DRP:  Added the CustName to the results  
from BomWithAvl t  
  inner join @poMake p on RIGHT(left(t.path,11),10) = p.Uniq_key  --11/07/2013 DRP:  this line replaces the two commented out below    
  --inner join poitems on RIGHT(left(t.path,11),10) = poitems.UNIQ_KEY  
  --inner join POMAIN on poitems.PONUM = pomain.PONUM  
  left outer join customer on t.bomcustno = customer.CUSTNO --09/16/2014 DRP:  added the Customer table here  
--where 1 = CASE WHEN NOT @lcPoDate IS NULL THEN CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcPoDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcPoDate)<0) THEN 1 ELSE 0 END ELSE 1 END  --03/20/2015 DRP:  added this filter for the components based off of the PoDate --09/22/15 DRP:  Removed  
  
  
order by poitemno,path,sort  
  
end