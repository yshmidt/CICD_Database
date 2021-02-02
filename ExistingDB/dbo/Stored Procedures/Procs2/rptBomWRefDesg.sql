-- =============================================  
-- Author:     Debbie  
-- Create date:    10/16/2013  
-- Description:    Created for the Bill of Material with Ref Designator  
-- Reports:     bomrpt1  
-- Modified:09/21/2012 DRP:  I needed to increase the Descript Char from (40) to (45), it was causing truncation error on the reports when the Description field was max'd out.  
--   05/22/2013 DRP: there was a spot within the code where I was calling BomIndented procedure and I had incorrectly had the MatlType as char(8) when it should have been char(10).  It was causing truncating issues.    
--      10/16/2013 DRP: I took a copy of the [rptBomWRefAvl] procedure and made modifications to remove the AVL information.  
--          Changed the @lcProd parameter to @lcUniqKey since in Web We pass the uniqkey instead of the part number itself.  Also removed the Revision parameter  
--       Added the @UserId Parameter  
--   11/25/2013 DRP: Changed the resulting name of Offset to BomOffset.  
--   03/19/14 YS  added Buyer column to [BomIndented]  
--     10/20/2014 DRP: added ItemsNotes and BomNotes parameters.  
--   01/22/2015 DRP: added the following fields to the final results so they could be used on the report form. (Prod,ProdRev,ProdDesc,ProdMatlType,CustName,PUniq_key,MbPhSource)  
--       Added CPN and SubP to the results below in order to get the MRT report to work properly  
--       Needed to add the /*CUSTOMER LIST*/ in order for the results to only display if the UserId is approved to see that customer information.    
--       Added <and 1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end> to the @t where Parent Prod information is gathered   
--          --for the time being I had to disable this line of code.  Which is not correct, we should have it in place so only approved users can view BOM for their approved customer list.  
          --But for some reason as soon I as place this in the scripts the quickviews will still work properly, but the StimulSoft report within Cloud Viewer will stop working. It is as if the userId is no longer being passed  
          --I compared it to all of the other report I have created in Stimulsoft and they appear to be setup the same way.   
--   04/27/2015 DRP: The Phantom BOMS were not having anything displayed in the results of the BOM REports.  Upon further review I believe that it had to do with the situation mentioned above with the Customer List no generating the correct results on the reports.   
--       made changes to the Where statement on the @T section below.  Changing {{and 1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end}} to {{and (EXISTS (SELECT 1 FROM @Customer C where c.CUSTNO = Inventor.CUSTNO))"}}   
--   04/30/2015 DRP: moved the Part_No and Revision to the end of the results.  And Placed ViewPartNo and ViewRevision at the beginning, because that is what the reports are using.  
--   09/22/15 DRP:  added the @lcDate to the <<INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,1,0,@UserId,@lcDate>> to make sure that it is pulling only the Active items from the BOM  
--   12/22/16 DRP: Due to recent changes in how the bom leveling is numbered (used to start at 0 and now has been changed to start at 1) we needed to make the needed changes within the Where Clause at the end of this procedure.  
--- 03/28/17 YS changed length of the part_no column from 25 to 35  
--   08/14/17 YS added PR values   
-- 09/18/17 VL added next line to filter the customer by bomcustno (copy from rptBomOutdentedWhereUsed)
-- 05/24/2019 Shrikant added column Bom_note for assembly note
-- 05/24/2019 Shrikant remove to avoid the error The column 'Bom_Note' was specified multiple times for 'BomDetail'.
-- 05/30/19 VL added CutSheet
-- 06/03/19 VL added Bom_note into INSERT INTO @tBom field list
-- 08/15/19 VL added  @lcShowCutSheet report parameter and only add cutsheet if user chooses to

-- rptBomWRefDesg '_39P0RLDFH', 'No', '05/25/2019', 1,1, 'Yes', 'Yes', 'All', '49f80792-e15e-4b62-b720-21b360e3108a'    
-- =============================================  
CREATE PROCEDURE [dbo].[rptBomWRefDesg]  
  
--declare  
   @lcUniqKey varchar(25) = ''    -- the user would select Product and Revision from Screen for top level BOM Product, but the Uniq_key will be passed to this parameter  
  ,@lcExplode char (3) = 'No'    --if left as No then the BOM will only display top level components.  If Yes, then the report will explode out components down to all sublevles  
  ,@lcDate smalldatetime = '19000101'  --If left empty the system should default in 19000101, which is then switched to the machines current date below.    
            --if the user enters null then it will display ALL items regardless of the Eff/OB date for the items.  When populated with a date then it will filter items based off of the Eff/OB dates.  
  ,@IncludeMakeBuy bit = 1    --if the value is 1 will explode make/buy parts ; if 0 - will not (default 1)  
  ,@showIndentation Bit = 1    --add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later)  
  ,@lcItemNotes char(3) = 'No'   --10/20/2014 DRP:  Added will determine if the Item Notes are included in the results or not    
  ,@lcBomNotes char(3) = 'No'    --10/20/2014 DRP:  Added will determin if the BomNotes are included in the results or not  
  ,@customerStatus varchar (20) = 'All' --01/23/2015 DRP: ADDED  
  ,@userId uniqueidentifier= null  --for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.  
  ,@lcShowCutSheet char(3) = 'No'
    
as  
begin   
  
   
/*CUSTOMER LIST*/ --10/16/2014 DRP:  Added  
 DECLARE  @tCustomer as tCustomer  
 DECLARE @Customer TABLE (custno char(10))  
  -- get list of Customers for @userid with access  
  INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,@customerStatus ;  
  --SELECT * FROM @tCustomer   
  BEGIN  
   INSERT INTO @Customer SELECT Custno FROM @tCustomer  
  END  
 --select * from @Customer  
    
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
   
 --- this sp will   
 ----- 1. find BOM information and explode PHANTOM and Make parts. If the make part has make/buy flag and @IncludeMakeBuy=0, then Make/Buy will not be indented to the next level  
  
 SET @lcDate = CASE WHEN @lcDate='19000101' THEN DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0)   
     WHEN  NOT @lcDate IS NULL THEN DATEADD(day, DATEDIFF(day, 0, @lcDate), 0) ELSE @lcDate END  
  
--This table will be used to find the Product, revision and uniq_key for the product entered by the user.  The uniq_key from this table will then be used to pull fwd from the [BomIndented] Yelena had created.   
-- 09/21/2012 DRP:  increased the descript char from (40) to (45)  
--- 03/28/17 YS changed length of the part_no column from 25 to 35  
 DECLARE @t TABLE(PART_NO CHAR (35),REVISION CHAR(8),descript char (45),UNIQ_key CHAR (10),matltype char(10),bomcustno char(10),CustName char(35), Bom_Note text)   
    
 INSERT @T SELECT part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,isnull(custname,''), bom_note  
    FROM inventor   
      LEFT OUTER JOIN CUSTOMER on inventor.BOMCUSTNO = customer.CUSTNO   
    WHERE UNIQ_KEY = @lcUniqKey AND PART_SOURC <> 'CONSG'  
      -- 09/18/17 VL comment out next line, I think we should not use "inventor.custno", shoud use "inventor.bomcustno" to check  
      --and (EXISTS (SELECT 1 FROM @Customer C where c.CUSTNO = Inventor.CUSTNO))     --04/27/2015 DRP:  Added this filter statement that appears to work properly with the UserId filters.   
      --and 1 = case when Customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end --01/23/2015 DRP: for the time being I had to disable this line of code.  Which is not correct, we should have it in place so only approved users can view BOM for their approved customer list.  
                             --But for some reason as soon I as place this in the scripts the quickviews will still work properly, but the StimulSoft report within Cloud Viewer will stop working. It is as if the userId is no longer being passed  
                             --I compared it to all of the other report I have created in Stimulsoft and they appear to be setup the same way.   
      -- 09/18/17 VL added next line to filter the customer by bomcustno (copy from rptBomOutdentedWhereUsed)  
      and 1 = CASE WHEN inventor.BOMCUSTNO IN (SELECT CUSTNO FROM @Customer) THEN 1 ELSE 0 END  
  
--select * from @t  
--I am declaring the other parameters that would be needed in order to pull in the [BomIndented] procedure    
 DECLARE @lcBomParent char(10)   
 SELECT  @lcBomParent = t1.uniq_key from @t as t1  
  
--declaring the table to match exactly the fields/data from the [BomIndented] procedure   
-- 03/19/14 YS added Buyer column to [BomIndented]  
--- 03/28/17 YS changed length of the part_no column from 25 to 35  
-- 05/30/19 VL added CutSheet varchar(max)
 declare @tBom table (bomParent char(10),bomcustno char(10),UNIQ_KEY char(10),item_no numeric(4),PART_NO char(35),Revision char(8),Part_sourc char(10) ,  
 ViewPartNo varchar(max),ViewRevision char(8),Part_class char(8),Part_type char(8),Descript char(45),MatlType char(10),Dept_id char(8),Item_note varchar(max),BomOffset numeric(4,0),  
 Term_dt date,Eff_dt date, Used_inKit char(1),custno char(10),Inv_note varchar(max),U_of_meas char(4), Scrap numeric(6,2),SetupScrap numeric(4,0),USESETSCRP bit  
 ,STDBLDQTY numeric(8,0),Phantom_make bit,StdCost numeric(13,5),Make_buy bit,Status char(10),TopQty numeric(9,2),qty numeric(9,2),Level integer, path varchar(max)  
 --- 03/28/17 YS changed length of the part_no column from 25 to 35  
 ,sort varchar(max),UniqBomNo char(10),Buyer char(3)  
 --   08/14/17 YS added PR values   
 ,stdcostpr numeric(13,5),funcFcUsed_uniq char(10) ,PrFcUsed_uniq char(10)  
 ,CustPartNo char(35),CustRev char(8),CustUniqKey char(10)
 -- 05/24/2019 Shrikant added column Bom_note for assembly note	 
	 , Bom_note varchar(max)
	-- 05/30/19 VL added CutSheet and nId for updating purpose
	,CutSheet varchar(max), nId int Identity) 

	-- 05/30/19 VL added Cut Sheet, so need to list all fields 
	-- 06*03/19 VL added Bom_note
	DECLARE @lnTotalCnt int, @lnCnt int, @UniqBomno char(10), @output varchar(max)
	--INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,@IncludeMakeBuy,@ShowIndentation,@UserId,@lcDate  
	INSERT INTO @tBom (bomParent,bomcustno,UNIQ_KEY,item_no,PART_NO,Revision,Part_sourc, ViewPartNo,ViewRevision,Part_class,Part_type,Descript,MatlType,Dept_id,Item_note,BomOffset,  
					Term_dt,Eff_dt, Used_inKit,custno,Inv_note,U_of_meas, Scrap,SetupScrap,USESETSCRP,STDBLDQTY,Phantom_make,StdCost,Make_buy,Status,TopQty,qty,Level, path, 
					sort,UniqBomNo,Buyer,stdcostpr,funcFcUsed_uniq,PrFcUsed_uniq, CustPartNo,CustRev,CustUniqKey, Bom_note)
		EXEC  [BomIndented] @lcBomParent,@IncludeMakeBuy,@ShowIndentation,@UserId,@lcDate  

	SELECT @lnTotalCnt = @@ROWCOUNT
	SELECT @lnCnt = 0

	-- 08/15/19 VL only update if need to show cut sheet
	IF @lcShowCutSheet = 'Yes'
	BEGIN

		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'udtBOM_Details')
		BEGIN
			WHILE @lnCnt < @lnTotalCnt
			BEGIN
				SELECT @lnCnt = @lnCnt + 1
				SELECT @UniqBomno = UniqBomno FROM @tBom WHERE nId = @lnCnt
				EXEC GetBomDetCutSheet @uniqBomno, @output OUTPUT
				UPDATE @tBom SET CutSheet = @output WHERE nId = @lnCnt
	
			END
		END
		-- 05/30/19 VL End}	
	END
	-- 08/15/19 VL End}
	  
   --@lcBomParent char(10)='_1EP0Q018H' , @IncludeMakeBuy bit=1 , @ShowIndentation bit=1, @UserId uniqueidentifier='49F80792-E15E-4B62-B720-21B360E3108A', @gridId varchar(50) = null  
--select * from @tBom   
  
  ;  
   WITH BomDetail  
   AS  
   (  
   select B.*,depts.DEPT_NAME  
    --, InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD,invtmfhd.MATLTYPE as MfgrMatlType,INVTMFHD.MATLTYPEVALUE  
    ,isnull(dbo.fnBomRefDesg(b.UniqBomNo),'') as RefDesg   
    ,case when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'  
    when i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom'   
     when I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 
	 then 'Make/Buy' else ''  end as MbPhSource  
    ,case when t3.UNIQ_KEY = I4.uniq_key 
	then '' else rtrim(I4.part_no)+'  /  '+rtrim(I4.revision) end as SubParent  
    ,t3.PART_NO as Prod,t3.REVISION as ProdRev,T3.uniq_key as PUniq_key,t3.descript as ProdDesc
	,t3.matltype as ProdMatlType, isnull(t3.CustName,'') as CustName
	--,t3.Bom_Note  
   FROM  @tBom B   
  -- LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY   
   LEFT OUTER JOIN DEPTS on b.Dept_id = depts.DEPT_ID  
   LEFT OUTER JOIN INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY  
   LEFT OUTER JOIN INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY   
   CROSS JOIN @t as T3  
  
   WHERE B.CustUniqKey<>' '  
   --AND Invtmfhd.IS_DELETED =0   
   --AND 1 = CASE WHEN NOT @lcDate IS NULL THEN CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END ELSE 1 END --09/22/15 DRP:  Removed  
     --and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )  
 UNION ALL  
  select B.*,depts.DEPT_NAME  
      --,InvtMfhd.PARTMFGR ,Invtmfhd.MFGR_PT_NO,Invtmfhd.ORDERPREF ,Invtmfhd.UNIQMFGRHD,invtmfhd.MATLTYPE as MfgrMatlType,INVTMFHD.MATLTYPEVALUE  
      ,isnull(dbo.fnBomRefDesg(b.UniqBomNo),'') as RefDesg  
      ,case when I3.UNIQ_KEY <> @lcBomParent AND I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 then 'Phantom/Make'  
       when i3.UNIQ_KEY <> @lcBomParent AND I3.PART_SOURC = 'PHANTOM' THEN 'Phantom'   
        when I3.UNIQ_KEY <> @lcBomParent AND I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 
		then 'Make/Buy' else ''  end as MbPhSource  
      ,case when t4.UNIQ_KEY = I4.uniq_key 
	  then '' else rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) end as SubParent  
      ,t4.PART_NO as Prod,t4.REVISION as ProdRev,t4.uniq_key as PUniq_key,t4.descript as ProdDesc
	  ,t4.matltype as ProdMatlType,isnull(t4.CustName,'') as CustName
	-- 05/24/2019 Shrikant remove to avoid the error The column 'Bom_Note' was specified multiple times for 'BomDetail'.
	  --,t4.Bom_Note  
  FROM @tBom B   
    --LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY   
    LEFT OUTER JOIN DEPTS on b.Dept_id = depts.DEPT_ID  
    LEFT OUTER JOIN INVENTOR I3 on B.UNIQ_KEY = i3.UNIQ_KEY  
    LEFT OUTER JOIN INVENTOR i4 on b.Bomparent = I4.UNIQ_KEY  
    CROSS JOIN @t as t4  
  WHERE B.CustUniqKey=' '  
       --AND Invtmfhd.IS_DELETED =0   
       --AND 1 = CASE WHEN NOT @lcDate IS NULL THEN CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END ELSE 1 END --09/22/15 DRP:  Removed  
    --and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )  
  )  
  ---08/14/17 YS remove stdcost column  
  select bomParent,bomcustno,UNIQ_KEY,item_no,Part_sourc,ViewPartNo,ViewRevision,Part_class,Part_type,Descript,MatlType,Dept_id  
    ,case when @lcItemNotes = 'Yes' then Item_note else CAST ('' as varchar(max)) end as Item_note --10/20/2014 DRP:  added the case statement to work for the lcItemNote parameter  
    ,BomOffset,Term_dt,Eff_dt,Used_inKit,custno,Inv_note,U_of_meas,Scrap,SetupScrap,USESETSCRP,STDBLDQTY
	,Phantom_make,Make_buy,Status,TopQty,qty,Level,path,sort,UniqBomNo,Buyer,CustPartNo,CustRev,CustUniqKey
	,case when @lcBomNotes = 'Yes' then Bom_Note else CAST('' as varchar(max)) end as Bom_note  
    ,Prod,ProdRev,ProdDesc,ProdMatlType,CustName,PUniq_key,MbPhSource
	,case when CustPartNo = '' then CAST(0 as bit) else CAST(1 as bit) end as CPN  
    ,case when SubParent = '' then CAST (0 as bit) else CAST(1 as bit)end as SubP,RefDesg,PART_NO,Revision  
	-- 05/30/19 VL added CutSheet
	,CutSheet
  from BomDetail   
  where @lcExplode='Yes' or (@lcExplode='No' and Level=1)  
    --1 = case when @lcExplode = 'Yes' then 1 else Level end  --10/20/2014 DRP:  added the case statement to work for the lcItemNote parameter --12/22/16 DRP: Replaced with the above.   
  ORDER BY Sort   
    
  --SELECT  * from BomDetail where 0 = case when @lcExplode = 'Yes' then 0 else Level end  ORDER BY Sort --10/20/2014 DRP:  replaced with the above so the ItemNote and BOMNotes can be added.   
END  