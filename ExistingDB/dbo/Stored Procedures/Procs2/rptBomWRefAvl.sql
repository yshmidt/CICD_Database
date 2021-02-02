  
-- =============================================  
-- Author:  Debbie  
-- Create date: 08/15/2012  
-- Description: Created for the Bill of Material with Ref Designator & AVL Reports  
-- Reports Using Stored Procedure:  bomrpt9.rpt // bomrpt9asof.rpt //bomrpt3.rpt // bomrpt2.rpt  
-- Modifications: 09/21/2012 DRP:  I needed to increase the Descript Char from (40) to (45), it was causing truncation error on the reports WHEN the Description field was max'd out.  
--     05/22/2013 DRP:  there was a spot within the code where I was calling BomIndented procedure and I had incorrectly had the MatlType AS char(8) WHEN it should have been char(10).  It was causing truncating issues.    
--     03/19/14 YS added Buyer column to [BomIndented]  
-- 10/10/14 YS replace invtmfhd with 2 new tables  
--     10/16/2014 DRP:  making changes to the procedure in order for it to work with Cloud Manex:  needed to change @lcProd and @lcRev to be @lcUniqkey  
--          moved the @userId to the top of the procedure.  also changed that section to now work with the @lcUniqkey  
--          I was having issues getting the MRT report to work the way I wanted it to where SubParents and Cust Part No are concerned.  I had to add CPN and SubP columns to the results in order for me to get the report to work properly.  
--     10/24/2014 DRP:  If the users were able to get the Customer AVL to save blank (no avls at all) THEN the item would drop off of the results.  Needed to make changes to display the part and indicate that there are no AVL's loaded  
-- 10/29/14 YS moved orderpref from mfgrmaster to invtmpnlink and changed type to int  
--     01/06/2015 DRP:  Added @customerStatus Filter   
--     01/23/2015 DRP:  Found that the UserId was not properly checking to see if the user has access to that Customer information.     
--          Added <and 1 = case WHEN Customer.CUSTNO in (select CUSTNO from @customer ) THEN 1 ELSE 0 END> to the @t section that gathers the parent information    
--          --for the time being I had to disable this line of code.  Which is not correct, we should have it in place so only approved users can view BOM for their approved customer list.  
          --But for some reason AS soon I AS place this in the scripts the quickviews will still work properly, but the StimulSoft report within Cloud Viewer will stop working. It is AS if the userId is no longer being passed  
          --I compared it to all of the other report I have created in Stimulsoft and they appear to be setup the same way.   
--     02/18/2015 DRP:  Added one more parameter @lcStatus to show only Active parts or not  
--     04/27/2015 DRP: The Phantom BOMS were not having anything displayed in the results of the BOM REports.  Upon further review I believe that it had to do with the situation mentioned above with the Customer List no generating the correct results on the reports.   
--         made changes to the Where statement on the @T section below.  Changing {{and 1 = case WHEN Customer.CUSTNO in (select CUSTNO from @customer ) THEN 1 ELSE 0 END}} to {{and (EXISTS (SELECT 1 FROM @Customer C where c.CUSTNO = Inventor.CUSTNO))"}}  
--     09/22/15 DRP:  added the @lcDate to the <<INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,1,0,@UserId,@lcDate>> to make sure that it is pulling only the Active items from the BOM  
--     12/22/16 DRP: Due to recent changes in how the bom leveling is numbered (used to start at 0 and now has been changed to start at 1) we needed to make the needed changes within the Where Clause at the END of this procedure.   
--     02/15/17 DRP: added int_uniq and mfgrname to the results per request by user  
--- 03/28/17 YS changed length of the part_no column from 25 to 35  
--  08/14/17 YS added PR values   
-- 09/18/17 VL added next line to filter the customer by bomcustno (copy from rptBomOutdentedWhereUsed)  
-- 12/10/2018 Sachin B Fix the Issue the WHEN the BOM Component Avl are not checked THEN the Components are not coming in the Reports add OUTER APPLY and Remove Not Exists Condition
-- 12/10/2018 Sachin B Insert one Default Empty Customer in the Temp Table @Customer
-- 12/10/2018 Sachin B Add Temp tables WithoutMfg,WithMfg,CommonData,AllData for the Getting Manufactures Data
-- 12/10/2018 Shrikant B remove outer apply and use left join to Fix the Issue the WHEN the BOM Component Avl are some of check and some of uncheck in consign customer all manufacturer displayed check and unchecked
-- 05/24/2019 Shrikant added column Bom_note for assembly note
-- 05/28/19 VL added CutSheet
-- 06/03/19 VL adde bom_note into INSERT INTO @tBom field list
-- 08/13/19 VL found I didn't added CutSheet in WithoutMfg and WithMfg, also added @lcShowCutSheet parameter
-- 04/16/20 VL added IS NULL condition for the records that didn't have Mfgr

-- rptBomWRefAvl '000-0003194 DC', 'No', '05/24/2019', 1,1, 'Yes', 'Yes', 'All','Active', '49f80792-e15e-4b62-b720-21b360e3108a'    
-- =============================================    

CREATE PROCEDURE [dbo].[rptBomWRefAvl]  
--declare  
  -- @lcProd varchar(25) = '' --10/16/2014 DRP:   REMOVED  
  --,@lcRev char(8) = ''  --10/16/2014 DRP:  Removed   
   @lcUniqkey CHAR(10) = ''   
  ,@lcExplode CHAR (3) = 'Yes'  
  ,@lcDate SMALLDATETIME = '19000101' 
  ,@IncludeMakeBuy BIT = 1  
  ,@showIndentation BIT = 1  
  ,@lcItemNotes CHAR(3) = 'No' --10/20/2014 DRP:  Added will determine if the Item Notes are included in the results or not    
  ,@lcBomNotes CHAR(3) = 'No'  --10/20/2014 DRP:  Added will determin if the BomNotes are included in the results or not   
  ,@customerStatus VARCHAR (20) = 'All' --01/06/2015 DRP: ADDED  
  ,@lcStatus CHAR(8) = 'Active' --02/18/2015 DRP:  Added  
  ,@userId UNIQUEIDENTIFIER = null  
  ,@lcShowCutSheet char(3) = 'No'
     
AS  
BEGIN    
   
/*CUSTOMER LIST*/ --10/16/2014 DRP:  Added  
 DECLARE  @tCustomer AS tCustomer  
 DECLARE @Customer TABLE (custno CHAR(10))  
  -- get list of Customers for @userid with access  
  INSERT INTO @tCustomer EXEC aspmnxSP_Getcustomers4user @userid,null,@customerStatus ;  
  --SELECT * FROM @tCustomer   
  BEGIN  
   INSERT INTO @Customer SELECT Custno FROM @tCustomer 
   -- 12/10/2018 Sachin B Insert one Default Empty Customer in the Temp Table @Customer 
   INSERT INTO @Customer (custno) VALUES ('') 
  END  
  
  
/*SELECT STATEMENT*/  
    
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
   
 -- list of parameters:  
 -- 1. @lcProd - top level BOM Product #  
 -- 2. @lcRev = Top Level Revision   
 -- 6. @lcExplode = if left AS No THEN the BOM will only display top level components.  If Yes, THEN the report will explode out components down to all sublevles  
 -- 3. @lcDate = If left empty the system should default in 19000101, which is THEN switched to the machines current date below.    
 --  if the user enters null THEN it will display ALL items regardless of the Eff/OB date for the items.  WHEN populated with a date THEN it will filter items based off of the Eff/OB dates.  
 -- 4. @IncludeMakeBuy if the value is 1 will explode make/buy parts ; if 0 - will not (default 1)  
 -- 5. @ShowIndentation add spaces in front of the PartView value to clearly show indentation (for now 4 spaces if =1, no spaces if =0, can customize later)  
  
   
 --- this sp will   
 ----- 1. find BOM information and explode PHANTOM and Make parts. If the make part has make/buy flag and @IncludeMakeBuy=0, THEN Make/Buy will not be indented to the next level  
 ----- 2. Figure out AVL (if internal part, but BOM assigned to a customer, an appropriate consign part AVL will be found  
 ----- 3. Remove AVL if any AntiAvl are assigned  
  
 SET @lcDate = CASE WHEN @lcDate='19000101' THEN DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0)   
     WHEN  NOT @lcDate IS NULL THEN DATEADD(day, DATEDIFF(day, 0, @lcDate), 0) ELSE @lcDate END  
  
--This table will be used to find the Product, revision and uniq_key for the product entered by the user.  The uniq_key from this table will THEN be used to pull fwd from the [BomIndented] Yelena had created.   
-- 09/21/2012 DRP:  increased the descript char from (40) to (45)  
 --- 03/28/17 YS changed length of the part_no column from 25 to 35  
 DECLARE @t TABLE(PART_NO CHAR (35),REVISION CHAR(8),descript char (45),UNIQ_key CHAR (10),matltype CHAR(10),
 bomcustno CHAR(10),CustName CHAR(35), Bom_Note TEXT)   
    
 INSERT @T SELECT part_no,revision,descript,uniq_key,matltype,BOMCUSTNO,ISNULL(custname,''), bom_note  
    FROM inventor   
      LEFT OUTER JOIN CUSTOMER ON inventor.BOMCUSTNO = customer.CUSTNO  
    WHERE inventor.UNIQ_KEY = @lcUniqkey  
      AND PART_SOURC <> 'CONSG'  
      -- 09/18/17 VL comment out next line, I think we should not use "inventor.custno", shoud use "inventor.bomcustno" to check  
      --and (EXISTS (SELECT 1 FROM @Customer C where c.CUSTNO = Inventor.CUSTNO))     --04/27/2015 DRP:  Added this filter statement that appears to work properly with the UserId filters.   
      --and 1 = case WHEN Customer.CUSTNO in (select CUSTNO from @customer ) THEN 1 ELSE 0 END 
      --01/23/2015 DRP: for the time being I had to disable this line of code.  Which is not correct, we should have it in
      --place so only approved users can view BOM for their approved customer list.  
                             --But for some reason AS soon I AS place this in the scripts the quickviews will still work properly, but the StimulSoft report within Cloud Viewer will stop working. It is AS if the userId is no longer being passed  
                             --I compared it to all of the other report I have created in Stimulsoft and they appear to be setup the same way.   
      -- 09/18/17 VL added next line to filter the customer by bomcustno (copy from rptBomOutdentedWhereUsed)  
      AND 1 = CASE WHEN inventor.BOMCUSTNO IN (SELECT CUSTNO FROM @Customer) THEN 1 ELSE 0 END  
  
--select * from @t  
--I am declaring the other parameters that would be needed in order to pull in the [BomIndented] procedure    
 declare  @lcBomParent char(10)   
    --,@UserId uniqueidentifier=NULL --10/16/2014 DRP:  moved to the top of the procedure  
  --  @UserId - for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.  
  
 SELECT  @lcBomParent = t1.uniq_key FROM @t AS t1  
  
--declaring the table to match exactly the fields/data from the [BomIndented] procedure   
-- 03/19/14 YS added Buyer column to [BomIndented]  
 --- 03/28/17 YS changed length of the part_no column from 25 to 35  
  -- 05/28/19 VL added CutSheet varchar(max)
 DECLARE @tBom TABLE (bomParent char(10), bomcustno char(10), UNIQ_KEY char(10), item_no numeric(4), 
     PART_NO char(35),Revision char(8),Part_sourc char(10) ,  
	 ViewPartNo varchar(max), ViewRevision char(8),Part_class char(8), Part_type char(8), Descript char(45),
	 MatlType char(10), Dept_id char(8),Item_note varchar(max), Offset numeric(4,0),  
	 Term_dt date,Eff_dt date, Used_inKit char(1), custno char(10), Inv_note varchar(max), U_of_meas char(4)
	 , Scrap numeric(6,2), SetupScrap numeric(4,0), USESETSCRP bit  
	 ,STDBLDQTY numeric(8,0),Phantom_make bit, StdCost numeric(13,5),Make_buy bit, Status char(10),TopQty numeric(9,2)
	 ,qty numeric(9,2), Level integer, path varchar(max)  
	 --- 03/28/17 YS changed length of the part_no column from 25 to 35  
	 ,sort varchar(max),UniqBomNo char(10),Buyer char(3),  
	 stdcostpr numeric(13,5),funcFcUsed_uniq char(10) ,PrFcUsed_uniq char(10),  
	 CustPartNo char(35),CustRev char(8),CustUniqKey char(10)
-- 05/24/2019 Shrikant added column Bom_note for assembly note	 
	 , Bom_note varchar(max),
	-- 05/28/19 VL added CutSheet and nId for updating purpose
	CutSheet varchar(max), nId int Identity) 
  
	-- 05/28/19 VL added CutSheet, so need to list all fields 
	-- 06/03/19 VL added Bom_note
	--INSERT INTO @tBom EXEC  [BomIndented] @lcBomParent,@IncludeMakeBuy,@ShowIndentation,@UserId,@lcDate  
	DECLARE @lnTotalCnt int, @lnCnt int, @UniqBomno char(10), @output varchar(max)
	INSERT INTO @tBom (bomParent,bomcustno,UNIQ_KEY,item_no,PART_NO,Revision,Part_sourc, ViewPartNo,ViewRevision,Part_class,Part_type,Descript,MatlType,Dept_id,Item_note,Offset,  
					Term_dt,Eff_dt, Used_inKit,custno,Inv_note,U_of_meas, Scrap,SetupScrap,USESETSCRP,STDBLDQTY,Phantom_make,StdCost,Make_buy,Status,TopQty,qty,Level, path, 
					sort,UniqBomNo,Buyer,stdcostpr,funcFcUsed_uniq,PrFcUsed_uniq, CustPartNo,CustRev,CustUniqKey, Bom_note)
		EXEC  [BomIndented] @lcBomParent,@IncludeMakeBuy,@ShowIndentation,@UserId,@lcDate  

	SELECT @lnTotalCnt = @@ROWCOUNT
	SELECT @lnCnt = 0

	-- 08/13/19 VL only update if need to show cut sheet
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
		-- 05/28/19 VL End}		   
	END
	-- 08/13/19 VL End}
	  
  ; WITH BomWithAvl  
   --10/10/14 YS replace invtmfhd with 2 new tables  
   AS  
   (  
	   SELECT B.*,depts.DEPT_NAME,   
		   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE Mfhd.PARTMFGR END AS PARTMFGR,
		   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE Mfhd.MFGR_PT_NO END AS MFGR_PT_NO,
		   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE mfhd.ORDERPREF END AS ORDERPREF,
		   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE mfhd.UNIQMFGRHD END AS UNIQMFGRHD,
		   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE Mfhd.MATLTYPE END AS MfgrMatlType,
		   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE Mfhd.MATLTYPEVALUE END AS MATLTYPEVALUE,  
		   isnull(dbo.fnBomRefDesg(b.UniqBomNo),'') AS RefDesg   
		   ,CASE WHEN I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 THEN 'Phantom/Make'  
				WHEN i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom'   
				WHEN I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 THEN 'Make/Buy'
				ELSE ''  END AS MbPhSource  
		  ,CASE WHEN t3.UNIQ_KEY = I4.uniq_key THEN '' 
				ELSE rtrim(I4.part_no)+'  /  '+rtrim(I4.revision) END AS SubParent  
		   ,t3.PART_NO AS Prod, t3.REVISION AS ProdRev, T3.uniq_key AS PUniq_key, t3.descript AS ProdDesc
		   , t3.matltype AS ProdMatlType, ISNULL(t3.CustName,'') AS CustName
		   --,t3.Bom_Note, 
		   , i3.INT_UNIQ,
		   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE mfhd.text END AS MFGRNAME --02/15/17 DRP:  Added  
		   --,MICSSYS.LIC_NAME --10/16/2014 DRP:  removed  
		   -- 10/10/14 YS replace invtmfhd with 2 new tables  
		   --FROM @tBom B   
		   --left outer JOIN (select * from INVTMFHD where invtmfhd.IS_DELETED = 0) AS invtmfhd on  B.CustUniqKey=INVTMFHD.UNIQ_KEY  --10/24/2014 DRP:  replaced . . .  left outer JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY   
		   --FROM @tBom B LEFT OUTER JOIN (SELECT l.Uniq_key,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MATLTYPE,M.MATLTYPEVALUE  
		   --      FROM InvtMPNLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId where l.is_deleted=0 and m.is_deleted=0) Mfhd  
		   --      ON  B.CustUniqKey=mfhd.UNIQ_KEY  --02/15/17 DRP:  replaced with the below.   
			,CASE WHEN temp.UNIQ_KEY IS NULL THEN 1 ELSE 0 END AS te
	   FROM @tBom B 
	   LEFT OUTER JOIN 
		(    
			 SELECT l.Uniq_key,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MATLTYPE,M.MATLTYPEVALUE,support.text          
			 FROM InvtMPNLink L 
			 INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
			 INNER JOIN support ON rtrim(m.partmfgr) = rtrim(support.text2) WHERE l.is_deleted=0 and m.is_deleted=0
	   ) Mfhd  
	   ON  B.CustUniqKey=mfhd.UNIQ_KEY
	   -- 12/10/2018 Sachin B Fix the Issue the WHEN the BOM Component Avl are not checked THEN the Components are not coming in the Reports add OUTER APPLY and Remove Not Exists Condition  
 	   
  --  OUTER APPLY         
  --(   
  --  SELECT bomParent,UNIQ_KEY         
  --  FROM ANTIAVL A         
  --  where         
  --  A.BOMPARENT =B.bomParent         
  --  and A.UNIQ_KEY = B.UNIQ_KEY         
  --  and A.PARTMFGR =MFHD.PARTMFGR         
  --  and A.MFGR_PT_NO =mfhd.MFGR_PT_NO        
  --)        
  --temp       
  -- 12/10/2018 Shrikant B remove outer apply and use left join to Fix the Issue the WHEN the BOM Component Avl are some of check and some of uncheck in consign customer all manufacturer displayed check and unchecked
    LEFT JOIN ANTIAVL temp  ON temp.BOMPARENT =B.bomParent AND temp.UNIQ_KEY = B.CustUniqKey 
							   AND temp.PARTMFGR =MFHD.PARTMFGR AND temp.MFGR_PT_NO =mfhd.MFGR_PT_NO      
	   LEFT OUTER JOIN DEPTS ON b.Dept_id = depts.DEPT_ID  
	   LEFT OUTER JOIN INVENTOR I3 ON B.UNIQ_KEY = i3.UNIQ_KEY  
	   LEFT OUTER JOIN INVENTOR i4 ON b.Bomparent = I4.UNIQ_KEY   
	   CROSS JOIN @t AS T3  

	  WHERE 
	  --02/20/19 Shrikant B Added Condition UNIQ_KEY IS NULL      
   B.CustUniqKey<>' ' and temp.UNIQ_KEY IS NULL         
	  --AND Invtmfhd.IS_DELETED =0 --10/24/2014 DRP:  removed and should be taken care of within the left outer join above   
	  --AND 1 = CASE WHEN NOT @lcDate IS NULL THEN CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END ELSE 1 END --09/22/15 DRP:  Removed  
	 -- 12/10/2018 Sachin B Fix the Issue the WHEN the BOM Component Avl are not checked THEN the Components are not coming in the Reports add OUTER APPLY and Remove Not Exists Condition
	 -- and 
	  --NOT EXISTS 
	  --(		SELECT bomParent,UNIQ_KEY FROM ANTIAVL A 
		 --   where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =MFHD.PARTMFGR and A.MFGR_PT_NO =mfhd.MFGR_PT_NO 
	  --)  


 UNION ALL  
	  select B.*,depts.DEPT_NAME,  
	   --10/10/14 YS replace invtmfhd with 2 new tables  
	  --Mfhd.PARTMFGR ,Mfhd.MFGR_PT_NO,mfhd.ORDERPREF ,mfhd.UNIQMFGRHD,Mfhd.MATLTYPE AS MfgrMatlType,Mfhd.MATLTYPEVALUE,
	   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE Mfhd.PARTMFGR END AS PARTMFGR,
	   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE Mfhd.MFGR_PT_NO END AS MFGR_PT_NO,
	   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE mfhd.ORDERPREF END AS ORDERPREF,
	   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE mfhd.UNIQMFGRHD END AS UNIQMFGRHD,
	   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE Mfhd.MATLTYPE END AS MfgrMatlType,
	   CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE Mfhd.MATLTYPEVALUE END AS MATLTYPEVALUE,    
	   ISNULL(dbo.fnBomRefDesg(b.UniqBomNo),'') AS RefDesg  
	   ,CASE WHEN I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.PHANT_MAKE = 1 THEN 'Phantom/Make'  
		WHEN i3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'PHANTOM' THEN 'Phantom'   
		 WHEN I3.UNIQ_KEY <> @lcBomParent and I3.PART_SOURC = 'MAKE' and I3.MAKE_BUY = 1 THEN 'Make/Buy'
		  ELSE ''  END AS MbPhSource  
	   ,CASE WHEN t4.UNIQ_KEY = I4.uniq_key THEN '' ELSE rtrim(I4.part_no)+'  /  '+rtrim(i4.revision) END AS SubParent  
	  ,t4.PART_NO AS Prod,t4.REVISION AS ProdRev,t4.uniq_key AS PUniq_key,t4.descript AS ProdDesc
	  ,t4.matltype AS ProdMatlType,
	  ISNULL(t4.CustName,'') AS CustName

	  ,i3.INT_UNIQ,
	  CASE WHEN temp.UNIQ_KEY IS NOT NULL THEN '' ELSE mfhd.text END AS MFGRNAME --02/15/17 DRP:  Added  
	  --,MICSSYS.LIC_NAME --10/16/2014 DRP:  Removed  
	   --FROM @tBom B   
	   --left outer JOIN (select * from INVTMFHD where invtmfhd.IS_DELETED = 0) AS invtmfhd on  B.UNIQ_KEY=INVTMFHD.UNIQ_KEY --10/24/2014 DRP:  replaced . . .left outer join INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY  
	   --10/10/14 YS replace invtmfhd with 2 new tables  
	   ,CASE WHEN temp.UNIQ_KEY IS NULL THEN 1 ELSE 0 END AS te
	   FROM @tBom B   
		--LEFT OUTER JOIN (SELECT l.Uniq_key,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MATLTYPE ,M.MATLTYPEVALUE  
		--      FROM InvtMPNLink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId where l.is_deleted=0 and m.is_deleted=0) Mfhd  
		--      ON  B.Uniq_Key=mfhd.UNIQ_KEY  02/15/17 DRP:  replaced with the below.   
		LEFT OUTER JOIN 
		(
			  SELECT l.Uniq_key,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MATLTYPE ,M.MATLTYPEVALUE,support.text  
			  FROM InvtMPNLink L 
			  INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
			  inner join support ON rtrim(m.partmfgr) = rtrim(support.text2) WHERE l.is_deleted=0 and m.is_deleted=0
	    ) Mfhd  
		ON  B.Uniq_Key=mfhd.UNIQ_KEY  
		-- 12/10/2018 Sachin B Fix the Issue the WHEN the BOM Component Avl are not checked THEN the Components are not coming in the Reports add OUTER APPLY and Remove Not Exists Condition
  --OUTER APPLY         
  --(  SELECT bomParent,UNIQ_KEY         
  --  FROM ANTIAVL A         
  --  where         
  --  A.BOMPARENT =B.bomParent         
  --  and A.UNIQ_KEY = B.UNIQ_KEY         
  --  and A.PARTMFGR =MFHD.PARTMFGR         
  --  and A.MFGR_PT_NO =mfhd.MFGR_PT_NO        
  --)        
  --temp    
 -- 12/10/2018 Shrikant B remove outer apply and use left join to Fix the Issue the WHEN the BOM Component Avl are some of check and some of uncheck in consign customer all manufacturer displayed check and unchecked
  LEFT JOIN ANTIAVL temp  ON temp.BOMPARENT =B.bomParent AND temp.UNIQ_KEY = B.Uniq_Key AND temp.PARTMFGR =MFHD.PARTMFGR AND temp.MFGR_PT_NO =mfhd.MFGR_PT_NO          
		LEFT OUTER JOIN DEPTS ON b.Dept_id = depts.DEPT_ID  
		LEFT OUTER JOIN INVENTOR I3 ON B.UNIQ_KEY = i3.UNIQ_KEY  
		LEFT OUTER JOIN INVENTOR i4 ON b.Bomparent = I4.UNIQ_KEY 

		CROSS JOIN @t AS t4  
		--cross join MICSSYS --10/16/2014 DRP:  Removed  
	  WHERE B.CustUniqKey=' '  
	  --AND Invtmfhd.IS_DELETED =0 --10/24/2014 DRP:  removed and should be taken care of within the left outer join above  
	  --AND 1 = CASE WHEN NOT @lcDate IS NULL THEN CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt is Null or DATEDIFF(day,TERM_DT,@lcDate)<0) THEN 1 ELSE 0 END ELSE 1 END --09/22/15 DRP:  Removed  
	  -- 12/10/2018 Sachin B Fix the Issue the WHEN the BOM Component Avl are not checked THEN the Components are not coming in the Reports add OUTER APPLY and Remove Not Exists Condition
	  --and NOT EXISTS 
	  --(
			--	SELECT bomParent,UNIQ_KEY 
			--	FROM ANTIAVL A 
			--	where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =MFHD.PARTMFGR and A.MFGR_PT_NO =mfhd.MFGR_PT_NO 
	  --)  
  )  
  
 --SELECT  * from BomWithAvl where 0 = case WHEN @lcExplode = 'Yes' THEN 0 ELSE Level END  ORDER BY Sort --10/16/2014 DRP:  replaced by below so I could implement some formulas that I used to calculate on the reports only [QtyEach].    
 --10/16/2014 DRP:  Added CPN and SubP to the results below in order to get the MRT report to work properly   
 --- 08/14/17 YS removed stcost column , is not used in any reports  
 -- 12/10/2018 Sachin B Add Temp tables WithoutMfg,WithMfg,CommonData,AllData for the Getting Manufactures Data
 ,WithoutMfg AS(
				SELECT DISTINCT bomParent,bomcustno,UNIQ_KEY,item_no,PART_NO ,Revision,Part_sourc,
					ViewPartNo, ViewRevision, Part_class,Part_type,Descript,MatlType,Dept_id  
					--10/20/2014 DRP:  added the case statement to work for the lcItemNote parameter  
					,CASE WHEN @lcItemNotes = 'Yes' THEN Item_note ELSE CAST ('' AS VARCHAR(MAX)) END AS Item_note  
					,Offset,Term_dt,Eff_dt, Used_inKit,custno,Inv_note,U_of_meas, Scrap,SetupScrap,USESETSCRP,STDBLDQTY,
					Phantom_make,Make_buy,[Status],TopQty,qty,TopQty*qty AS QtyEach  
					,[Level],[path],sort,UniqBomNo,Buyer,CustPartNo,CustRev,
					CASE WHEN CustPartNo = '' THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS CPN,DEPT_NAME  
					,ISNULL(PARTMFGR,'') AS PARTMFGR,
					ISNULL(cast(MFGR_PT_NO AS CHAR(35))
					,'No Avl''s exist check Item Master') AS MFGR_PT_NO  
					,ISNULL(ORDERPREF,0) AS ORDERPREF
					,ISNULL(UNIQMFGRHD,'') AS UNIQMFGRHD
					,ISNULL(MfgrMatlType,'') AS MfgrMatlType
					,ISNULL(MATLTYPEVALUE,'') AS MATLTYPEVALUE  
					,RefDesg ,MbPhSource,SubParent,
					 CASE WHEN SubParent = '' THEN CAST (0 AS BIT) ELSE CAST(1 AS BIT)END AS SubP  
					,Prod,ProdRev,PUniq_key,ProdDesc,ProdMatlType,CustName
					,case WHEN @lcBomNotes = 'Yes' THEN Bom_Note ELSE CAST('' AS varchar(max)) END AS Bom_note  
					--'' AS Bom_note
					--,CASE WHEN @lcBomNotes = 'Yes' THEN BomWithAvl.Bom_Note ELSE CAST('' AS varchar(max)) END AS Bom_note   
					,INT_UNIQ,MFGRNAME --02/15/17 DRP:  Added 
				-- 08/13/19 VL found I didn't added CutSheet in WithoutMfg and WithMfg
				,CutSheet
				FROM BomWithAvl   
				WHERE (@lcExplode='Yes' or (@lcExplode='No' and Level=1))  
				--1 = case WHEN @lcExplode = 'Yes' THEN 1 ELSE Level END  --12/22/16 DRP: Replaced with the above.   
				AND 1 = CASE @lcStatus WHEN 'Active' THEN CASE WHEN Status = 'Active' THEN 1 ELSE 0 END ELSE 1 END
				 --02/18/2015 DRP:  Added 
				 -- 04/16/20 VL added IS NULL condition for the records that didn't have Mfgr
				--AND RTRIM(LTRIM(BomWithAvl.PARTMFGR)) ='' AND RTRIM(LTRIM(BomWithAvl.MFGR_PT_NO)) =''
				AND ((RTRIM(LTRIM(BomWithAvl.PARTMFGR)) ='' AND RTRIM(LTRIM(BomWithAvl.MFGR_PT_NO)) ='')
					OR (BomWithAvl.PARTMFGR IS NULL AND BomwithAvl.Mfgr_pt_no IS NULL))
				-- 04/16/20 VL End}
 )
 ,WithMfg AS (
				SELECT DISTINCT bomParent,bomcustno,UNIQ_KEY,item_no,PART_NO ,Revision,Part_sourc,ViewPartNo,ViewRevision,
					Part_class,Part_type,Descript,MatlType,Dept_id  
					--10/20/2014 DRP:  added the case statement to work for the lcItemNote parameter  
					,CASE WHEN @lcItemNotes = 'Yes' THEN Item_note ELSE CAST ('' AS VARCHAR(MAX)) END AS Item_note 
					,Offset,Term_dt,Eff_dt, Used_inKit,custno,Inv_note,U_of_meas, Scrap,SetupScrap,USESETSCRP,STDBLDQTY
					,Phantom_make,Make_buy,[Status],TopQty,qty,TopQty*qty AS QtyEach  
				    ,[Level],[path],sort,UniqBomNo,Buyer,CustPartNo,CustRev
					,CASE WHEN CustPartNo = '' THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END AS CPN,DEPT_NAME  
				    ,ISNULL(PARTMFGR,'') AS PARTMFGR
					,ISNULL(CAST(MFGR_PT_NO AS CHAR(35)),'No Avl''s exist check Item Master') AS MFGR_PT_NO  
				    ,ISNULL(ORDERPREF,0) AS ORDERPREF,ISNULL(UNIQMFGRHD,'') AS UNIQMFGRHD
					,ISNULL(MfgrMatlType,'') AS MfgrMatlType,ISNULL(MATLTYPEVALUE,'') AS MATLTYPEVALUE  
				    ,RefDesg ,MbPhSource,SubParent
					,CASE WHEN SubParent = '' THEN CAST (0 AS BIT) ELSE CAST(1 AS BIT)END AS SubP  
				    ,Prod,ProdRev,PUniq_key,ProdDesc,ProdMatlType,CustName
				   ,CASE WHEN @lcBomNotes = 'Yes' THEN Bom_Note ELSE CAST('' AS varchar(max)) END AS Bom_note  
				   -- '' AS Bom_note
				   --,CASE WHEN @lcBomNotes = 'Yes' THEN  BomWithAvl.Bom_Note  ELSE CAST('' AS varchar(max)) END AS Bom_note   
				   ,INT_UNIQ,MFGRNAME --02/15/17 DRP:  Added  
				-- 08/13/19 VL found I didn't added CutSheet in WithoutMfg and WithMfg
				,CutSheet
				FROM BomWithAvl   
				WHERE (@lcExplode='Yes' or (@lcExplode='No' and Level=1))  
				--1 = case WHEN @lcExplode = 'Yes' THEN 1 ELSE Level END  --12/22/16 DRP: Replaced with the above.   
			   AND 1 = CASE @lcStatus WHEN 'Active' 
					THEN CASE WHEN Status = 'Active' THEN 1 ELSE 0 END ELSE 1 END --02/18/2015 DRP:  Added 
			   AND (PARTMFGR <>'' OR MFGR_PT_NO <>'')
 ) 
 ,CommonData AS ( 
		 SELECT DISTINCT WOMfg.* FROM WithMfg WMfg
		 INNER JOIN WithoutMfg WOMfg ON WMfg.bomParent =WOMfg.bomParent AND WMfg.UNIQ_KEY =WOMfg.UNIQ_KEY
 )
 ,AllData AS(
		SELECT * FROM WithMfg
	 UNION ALL
		 SELECT WOMfg.* FROM WithoutMfg WOMfg
		 LEFT JOIN CommonData co ON WOMfg.bomParent =co.bomParent AND WOMfg.UNIQ_KEY =co.UNIQ_KEY
		 WHERE co.bomParent IS NULL AND co.UNIQ_KEY IS NULL    
 )
 SELECT * FROM AllData ORDER BY Sort
END   
 