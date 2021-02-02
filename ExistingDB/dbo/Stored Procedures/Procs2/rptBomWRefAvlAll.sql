-- =============================================    
-- Author:  Debbie    
-- Create date: 08/15/2012    
-- Description: Created for the Bill of Material with Ref Designator ~ All Report    
-- Reports Using Stored Procedure:  bomrpt9all.rpt    
-- Modifications: 09/21/2012 DRP:  I needed to increase the Descript Char from (40) to (45), it was causing truncation error on the reports when the Description field was max'd out.    
--     05/22/2013 DRP:  there was a spot within the code where I was calling BomIndented procedure and I had incorrectly had the MatlType as char(8) when it should have been char(10).  It was causing truncating issues.     
--     03/19/14 YS added Buyer column to [BomIndented]    
-- 10/10/14 YS replace invtmfhd with 2 new tables    
--     10/20/2014 DRP:  making changes to the procedure in order for it to work with Cloud Manex:  needed to change @lcProd and @lcRev to be @lcUniqkey    
--          moved the @userId to the top of the procedure.  also changed that section to now work with the @lcUniqkey    
--          I was having issues getting the MRT report to work the way I wanted it to where SubParents and Cust Part No are concerned.  I had to add CPN and SubP columns to the results in order for me to get the report to work properly.    
--     10/24/2014 DRP:  If the users were able to get the Customer AVL to save blank (no avls at all) THEN the item would drop off of the results.  Needed to make changes to display the part and indicate that there are no AVL's loaded    
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int    
--     01/14/15 YS remove inv_note if @lcItemNotes ='No'     
--     02/18/2015 DRP:  Added one more parameter @lcStatus to show only Active parts or not    
--     06/12/2015 DRP:  needed to replace <<ISNULL(MATLTYPE,'') as MfgrMatlType>> in the final Selection statement with <<ISNULL(MFGRMATLTYPE,'') as MfgrMatlType>>  otherwise the Mfgr Matl Type was incorrectly displaying the Parts Material Type    
--     11/16/16 DRP: Per request by user added invtmfgr.marking    
--     12/22/16 DRP: Due to recent changes in how the bom leveling is numbered (used to start at 0 and now has been changed to start at 1) we needed to make the needed changes within the Where Clause at the END of this procedure.     
--- 03/28/17 YS changed length of the part_no column from 25 to 35    
--   08/14/17 YS added PR values     
-- 05/24/2019 Shrikant added column Bom_note for assembly note  
--- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50
-- 04/16/20 VL changed the code for MPN and moved the (L.IS_DELETED =0 or L.is_deleted is null) to the Mfhd sub query so the MPN will have NULL value even the record is marked as deleted and show 'No Avl''s exist check Item Master' in last query
-- rptBomWRefAvlAll '_39P0RLDFH','Yes', 1,1, 'Yes','Yes'  
-- =============================================    
CREATE PROCEDURE [dbo].[rptBomWRefAvlAll]    
    
--declare    
  -- @lcProd varchar(25) = '' --10/20/2014 DRP:   REMOVED    
  --,@lcRev char(8) = ''  --10/20/2014 DRP:  Removed     
  @lcUniqkey CHAR(10) = ''    
  ,@lcExplode CHAR (3) = 'Yes'    
  ,@IncludeMakeBuy BIT = 1    
  ,@showIndentation BIT = 1    
  ,@lcItemNotes CHAR(3) = 'No' --10/20/2014 DRP:  Added will determine if the Item Notes are included in the results or not      
  ,@lcBomNotes CHAR(3) = 'No'  --10/20/2014 DRP:  Added will determin if the BomNotes are included in the results or not     
  ,@lcStatus CHAR(8) = 'Active' --02/18/2015 DRP:  Added    
  ,@userId UNIQUEIDENTIFIER = null    
      
AS    
BEGIN      
      
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
     
 -- list of parameters:    
 -- 1. @lcProd - top level BOM Product #    
 -- 2. @lcRev = Top Level Revision     
 -- 4. @IncludeMakeBuy if the value is 1 will explode make/buy parts ; if 0 - will not (default 1)    
 -- 5. @ShowIndentation add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later)    
    
     
 --- this sp will     
 ----- 1. find BOM information and explode PHANTOM and Make parts. If the make part has make/buy flag and @IncludeMakeBuy=0, then Make/Buy will not be indented to the next level    
 ----- 2. Figure out AVL (if internal part, but BOM assigned to a customer, an appropriate consign part AVL will be found    
 ----- 3. Remove AVL if any AntiAvl are assigned    
    
    
    
--This table will be used to find the Product, revision and uniq_key for the product entered by the user.  The uniq_key from this table will then be used to pull fwd from the [BomIndented] Yelena had created.     
--<< 09/21/2012 DRP:  increased the descript char from (40) to (45)    
 --- 03/28/17 YS changed length of the part_no column from 25 to 35    
 --- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50
 DECLARE @t TABLE(PART_NO CHAR (35),REVISION CHAR(8),descript char (45),UNIQ_key CHAR (10),matltype char(10),bomcustno char(10),CustName char(50), Bom_Note text)     
      
 INSERT @T SELECT part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''), bom_note    
    FROM inventor     
    LEFT OUTER JOIN CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO     
    --where part_no = @lcProd and REVISION = @lcRev AND PART_SOURC <> 'CONSG' --10/20/2014 DRP:  removed and replaced by the @lcUniq_key below     
    WHERE inventor.UNIQ_KEY = @lcUniqkey    
    AND PART_SOURC <> 'CONSG'    
        
--select * from @t    
--I am declaring the other parameters that would be needed in order to pull in the [BomIndented] procedure      
 DECLARE  @lcBomParent char(10)     
    --,@UserId uniqueidentifier=NULL --10/20/2014 DRP:  moved to the top of the procedure     
  --  @UserId - for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.    
    
 SELECT  @lcBomParent = t1.uniq_key from @t as t1    
    
--declaring the table to match exactly the fields/data from the [BomIndented] procedure     
-- 03/19/14 YS added Buyer column to [BomIndented]    
--- 03/28/17 YS changed length of the part_no column from 25 to 35    
 declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) ,    
 ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char(10),Dept_id char(8),Item_note varchar(max),Offset numeric(4,0),    
 Term_dt smalldatetime,Eff_dt smalldatetime, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit    
 ,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5),Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer, path varchar(max)    
 --- 03/28/17 YS changed length of the part_no column from 25 to 35    
 ,sort varchar(max),UniqBomNo char(10),Buyer char(3),    
 --   08/14/17 YS added PR values     
 stdcostpr numeric(13,5),funcFcUsed_uniq char(10) ,PrFcUsed_uniq char(10),    
 CustPartNo char(35),CustRev char(8),CustUniqKey char(10)  
 -- 05/24/2019 Shrikant added column Bom_note for assembly note  
 ,Bom_note varchar(max) )    
     
  INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,@IncludeMakeBuy,@ShowIndentation,@UserId    
     
    
  ;WITH BomWithAvl    
   --10/10/14 YS replace invtmfhd with 2 new tables    
   AS    
   (    
   select B.*,    
  --InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD,invtmfhd.MATLTYPE as MfgrMatlType,INVTMFHD.MATLTYPEVALUE,    
  -- 04/16/20 VL changed M. to Mfhd. in following columns
  Mfhd.PARTMFGR ,Mfhd.MFGR_PT_NO,Mfhd.ORDERPREF ,Mfhd.UNIQMFGRHD,Mfhd.MATLTYPE as MfgrMatlType,Mfhd.MATLTYPEVALUE,    
  isnull(dbo.fnBomRefDesg(b.UniqBomNo),'') as RefDesg     
   ,case when i3.UNIQ_KEY <> @lcBomParent and i3.PART_SOURC = 'MAKE' and i3.PHANT_MAKE = 1 THEN 'Phantom/Make'    
    when i3.UNIQ_KEY <> @lcBomParent and i3.PART_SOURC = 'MAKE' and i3.MAKE_BUY = 1 THEN 'Make/Buy' ELSE '' END as MbPhSource    
   ,case when t3.UNIQ_KEY = I4.uniq_key THEN '' ELSE rtrim(I4.part_no)+'  /  '+rtrim(I4.revision) END as SubParent    
   ,t3.PART_NO as Prod,t3.REVISION as ProdRev,T3.uniq_key as PUniq_key,t3.descript as ProdDesc,t3.matltype as ProdMatlType  
   , isnull(t3.CustName,'') as CustName  
   --,t3.Bom_Note  
   -- 04/16/20 VL changed M. to Mfhd. in following columns
   ,mfhd.marking    
  --FROM @tBom B     
   --left outer JOIN (select * from INVTMFHD where invtmfhd.IS_DELETED = 0) as invtmfhd on  B.CustUniqKey=INVTMFHD.UNIQ_KEY      
   ----10/24/2014 DRP:  replaced . . .  left outer JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY     
   -- 10/10/14 YS replace invtmfhd with 2 new tables   
   -- 04/16/20 VL changed the code for MPN and moved the (L.IS_DELETED =0 or L.is_deleted is null) to the Mfhd sub query so the MPN will have NULL value even the record is marked as deleted and show 'No Avl''s exist check Item Master' in last query
--   FROM @tBom B LEFT OUTER JOIN InvtMPNLink L ON B.CustUniqKey=L.UNIQ_KEY    
--   LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId    
	 FROM @tBom B LEFT OUTER JOIN (select l.Uniq_key, M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MATLTYPE ,MATLTYPEVALUE,m.marking    
     FROM InvtMPNLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId and m.is_deleted=0 and l.is_deleted=0) Mfhd On  B.CustUniqKey=Mfhd.UNIQ_KEY    
	 -- 04/16/20 VL End}
   left outer join DEPTS on b.Dept_id = depts.DEPT_ID    
   left outer join INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY    
   left outer join INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY     
   cross join @t as T3    
   WHERE B.CustUniqKey<>' '    
   -- 10/10/14 YS allow for the is_deleted to be null    
   -- 04/16/20 VL comment out next line and added to Mfhd sub query
   --AND (L.IS_DELETED =0 or L.is_deleted is null)   
   
   --AND Invtmfhd.IS_DELETED =0 --10/24/2014 DRP:  removed and should be taken care of within the left outer join above    
  --and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )    
  --10/14/14 YS added 2 new files    
  -- 04/16/20 VL changed M. to Mfhd. in following columns
  and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =Mfhd.PARTMFGR and A.MFGR_PT_NO =Mfhd.MFGR_PT_NO )    
 UNION ALL    
  select B.*,    
  --InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD,invtmfhd.MATLTYPE as MfgrMatlType,INVTMFHD.MATLTYPEVALUE,    
  Mfhd.PARTMFGR ,Mfhd.MFGR_PT_NO,Mfhd.ORDERPREF ,Mfhd.UNIQMFGRHD,Mfhd.MATLTYPE as MfgrMatlType,Mfhd.MATLTYPEVALUE,    
  isnull(dbo.fnBomRefDesg(b.UniqBomNo),'') as RefDesg    
  ,case when i3.UNIQ_KEY <> @lcBomParent and i3.PART_SOURC = 'MAKE' and i3.PHANT_MAKE = 1 THEN 'Phantom/Make'    
    when i3.UNIQ_KEY <> @lcBomParent and i3.PART_SOURC = 'MAKE' and i3.MAKE_BUY = 1 THEN 'Make/Buy' ELSE ''  END as MbPhSource    
  ,case when t4.UNIQ_KEY = I4.uniq_key THEN '' ELSE rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) END as SubParent    
  ,t4.PART_NO as Prod,t4.REVISION as ProdRev,t4.uniq_key as PUniq_key,t4.descript as ProdDesc,t4.matltype as ProdMatlType,isnull(t4.CustName,'') as CustName  
  --,t4.Bom_Note    
  ,mfhd.marking    
  --10/10/14 YS replace invtmfhd with 2 new tables    
  --FROM @tBom B LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY    
  FROM @tBom B LEFT OUTER JOIN (select l.Uniq_key, M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MATLTYPE ,MATLTYPEVALUE,m.marking    
      FROM InvtMPNLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId and m.is_deleted=0 and l.is_deleted=0) Mfhd On  B.UNIQ_KEY=Mfhd.UNIQ_KEY    
   --- left outer JOIN (select * from INVTMFHD where invtmfhd.IS_DELETED = 0) as invtmfhd on  B.UNIQ_KEY=INVTMFHD.UNIQ_KEY --10/24/2014 DRP:  replaced . . .left outer join INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY    
    left outer join DEPTS on b.Dept_id = depts.DEPT_ID    
    left outer join INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY    
    left outer join INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY    
    cross join @t as t4    
  WHERE B.CustUniqKey=' '    
  --AND Invtmfhd.IS_DELETED =0 --10/24/2014 DRP:  removed and should be taken care of within the left outer join above    
  --and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )    
  --10/14/14 YS added 2 new files    
  and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =Mfhd.PARTMFGR and A.MFGR_PT_NO =Mfhd.MFGR_PT_NO )    
  )    
      
  --SELECT  * from BomWithAvl where 0 = case when @lcExplode = 'Yes' THEN 0 ELSE Level END  ORDER BY Sort --10/20/2014 DRP:  replaced by below so I could implement some formulas that I used to calculate on the reports only [QtyEach].      
--10/20/2014 DRP:  Added CPN and SubP to the results below in order to get the MRT report to work properly     
    
--select sort, COUNT(*) n  from BomWithAvl where 0 = case when @lcExplode = 'Yes' THEN 0 ELSE Level END group by sort    
    
--     01/14/15 YS remove inv_note if @lcItemNotes ='No'     
-- 06/12/2015 DRP:  replaced ISNULL(MATLTYPE,'') as MfgrMatlType with ISNULL(MFGRMATLTYPE,'') as MfgrMatlType    
---08/14/17 YS remove stdcost column    
SELECT bomParent,bomcustno,UNIQ_KEY,item_no,PART_NO ,Revision,Part_sourc,ViewPartNo,ViewRevision,Part_class,Part_type,Descript,MatlType,Dept_id    
   ,CASE WHEN @lcItemNotes = 'Yes' THEN Item_note ELSE CAST ('' AS varchar(max)) END AS Item_note --10/20/2014 DRP:  added the case statement to work for the lcItemNote parameter    
   ,Offset,Term_dt,Eff_dt, Used_inKit,custno,    
   CASE WHEN @lcItemNotes = 'Yes' THEN Inv_note ELSE CAST ('' AS varchar(max)) END AS Inv_note,    
   U_of_meas, Scrap,SetupScrap,USESETSCRP,STDBLDQTY,Phantom_make,Make_buy,[Status],TopQty,qty,TopQty*qty as QtyEach    
   ,[Level],[path],sort,UniqBomNo,Buyer,CustPartNo,CustRev,case when CustPartNo = '' THEN CAST(0 AS bit) ELSE CAST(1 as bit) END as CPN    
   ,isnull(PARTMFGR,'') AS PARTMFGR,ISNULL(cast(MFGR_PT_NO as CHAR(35)),'No Avl''s exist check Item Master') as MFGR_PT_NO    
   ,ISNULL(ORDERPREF,0) AS ORDERPREF,ISNULL(UNIQMFGRHD,'') AS UNIQMFGRHD,ISNULL(MFGRMATLTYPE,'') AS MfgrMatlType,ISNULL(MATLTYPEVALUE,'') AS MATLTYPEVALUE,RefDesg     
   ,MbPhSource,SubParent,CASE WHEN SubParent = '' THEN CAST (0 AS bit) ELSE CAST(1 as bit)END as SubP    
   ,Prod,ProdRev,PUniq_key,ProdDesc,ProdMatlType,CustName  
   ,CASE WHEN @lcBomNotes = 'Yes' THEN Bom_Note ELSE CAST('' AS varchar(max)) END AS Bom_note    
   ,marking    
 FROM BomWithAvl     
 WHERE @lcExplode='Yes' or (@lcExplode='No' and Level=1)    
   --1 = case when @lcExplode = 'Yes' THEN 1 ELSE Level END  --12/22/16 DRP: Replaced with the above.    
   and 1 = CASE @lcStatus WHEN 'Active' THEN CASE WHEN Status = 'Active' THEN 1 ELSE 0 END ELSE 1 END --02/18/2015 DRP:  Added    
  ORDER BY item_no,Sort     
      
END