  -- =============================================    
  -- Author:   Debbie    
  -- Create date:  12/15/2012    
  -- Description:  Created for the Top Assembly Part Usage    
  -- Reports Using:   bmrpt10p.rpt     
  -- Modifications: 07/12/2013 DRP:  I include the Product and the revision in the same field for SubParent and I used to only have Char(25).  That did not properly account for the revision characters and was causing a Truncating error.     
  --     I have increase it to SubParent char(50).  These changes were made to the @Results section below.    
  --     02/19/2014 DRP:  needed to increase all occurrances of  MatlType Char(8) to Char(10) within the declared tables below.     
  --     03/19/14 YS added Buyer column to [BomIndented]     
  --     10/10/14 YS replace invtmfhd tables with 2 tables    
  -- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int    
  -- 10/29/2014 DRP: making changes to the procedure in order for it to work with Cloud Manex: needed to change @lcProd and @lcRev to be @lcUniqkey    
  -- I was having issues getting the MRT report to work the way I wanted it to where SubParents and Cust Part No are concerned. I had to add CPN and SubP columns to the results in order for me to get the report to work properly.    
  -- If the users were able to get the Customer AVL to save blank (no avls at all) then the item would drop off of the results. Needed to make changes to display the part and indicate that there are no AVL's loaded    
  -- 02/18/2015 DRP: Added one more parameter @lcStatus to show only Active parts or not. needed to add Inventor table and the Status Field to the results so I could make sure that we could filter using the @lcStatus    
  -- 04/14/15 YS Location length is changed to varchar(256)    
  --     06/12/2015 DRP:  needed to replace <<ISNULL(MATLTYPE,'') as MfgrMatlType>> in the final Selection statement with <<ISNULL(MFGRMTLTYPE,'') as MfgrMatlType>>  otherwise the Mfgr Matl Type was incorrectly displaying the Parts Material Type    
  --     09/22/15 DRP:  added the @lcDate to the <<INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,1,0,@UserId,@lcDate>> to make sure that it is pulling only the Active items from the BOM    
  --     09/25/15 DRP/YS: it was found that the Qty_oh and QtyNotReserved were all pulling from the Consigned link. Modifications have been made to pull the appropriate qty on hand for both Internal and Consigned.     
  -- 02/24/17 YS removed Invtmfhd table and replace with MfgrMaster and Invtmpnlink    
  --- 03/28/17 YS changed length of the part_no column from 25 to 35    
  --   08/14/17 YS added PR values    
  -- 05/24/2019 Shrikant added column Bom_note for getting assembly note and avoid error Column name or number of supplied values does not match table definition.  
  -- 05/24/2019 Remove shrikant to avoid error The column 'Bom_Note' was specified multiple times for 'BomWithAvl'.
  --- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50   
   -- 12/07/20 VL: mnxSettingsManagement.settingname was changed from 'Suppress Not Used in Kit items ?' to 'suppressNotUsedInKitItems' and change from kitdef to mnxsettingsmanagement
  -- [rptBomTopAssm] '_39P0RLDFH','No', 1, 'no','Active'   
  -- =============================================    
  CREATE procedure [dbo].[rptBomTopAssm]    
  -- @lcProd varchar(25) = '' --10/29/2014 DRP: removed    
  --,@lcRev char(8) = '' --10/29/2014 DRP: removed    
  @lcUniqkey char(10) = ''    
  ,@lcIgnore as char(20) = 'No' -- used within the report to indicate if the user elects to ignore any of the scrap settings.    
  ,@lcQty numeric(5,0) = '1' -- user would populate the desired qty/bld qty here    
  ,@lcSupUsedKit char(18) = 'No' -- here the report will use the system default for Suppress Not Used in Kit, but the users have the option to change manually within the report.    
  ,@lcStatus char(8) = 'Active' --02/18/2015 DRP: Added    
  ,@userId uniqueidentifier=NULL -- @UserId - for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.    
  as    
  begin    
        
   -- SET NOCOUNT ON added to prevent extra result sets from    
   -- interfering with SELECT statements.    
   SET NOCOUNT ON;    
       
    
   --- this sp will     
   ----- 1. find BOM information and explode PHANTOM and Make parts. If the make part has make/buy flag and @IncludeMakeBuy=0, then Make/Buy will not be indented to the next level    
   ----- 2. Figure out AVL (if internal part, but BOM assigned to a customer, an appropriate consign part AVL will be found    
   ----- 3. Remove AVL if any AntiAvl are assigned    
    
  --The below is used to indicate to take the active BOM as of today's date (computer date)    
  declare @lcDate smalldatetime     
  select @lcDate = DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0)    
    
    
  --This table will be used to find the Product, revision and uniq_key for the product entered by the user.  The uniq_key from this table will then be used to pull fwd from the [BomIndented] Yelena had created.     
  -- 09/21/2012 DRP:  increased the descript char from (40) to (45)    
   --- 03/28/17 YS changed length of the part_no column from 25 to 35 
   --- 02/14/2020 Vijay G: Changed length of the part_no column from 35 to 50  
      
   DECLARE @t TABLE(PART_NO CHAR (35),REVISION CHAR(8),descript char (45),UNIQ_key CHAR (10),matltype char(10),bomcustno char(10),CustName char(50), Bom_Note text)     
        
   INSERT @T select part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''), bom_note    
      from inventor     
      left outer join CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO     
      --where part_no = @lcProd and REVISION = @lcRev AND PART_SOURC <> 'CONSG' --10/20/2014 DRP: removed and replaced by the @lcUniq_key below    
      where inventor.UNIQ_KEY = @lcUniqkey    
          
  --select * from @t    
  --I am declaring the other parameters that would be needed in order to pull in the [BomIndented] procedure      
   declare  @lcBomParent char(10)     
      --,@UserId uniqueidentifier=NULL   --10/29/2014 DRP: moved to the top of the report    
      ,@SupUsedKit char(18)    
      ,@lcBomCustNo char(10)    
      ,@lcExplode char (3)    
   
   select @lcBomParent = t1.uniq_key, @lcbomCustno = t1.bomcustno,@lcExplode = 'Yes' from @t as t1    
   
	-- 12/07/20 VL changed to not use kitdef any more
	--select @SupUsedKit = (select case when @lcSupUsedKit = 'Use System Default' OR @lcSupUsedKit = '' then Lsuppressnotusedinkit    
	--          else case when @lcSupUsedKit = 'Yes' then 1    
	--           else case when @lcSupUsedKit = 'No' then 0 end end end from KITDEF)   
   select @SupUsedKit = (select case when @lcSupUsedKit = 'Use System Default' OR @lcSupUsedKit = '' then ISNULL(wm.settingValue,mnx.settingValue)  
         else case when @lcSupUsedKit = 'Yes' then 1  
         else case when @lcSupUsedKit = 'No'  then 0 end end end   
         FROM MnxSettingsManagement mnx LEFT OUTER JOIN wmSettingsManagement wm   
         ON mnx.settingId = wm.settingId   
         WHERE mnx.settingName='suppressNotUsedInKitItems')  
			  
    
  --declaring the table to match exactly the fields/data from the [BomIndented] procedure     
  -- 03/19/14 YS added Buyer column to [BomIndented]    
  --- 03/28/17 YS changed length of the part_no column from 25 to 35    
   declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) ,    
   ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char(10),Dept_id char(8),Item_note varchar(max),Offset numeric(4,0),    
   Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit    
   ,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5),Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer, path varchar(max)    
   --- 03/28/17 YS changed length of the part_no column from 25 to 35    
   ,sort varchar(max),UniqBomNo char(10),Buyer char(3),    
   --   08/14/17 YS added PR values     
   stdcostpr numeric(13,5),funcFcUsed_uniq char(10) ,PrFcUsed_uniq char(10),    
   CustPartNo char(35),CustRev char(8),CustUniqKey char(10)  
     -- 05/24/2019 Shrikant added column Bom_note for getting assembly note and avoid error Column name or number of supplied values does not match table definition.  
  ,Bom_note varchar(max)  
   )    
       
  --INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,@IncludeMakeBuy,@ShowIndentation,@UserId    
    INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,1,0,@UserId,@lcDate  --09/22/15 DRP:  added @lcDate    
    --SELECT * FROM @tBom    
    --07/12/2013 DRP:  I include the Product and the revision in the same field for SubParent and I used to only have Char(25).  That did not properly account for the revision characters and was causing a Truncating error.     
   -- 04/14/15 YS Location length is changed to varchar(256)    
   --- 03/28/17 YS changed length of the part_no column from 25 to 35    
    declare @results table (Custname char(35),PUniq_key char(10),ParentBomPn char(35),ParentBomRev char(8),ParentBomDesc char(45),ParentMatlType char(10),BldQty numeric (7,0)    
        ,Item_No numeric(4,0),Used_InKit char(1),DispPart_No varchar(max),DispRevision char(8),Req_Qty numeric(12,2),Phantom char(1)    
        ,Part_Class char(8),Part_Type char(8),Uniq_key char(10),Dept_Id char(4),Dept_Name char(25),Scrap numeric (6,2),SetupScrap numeric (4,0)    
        --- 03/28/17 YS changed length of the part_no column from 25 to 35    
        ,BomParent char(10),Part_Sourc char(10),Qty numeric(12,2),Descript char(45),U_of_Meas char(4),MbPhSource char(15),SubParent char(50),Part_No char(35)    
        --- 03/28/17 YS changed length of the part_no column from 25 to 35    
        ,CustPartNo char(35),Phant_Make bit,Revision char(8),MatlType char(10),CustRev char(8),location varchar(256),whse char(6),Qty_Oh numeric(12,2)    
        ,QtyNotReserved numeric(12,2),AntiAvl char(2),PartMfgr char(8),Mfgr_Pt_No char(30),MfgrMtlType char(10),OrderPref int,UniqMfgrHd char(10)    
        ,PhParentPn char(35),Instore bit,Level integer,sort varchar(max),[status] char(8), Bom_note varchar(max))    
   ;    
     WITH BomWithAvl    
     -- 10/10/14 YS replace invtmfhd tables with 2 tables    
     AS    
     (    
     select B.*    
     ,depts.DEPT_NAME    
     , M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MATLTYPE as MfgrMatlType,M.MATLTYPEVALUE,    
    isnull(dbo.fnBomRefDesg(b.UniqBomNo),'') as RefDesg     
     ,case when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'    
      when i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom'     
       when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource    
       ,case when t3.UNIQ_KEY = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(I4.revision) end as SubParent    
     ,t3.PART_NO as Prod,t3.REVISION as ProdRev,T3.uniq_key as PUniq_key,t3.descript as ProdDesc,t3.matltype as ProdMatlType,     
     isnull(t3.CustName,'') as CustName  
 -- 05/24/2019 Remove shrikant to avoid error The column 'Bom_Note' was specified multiple times for 'BomWithAvl'.  
  --,t3.Bom_Note    
     ---,MICSSYS.LIC_NAME --10/29/2014 DRP: Removed    
    FROM @tBom B     
     -- 10/10/14 YS replace invtmfhd tables with 2 tables    
     --LEFT OUTER JOIN INVTMFHD ON B.Uniq_Key=INVTMFHD.UNIQ_KEY     
     LEFT OUTER JOIN InvtMpnLink L ON B.Uniq_Key=L.UNIQ_KEY    
     LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId     
     left outer join DEPTS on b.Dept_id = depts.DEPT_ID    
     left outer join INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY    
     left outer join INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY     
     cross join @t as T3    
     ---cross join MICSSYS --10/29/2014 DRP: Removed    
    WHERE B.CustUniqKey<>' '    
     AND (L.IS_DELETED =0 or L.is_deleted IS NULL)    
     --AND 1 = CASE WHEN NOT @lcDate IS NULL THEN CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END ELSE 1 END --09/22/15 DRP:  replaced by the filter that was added tothe BomIndented Procedure    
    
   UNION ALL    
    select B.*,depts.DEPT_NAME,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MATLTYPE as MfgrMatlType,M.MATLTYPEVALUE,    
    isnull(dbo.fnBomRefDesg(b.UniqBomNo),'') as RefDesg    
     ,case when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'    
      when i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom'     
       when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 then 'Make/Buy' else ''  end as MbPhSource    
     ,case when t4.UNIQ_KEY = I4.uniq_key then '' else rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) end as SubParent    
    ,t4.PART_NO as Prod,t4.REVISION as ProdRev,t4.uniq_key as PUniq_key,t4.descript as ProdDesc,t4.matltype as ProdMatlType,    
    isnull(t4.CustName,'') as CustName  
 -- 05/24/2019 Remove shrikant to avoid error The column 'Bom_Note' was specified multiple times for 'BomWithAvl'.   
 --,t4.Bom_Note    
    ---,MICSSYS.LIC_NAME --10/29/2014 DRP: Removed    
    -- 10/10/14 YS replace invtmfhd tables with 2 tables    
    --FROM @tBom B LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY     
    FROM @tBom B LEFT OUTER JOIN InvtMPNLink L ON B.UNIQ_KEY=L.UNIQ_KEY     
     LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId     
     left outer join DEPTS on b.Dept_id = depts.DEPT_ID    
     left outer join INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY    
     left outer join INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY    
     cross join @t as t4    
     ---cross join MICSSYS --10/29/2014 DRP: Removed    
    WHERE B.CustUniqKey=' '    
     AND (L.IS_DELETED =0 or L.is_deleted is null)    
     --AND 1 = CASE WHEN NOT @lcDate IS NULL THEN CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END ELSE 1 END --09/22/15 DRP:  replaced by the filter that was added tothe BomIndented Procedure    
    )   
  insert into @results    
  select  isnull(CUSTOMER.CUSTNAME,'') as CustName,PUniq_key,t5.part_no as ParentBomPn  
 ,t5.REVISION as ParentBomRev,t5.DESCRIPT as ParentBomDesc,t5.MATLTYPE,@lcQty as BldQty    
    ,b1.ITEM_NO,Used_inKit,b1.viewpartno as DispPart_no,b1.ViewRevision as DispRevision    
    ,case when @lcIgnore = 'No'   
   then ((b1.topqty*b1.qty)*@lcQty)+b1.SetupScrap+ round((((B1.Qty * @lcQty)*B1.Scrap)/100),0)     
     else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*@lcQty)+b1.SetupScrap     
     else case when @lcIgnore = 'Ignore Setup Scrap'    
    then ((b1.topqty*b1.qty)*@lcQty) + round((((B1.Qty * @lcQty)*B1.Scrap)/100),0)    
     else case when @lcIgnore = 'Ignore Both Scraps'    
    then ((b1.topqty*b1.qty)*@lcQty) else CAST(0.00 as numeric(15,2)) end end end end as Req_Qty    
    ,CASE when @lcBomParent =  B1.BomParent THEN ' ' ELSE 'f' end as Phantom  
 ,b1.Part_class,b1.Part_type    
    ,b1.UNIQ_KEY,b1.Dept_id,b1.DEPT_NAME,b1.scrap,b1.SetupScrap,b1.bomParent,b1.Part_sourc  
 ,b1.TopQty*b1.qty as Qty,b1.Descript,b1.U_of_meas,b1.MbPhSource,b1.SubParent,b1.PART_NO,b1.CustPartNo    
    ,CAST (0 as bit) as Phant_make,b1.Revision,b1.MatlType,b1.CustRev  
 ,case when b1.CustUniqKey=' ' then id.location else li.location end as location,warehous.WAREHOUSE    
    ,case when b1.CustUniqKey=' ' THEN ID.QTY_oh else LI.qty_oh END as qty_oh  
 ,CASE WHEN B1.CustUniqKey = '' THEN ID.QTY_OH-ID.RESERVED ELSE LI.QTY_OH - LI.RESERVED END AS QtyNotReserved    
    ,case when (antiavl.PARTMFGR is null)   
    then 'A' else '' end as antiAVL,b1.PARTMFGR,b1.MFGR_PT_NO,b1.MfgrMatlType,b1.ORDERPREF    
    ,case when b1.CustUniqKey=' ' THEN B1.UNIQMFGRHD else L.UNIQMFGRHD END as UNIQMFGRHD  
 ,case when @lcBomParent = B1.bomparent   
       then '' else  rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) end as PhParentPn    
    ,CASE WHEN B1.CustUniqKey = '' THEN ID.INSTORE ELSE LI.INSTORE END AS INSTORE,b1.level,b1.sort,b1.Status, b1.Bom_note    
    
  FROM BomWithAvl AS B1    
    left outer join customer on B1.bomcustno = customer.CUSTNO    
    left outer join Invtmfgr ID ON B1.Uniqmfgrhd = ID.Uniqmfgrhd and B1.CustUniqKey=' ' and ID.is_deleted=0    
    --02/24/17 YS removed Invtmfhd table and replace with MfgrMaster and Invtmpnlink    
    LEFT OUTER JOIN InvtMpnLink L ON B1.Uniq_Key=L.UNIQ_KEY and B1.CustUniqKey<>' ' and l.is_deleted=0    
     LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId and  M.Partmfgr=B1.Partmfgr and M.Mfgr_pt_no=B1.Mfgr_pt_no  and m.is_deleted=0    
    --LEFT OUTER JOIN Invtmfhd MI on MI.uniq_key=B1.uniq_key and B1.CustUniqKey<>' ' and MI.IS_DELETED=0 and MI.Partmfgr=B1.Partmfgr and MI.Mfgr_pt_no=B1.Mfgr_pt_no    
    left outer join Invtmfgr LI on l.Uniqmfgrhd=LI.Uniqmfgrhd and LI.IS_DELETED=0    
    LEFT OUTER JOIN WAREHOUS ON LI.UNIQWH = WAREHOUS.UNIQWH OR ID.UNIQWH = WAREHOUS.UNIQWH    
    left outer join ANTIAVL on B1.Bomparent = ANTIAVL.BOMPARENT and ((b1.Uniq_key = ANTIAVL.UNIQ_KEY AND b1.CustUniqKey =' ') or (b1.CustUniqKey = ANTIAVL.UNIQ_KEY AND b1.CustUniqKey <>' ') )    
      and b1.PARTMFGR = ANTIAVL.PARTMFGR and b1.MFGR_PT_NO = ANTIAVL.MFGR_PT_NO    
    left outer join INVENTOR as I3 on b1.BomParent = I3.UNIQ_KEY    
    
    ,@t as t5    
    
  WHERE @lcBomParent = right(Left(b1.path,11),10)    
    and @lcBomParent = t5.uniq_key    
    and used_inkit = case when @SupUsedKit = 0   
        then Used_inKit else (select Used_inKit where Used_inKit <> 'N') end     
    and 1 = CASE @lcStatus WHEN 'Active' THEN CASE WHEN b1.STATUS = 'Active' THEN 1 ELSE 0 END ELSE 1 END --02/18/2015 DRP:  Added    
    
/*09/24/15 DRP:  the above replaced the below in order to make sure that we were grabbing the correct qty on hand information for both internal and consigned.     
  insert into @results    
  select isnull(CUSTOMER.CUSTNAME,'') as CustName,PUniq_key,t5.part_no as ParentBomPn,t5.REVISION as ParentBomRev,t5.DESCRIPT as ParentBomDesc,t5.MATLTYPE,@lcQty as BldQty    
    ,b1.ITEM_NO,Used_inKit,b1.viewpartno as DispPart_no,b1.ViewRevision as DispRevision    
    ,case when @lcIgnore = 'No' then ((b1.topqty*b1.qty)*@lcQty)+b1.SetupScrap+ round((((B1.Qty * @lcQty)*B1.Scrap)/100),0)    
    else case when @lcIgnore = 'Ignore Scrap' then ((b1.topqty*b1.qty)*@lcQty)+b1.SetupScrap    
    else case when @lcIgnore = 'Ignore Setup Scrap' then ((b1.topqty*b1.qty)*@lcQty) + round((((B1.Qty * @lcQty)*B1.Scrap)/100),0)    
    else case when @lcIgnore = 'Ignore Both Scraps' then ((b1.topqty*b1.qty)*@lcQty) else CAST(0.00 as numeric(15,2)) end end end end as Req_Qty    
    --,case when @lcIgnore = 'No' and  ROW_NUMBER() OVER(Partition by b1.uniq_key,sort Order by b1.uniq_key)=1 then ((b1.topqty*b1.qty)*@lcQty)+b1.SetupScrap+ round((((B1.Qty * @lcQty)*B1.Scrap)/100),0)     
    -- else case when @lcIgnore = 'Ignore Scrap' and  ROW_NUMBER() OVER(Partition by b1.uniq_key,sort Order by b1.uniq_key)=1  then ((b1.topqty*b1.qty)*@lcQty)+b1.SetupScrap     
    --  else case when @lcIgnore = 'Ignore Setup Scrap' and  ROW_NUMBER() OVER(Partition by b1.uniq_key,sort Order by b1.uniq_key)=1  then ((b1.topqty*b1.qty)*@lcQty) + round((((B1.Qty * @lcQty)*B1.Scrap)/100),0)    
    --   else case when @lcIgnore = 'Ignore Both Scraps' and  ROW_NUMBER() OVER(Partition by b1.uniq_key,sort Order by b1.uniq_key)=1  then ((b1.topqty*b1.qty)*@lcQty) else CAST(0.00 as numeric(15,2)) end end end end as Req_Qty    
    ,CASE when @lcBomParent =  B1.BomParent THEN ' ' ELSE 'f' end as Phantom,b1.Part_class,b1.Part_type    
    ,b1.UNIQ_KEY,b1.Dept_id,depts.DEPT_NAME,b1.scrap,b1.SetupScrap,b1.bomParent,b1.Part_sourc,b1.TopQty*b1.qty as Qty,b1.Descript,b1.U_of_meas,b1.MbPhSource,b1.SubParent,b1.PART_NO,b1.CustPartNo    
    ,CAST (0 as bit) as Phant_make,b1.Revision,b1.MatlType,b1.CustRev,invtmfgr.location,warehous.WAREHOUSE    
    ,CASE WHEN ROW_NUMBER() OVER(Partition by b1.uniqmfgrhd,w_key Order by b1.uniqmfgrhd,w_key)=1 then invtmfgr.qty_oh else CAST(0.00 as numeric(15,2)) end as Qty_oh    
    ,CASE WHEN ROW_NUMBER() OVER(Partition by b1.uniqmfgrhd,w_key Order by b1.uniqmfgrhd,w_key)=1 then invtmfgr.qty_oh-invtmfgr.reserved  else CAST(0.00 as numeric(15,2)) end as QtyNotResrved    
    ,case when (antiavl.PARTMFGR is null) then 'A' else '' end as antiAVL,b1.PARTMFGR,b1.MFGR_PT_NO,b1.MfgrMatlType,b1.ORDERPREF,b1.UNIQMFGRHD    
    ,case when @lcBomParent = B1.bomparent then '' else  rtrim(I3.PART_NO) + ' / '+rtrim(I3.revision) end as PhParentPn,INSTORE,b1.level,    
    b1.sort,b1.Status    
   FROM BomWithAvl AS B1    
    left outer join DEPTS on b1.Dept_id = depts.DEPT_ID    
    left outer join INVTMFGR on b1.uniqmfgrhd = invtmfgr.uniqmfgrhd    
    left outer join warehous on invtmfgr.uniqwh = warehous.uniqwh    
    left outer join ANTIAVL on B1.Bomparent = ANTIAVL.BOMPARENT and ((b1.Uniq_key = ANTIAVL.UNIQ_KEY AND b1.CustUniqKey =' ') or (b1.CustUniqKey = ANTIAVL.UNIQ_KEY AND b1.CustUniqKey <>' ') )    
     and b1.PARTMFGR = ANTIAVL.PARTMFGR and b1.MFGR_PT_NO = ANTIAVL.MFGR_PT_NO    
        
    left outer join INVENTOR as I3 on b1.BomParent = I3.UNIQ_KEY    
    left outer join customer on B1.bomcustno = customer.CUSTNO    
    ,@t as t5    
    
  WHERE @lcBomParent = right(Left(b1.path,11),10)    
    and @lcBomParent = t5.uniq_key    
    and used_inkit = case when @SupUsedKit = 0 then Used_inKit else (select Used_inKit where Used_inKit <> 'N') end     
    and 1 = CASE @lcStatus WHEN 'Active' THEN CASE WHEN b1.STATUS = 'Active' THEN 1 ELSE 0 END ELSE 1 END --02/18/2015 DRP: Added    
--09/25/15 DRP: Removal End */      
    
  /*10/29/2014 DRP: added this section in order to get the correct qty on hand and qty not reserved. */    
  -- 06/12/2015 DRP:  replaced ISNULL(MATLTYPE,'') as MfgrMatlType with ISNULL(MFGRMTLTYPE,'') as MfgrMatlType    
  ;    
  with    
  zTotal as (    
  select uniqmfgrhd,SUM(qty_oh) as Qty_oh,SUM(qtyNotReserved) as QtyNotReserved    
  from @results R1    
  where 0 = case when Part_Sourc = 'MAKE' and MbPhSource = '' then 1 else 0 end    
  group by DispPart_No,DispRevision,UniqMfgrHd    
  )    
  update @results set Qty_Oh = t1.qty_oh,QtyNotReserved = t1.qtyNotReserved    
  from zTotal t1,@results R2    
  where t1.UniqMfgrHd = R2.UniqMfgrHd    
  --10/29/2014 DRP: below was replaced by below Select.    
  --select R.*    
  --from @results as R    
  -- cross join MICSSYS    
  --where 0 = case when Pa    
  select distinct Custname,PUniq_key,ParentBomPn,ParentBomRev,ParentBomDesc,ParentMatlType,BldQty  
  ,Item_No,Used_InKit,DispPart_No,DispRevision,Req_Qty,Phantom    
  ,Part_Class,Part_Type,Uniq_key,Dept_Id,Dept_Name,Scrap,SetupScrap  
  ,BomParent  
  ,Part_Sourc,Qty,Descript  
  ,U_of_Meas,MbPhSource, SubParent  
  ,case when SubParent = '' then CAST (0 as bit) else CAST(1 as bit)end as SubP,Part_No,CustPartNo  
  ,Phant_Make,Revision, MatlType,CustRev  
  ,case when CustPartNo = ''   
  then CAST(0 as bit) else CAST(1 as bit) end as CPN  
  ,isnull(Qty_Oh,0.00) as Qty_Oh  
  ,isnull(QtyNotReserved,0.00) as QtyNotReserved,AntiAvl,isnull(PARTMFGR,'') as PARTMFGR  
  ,ISNULL(cast(MFGR_PT_NO as CHAR(35))    
  ,'No Avl''s exist check Item Master') as MFGR_PT_NO,ISNULL(ORDERPREF,0) AS ORDERPREF  
  ,ISNULL(MfgrMtlType,'') as MfgrMatlType    
  ,ISNULL(UNIQMFGRHD,'') AS UNIQMFGRHD,PhParentPn,isnull(Instore,0) as Instore,Level,sort,[status], Bom_note  
  
  from @results as R    
  where 0 = case when Part_Sourc = 'MAKE' and MbPhSource = '' then 1 else 0 end    
  ORDER BY Sort    
end    
     
    