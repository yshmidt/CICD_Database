		-- =============================================
		-- Author:		<Debbie> 
		-- Create date: <01/12/2010>
		-- Description:	<compiles details for the Packing List Form>
		-- Reports:     <used on packform.rpt>
		-- Modified:	02/29/2012 DRP - Realized that I forgot to display the MFGR and MPN if the packing list was for buy parts. >
		--				03/01/2012 DRP - Through testing found that the Packing List form was not working when there were Alpha Numeric Serial numbers.  Aslo found that I was pulling ALL SN records fwd
		--								 I needed to add more Where clauses to filter out the SN per Selected packing list #>
		--				03/09/2012 DRP:  I originally had the below updating code setup incorrect to match off of the Invoiceno instead of PackListNO field.  So if the Invoice and Packing List numbering was setup to be different it would not update aspmnx_ActiveUsers posted. >			
		--				04/13/2012 DRP:	 found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired.
		--				06/06/2012	VL:	 Update Plmain.PkPostDate to save when the PK is posted
		--				10/05/2012 DRP:  had to replace  <<select CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as integer) AS iSerialNo>>
		--			  					 with <<select CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint) AS iSerialNo>>	
		--				10/05/2012 DRP:  Found that if the users did not have a Shipping address selected that it would not pull the packing List detail forward at all.
		--								 Change the Inner Join to Outer Join
		--				11/16/2012 DRP:  Enhancement Request:  added pldetail.certdone to the procedure below so that we can add the  "C of C Required" indicator on the Packing List print out.
		--				11/26/2012	VL:	 Changed ISNULL(cast(inventor.descript as CHAR(45)),CAST(pldetail.cdescr as CHAR(45))) as Descript to 
		--									     ISNULL(CASt(Inventor.Descript AS CHAR(45)),ISNULL(CAST(Sodet_Desc AS CHAR(45)),CAST(cDescr AS CHAR(45)))) AS Descript
		--				02/08/2013 DRP:	 User was experiencing truncated issue with one of their packing list.  Upon investigation found that the ShipAdd3 was the field that was being truncated. 
		--								 As a precaution I went through and updated all of the ShipAdd and BillAdd fields from whatever character it had before to char(40) and that addressed the issue.
 		--				08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.
		--				10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the packing list. 				
		--				01/24/2014 DRP:  The Line_no field needed to be increased from char(7) to char(10) due to the fact that I will use the uniqueln when it is a manual packing list and that is 10 characters.	
		--				04/08/2014 DRP:  Needed to change [CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint)] to [CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as numeric(30,0))] for users that had extremely large Serial Numbers entered into the system. 
		--				02/13/2015 DRP:  Serial numbers we causing overflow of the Packing List on screen and I need to add a space after the comma to get the SN to break properly. 
		--				03/30/2015 DRP:	 Added the uniqueln to the results.  in one particular user situation they could add the same line item Number multiple times and even for the same uniq_key.  In order to break them out on the report properly I needed to added the uniqueln to make the grouping unique. 
		--				04/07/2015 DRP:  Made the rptPackListFormWM copy of the procedure for the Cloud.  Added the /*PAGE LIST*/ to the procedure and also added the PageDesc to the results.  The item results will be repeated for as many times as there are PAGEDESC records.  
		--				04/22/2015 VL:   Added 'FirstinBatch' parameter default 1, if it's 1, delete last batch, will insert into 'PrevStat' at the end of this SP to save new last batch
 		--				01/27/16 YS move pkinvlot and pkalloc next to pldetail and invtmfgr and invtmfhd next to sodetail
		--				08/10/16 DRP:  Added the /*CUSTOMER LISTS*/ To make sure the users can only view their approved customer records.   Also combined the individual Address fields into one Address field.
		--				12/06/16 DRP:  <<left outer join INVTMFGR on sodetail.W_KEY = invtmfgr.W_KEY>>  replaced with <<left outer join INVTMFGR on pkalloc.W_KEY = invtmfgr.W_KEY>> in order to make sure we can get the Matl Type for all items on the packing list
		--				01/09/2017 Satish B - Added ITAR column in report grid
		--				01/13/2017 Satish B - Added RoHS column in report grid
		--              01/16/2017 Satish B - Does not display record with zero quantity in report 
		--				03/21/17 DRP:  I had originally added the Packing List Signature to the results back on 08/01/16, but found that it did not make it into the official release.  So I am now adding it back in. 
		--				08/21/17 DRP:  when user would had a large number of misc items to the packing list it would not sort per Line Item.  Added the Sort order at the end of this procedure. 
		--				10/25/2017 Satish B : Select PKFOOTNOTE from Note table instade of PLDETAIL table
		--				10/25/2017 Satish B : Select PKFOOTNOTE from wmNoteRelationship table instade of SHIPBILL table
		--				10/25/2017 Satish B : Added join of wmNotes and wmNoteRelationship table to get Pl foot note and pl line note
		--				11/01/2017 : Satish B : Added parameter @isPreviewOnly to avoid updation of PLMAIN table when preview the report
		--				11/01/2017 : Satish B : Create cte to get line note
		--				11/01/2017 : Satish B : Create cte to get foot note
		--				11/01/2017 : Satish B : Change selection of note from wmNoteRel.Note to wmLine.NOTE
		--				11/01/2017 : Satish B : Change selection of note from wmNoteRelation.Note to wmFoot.Note
		--				11/01/2017 : Satish B : Comment the join of wmNotes and wmNoteRelationship table
        --				11/13/2017 : Satish B : Added the filter of wmNoteRelationship.ImagePath
		--				01/10/18 VL: Suntronics could not print PK, found out shipped qty is about 17500, the serial number code (remove zero, make start-end) caused the issue, so changed to use temp table instead of CTE cursor to solve the issue
		--							 tried to use table variables at first, but could not add index to speed up due to some customers are still in SQL 2012, once added index on temp table, the same invoice run from 45 seconds to 4 seconds
		--				03/26/18 Satish B : select from #PLSerial instade of selection from PLSerial
		--				04/16/18 Satish B : Check null for ITAR
    --        07/16/18 VL changed custname from char(35) to char(50)
		--				06/8/2018 : Satish B : Create temp table for sid
		--				06/8/2018 : Satish B : Added IpKey in @tResults
		--			  06/8/2018 : Satish B : Insert values into #PLSID temp table
		--				06/8/2018 : Satish B : Select IpKey from #PLSid against each row
		--				06/8/2018 : Satish B : Drop temp table #PLSid
		-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
		-- 11/15/2019 : VL : This report took long time to load, so tried to move some code out of the big SQL and update later to speed up 
		-- 10/12/20	VL Changed #tResults.ShipTo and BillTo from char(40) to char(50)
		-- exec rptPackListFormWM '0000000693','ALL','49F80792-E15E-4B62-B720-21B360E3108A',1,1
		-- =============================================
     CREATE PROCEDURE [dbo].[rptPackListFormWM] 
	--declare	
		@lcPackListNo char(10) = ''
	   ,@lcPageLbl varchar(max) = 'ALL'
	   ,@userId uniqueidentifier=null
	   ,@firstinBatch bit = 1
	   --11/01/2017 : Satish B : Added parameter @isPreviewOnly to avoid updation of PLMAIN table when preview the report
	   ,@isPreviewOnly bit=0

AS
		BEGIN


/*CUSTOMER LIST*/	--08/10/16 DRP:  Added the Customer List		
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		

INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer

/*PAGE LIST*/
	---- SET NOCOUNT ON added to prevent extra result sets from
	---- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE  @tPageDesc AS TABLE (PAGENO numeric(1,0), PAGEDESC CHAR (25),PKINPGNMUK char(10))
	declare @tPageD as Table (PKINPGNMUK CHAR(10))
	insert into @tPageDesc select pageno,rtrim(pagedesc),PKINPGNMUK from PKINPGNM where type = 'P' and PAGEDESC <> ' '

	--SELECT * FROM @tPageDesc

	IF @lcPageLbl is not null and @lcPageLbl <>'' and @lcPageLbl<>'All'
		insert into @tPageD select * from dbo.[fn_simpleVarcharlistToTable](@lcPageLbl,',')
			where CAST (id as CHAR(10)) in (select PKINPGNMUK from @tPageDesc)
	ELSE
	--- empty or null customer or part number means no selection were made
	IF  @lcPageLbl='All'	
	BEGIN
		INSERT INTO @tPageD SELECT PKINPGNMUK FROM @tPageDesc

	END	

	--select * from @tPageD

	-- 04/22/15 VL added to delete all invoice last batch if @firstinBatch = 1
	IF @firstinBatch = 1
	BEGIN
		DELETE FROM PrevStat WHERE FIELDTYPE = 'PACKLIST'
	END

	-- 01/10/18 VL create temp tables to replace the CTE cursor, found if the PK has lots of serial numbers, the remove zero and start-end SN code used too much resource and got hang, temp tables with indexes really speed up
	CREATE TABLE #PLSerial (iSerialno numeric(30,0), Packlistno char(10), Uniqueln char(10))
	CREATE TABLE #startingPoints (iSerialno numeric(30,0), Packlistno char(10), Uniqueln char(10), rownum int)
	CREATE TABLE #EndingPoints (iSerialno numeric(30,0), Packlistno char(10), Uniqueln char(10), rownum int)
	CREATE TABLE #StartEndSerialno (iSerialno numeric(30,0), Packlistno char(10), Uniqueln char(10), rownum int, start_range numeric(30,0), end_range numeric(30,0))
	CREATE TABLE #FinalSerialno (Serialno varchar(MAX), Packlistno char(10), Uniqueln char(10))
	-- 06/8/2018 : Satish B : Create temp table for sid
	CREATE TABLE #PLSid (IpKey char(10), PacklistNo char(10), UniqueLn char(10))
	CREATE NONCLUSTERED INDEX Packlistno ON #PLSerial (Packlistno)
	CREATE NONCLUSTERED INDEX Uniqueln ON #PLSerial (Uniqueln)
	CREATE NONCLUSTERED INDEX Packlistno ON #startingPoints (Packlistno)
	CREATE NONCLUSTERED INDEX Uniqueln ON #startingPoints (Uniqueln)
	CREATE NONCLUSTERED INDEX Packlistno ON #EndingPoints (Packlistno)
	CREATE NONCLUSTERED INDEX Uniqueln ON #EndingPoints (Uniqueln)
	CREATE NONCLUSTERED INDEX Packlistno ON #StartEndSerialno (Packlistno)
	CREATE NONCLUSTERED INDEX Uniqueln ON #StartEndSerialno (Uniqueln)
	CREATE NONCLUSTERED INDEX Packlistno ON #FinalSerialno (Packlistno)
	CREATE NONCLUSTERED INDEX Uniqueln ON #FinalSerialno (Uniqueln)

/*RECORD SELECTION SECTION*/
---08/26/2013 YS :  changed Attn to varchar(200), increased length of the ccontact fields.
---03/21/17 DRP:  added the packListSignature varchar(max) to the results
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- 11/15/19 VL changed to temp table, try to speed up
		--Declare @tResults table	
		-- 10/12/20	VL Changed #tResults.ShipTo and BillTo from char(40) to char(50)
		CREATE TABLE #tResults (PackListNo char(10),CustNo char (10),CustName char (50),PoNo char (20),SoNo char(10),ShipDate smalldatetime,OrderDate smalldatetime
								,Line_no char(10)   --01/24/2014 DRP:--,Line_No char (7)
								,sortby char(7),Uniq_key char(10),PartNo char (35),Rev char (8),Descript char (45),CustPartNo char(35),CustRev char (8),CDescript char(45)
								,UofM char (4),w_key char(10),partmfgr char(8),mfgr_pt_no char (30),MatlType char(10)	--12/06/16 DRP:  Added MatlType
								,CertDone bit,OrdQty numeric (12,2),ShippedQty numeric (12,2)
								,SoBalance numeric (12,2), Note text,SerialNo varchar (max),Attn varchar (200),PackFoot text,ShipTo char (50)
								--,ShipAdd1 char (40),ShipAdd2 char (40),ShipAdd3 char (40),ShipAdd4 char (40)	--08/10/16 DRP:  Replaced with the individual ShipToAddress
								,ShipToAddress varchar(max),PkFootNote text,BillTo char(50)
								--,BillAdd1 char (40),BillAdd2 char(40),BillAdd3 char (40), BillAdd4 char(40)	--08/10/16 DRP:  Replaced with the individual BillToAddress
								,BillToAddress varchar(max),FOB char (15)
								,ShipVia char (15), BillAccount char (20),WayBill char (20),IsRMA varchar (3),LotCode char (15),ExpDate smalldatetime,Reference char(12),LotQty numeric (12,2),uniqueln char(10)
								--01/09/2017 Satish B - Added ITAR column in report grid
								--01/13/2017 Satish B - Added RoHS column in report grid
								,ITAR char (15),RoHS char (10)
								,packListSignature varchar(max)
								-- 06/8/2018 : Satish B : Added IpKey in @tResults
								,IpKey VARCHAR(MAX)
								-- 11/15/19 VL added Uniqmfgrhd for update partmfgr, mfgr_pt_no, matltype purpose
								,UniqMfgrhd char(10)
								-- 11/15/19 VL added Inv_link for update note purpose
								,Inv_link char(10))

		SET @lcPackListNo=dbo.PADL(@lcPacklistno,10,'0')
		-- 06/8/2018 : Satish B : Insert values into #PLSID temp table
		INSERT INTO #PLSid
			SELECT DISTINCT pdi.fk_IpKeyUnique AS IpKey,p.PacklistNo,p.UniqueLn
			FROM pldetail p
			INNER JOIN pldtlipkey pdi ON pdi.FK_INV_LINK=p.INV_LINK
			WHERE p.PACKLISTNO=@lcPackListNo 

		--this section will go through and compile any Serialno information
		-- 01/10/18 VL changed to use table variable
		--;
		--with
		--PLSerial AS
		--	  (

		-- 11/15/19 VL added code to check if any serial number for this PK, only go through if serial number exists
		IF EXISTS(SELECT 1 FROM Packlser WHERE Packlistno = @lcPackListNo)
		BEGIN
			INSERT INTO #PLSerial
			  --03/01/2012 DRP: had to change the casting of the serial numbers to interger in order for it to work with both Numeric/Alpha Numeric combination of serial numbers selected
			  --03/01/2012 DRP:	SELECT CAST(PS.Serialno as numeric(30,0)) as iSerialno,ps.packlistno,PS.UNIQUELN  
			  --10/05/2012 DRP:  had to replace  <<select CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as integer) AS iSerialNo>>
			  --			  	 with <<select CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint) AS iSerialNo>>	 
			  /*04/08/2014 drp: SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as bigint) as iSerialno,ps.packlistno,PS.UNIQUELN  */
			  SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as numeric(30,0)) as iSerialno,ps.packlistno,PS.UNIQUELN   
			  FROM packlser PS 
			  where PS.PACKLISTNO = @lcPackListNo
			  AND PATINDEX('%[^0-9]%',PS.serialno)=0 
			  --)
			 -- 01/10/18 VL changed to table variable
			 --; WITH startingPoints as
			 -- (
			 INSERT INTO #startingPoints
			  select A.*, ROW_NUMBER() OVER(PARTITION BY A.packlistno,uniqueln ORDER BY iSerialno) AS rownum
			  -- 03/26/18 Satish B : select from #PLSerial instade of selection from PLSerial
			  FROM #PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM #PLSerial AS B WHERE B.iSerialno=A.iSerialno-1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN )
			 -- )
			 --SELECT * FROM StartingPoints  
   			--,
			-- 01/10/18 VL changed to table variable
			--EndingPoints AS
			--(
			INSERT INTO #EndingPoints
			select A.*, ROW_NUMBER() OVER(PARTITION BY packlistno,uniqueln ORDER BY iSerialno) AS rownum
			-- 03/26/18 Satish B : select from #PLSerial instade of selection from PLSerial
			FROM #PLSerial AS A WHERE NOT EXISTS (SELECT 1 FROM #PLSerial AS B WHERE B.iSerialno=A.iSerialno+1 and B.PACKLISTNO =A.PACKLISTNO and B.UNIQUELN=A.UNIQUELN) 
			--)
			--SELECT * FROM EndingPoints
			--,
			-- 01/10/18 VL changed to table variable
			--StartEndSerialno AS 
			--(
			INSERT INTO #StartEndSerialno
			SELECT S.*,S.iSerialno AS start_range, E.iSerialno AS end_range
			FROM #StartingPoints AS S
			JOIN #EndingPoints AS E
			ON E.rownum = S.rownum and E.PACKLISTNO = S.PACKLISTNO and E.UNIQUELN =S.UNIQUELN 
			--)
			-- 01/10/18 VL changed to table variable
			--,FinalSerialno AS
			--(
			INSERT INTO #FinalSerialno 
			SELECT CASE WHEN A.start_range=A.End_range
					THEN CAST(RTRIM(CONVERT(char(30),A.start_range))  as varchar(MAX)) ELSE
					CAST(RTRIM(CONVERT(char(30),A.start_range))+'-'+RTRIM(CONVERT(char(30),A.End_range)) as varchar(MAX)) END as Serialno,
					packlistno,uniqueln
			FROM #StartEndSerialno  A
			UNION 
			SELECT CAST(DBO.fRemoveLeadingZeros(PS.Serialno) as varchar(max)) as Serialno,PS.packlistno,PS.UNIQUELN  
				from PACKLSER ps 
				where ps.PACKLISTNO = @lcPackListNo
				and (PS.Serialno LIKE '%[a-z]%' OR PATINDEX('%[^0-9A-Za-z]%',Ps.serialno)<>0) 
			--)
			--select * from FinalSerialno
		END
		-- 11/15/19 VL only run if SN exist

		--This section will then gather all other Packing list information and also include the Serial Number information from above.

		--02/29/2012 DRP:  Addded the W_key, Mfgr and MPN to the process to display when Buy parts are shipped out against a Sales Order/Packing List
		--04/13/2012 DRP:	found that if there was a large number of misc items added to the packing list that exceeded 10 that it would then begin not sorting them as desired. 
		--					added the sortby field below to address this situation. 
		---08/26/13 YS   changed attn to varchar(200), increased length of the ccontact fields.
			-- 01/10/18 VL comment out , and added ;WITH for wmLineNote cte
			--,
			-- 11/01/2017 : Satish B : Create cte to get line note

			-- 11/15/19 VL comment out the CTE cursor for now, it took too long, will use it after insert into @tResults
			--;WITH WmLineNote AS(
			--	SELECT ROW_NUMBER() OVER (PARTITION BY PL.INV_LINK ORDER BY wmNoteRel.CreatedDate DESC) AS ROWNUM,PL.INV_LINK,wmNoteRel.Note Note
			--	FROM PLDETAIL PL 
			--	    LEFT JOIN wmNotes wmn ON PL.INV_LINK=wmn.RecordId -- Used to get line note
			--		LEFT JOIN wmNoteRelationship wmNoteRel ON wmNoteRel.FkNoteId=wmn.NoteID
			--	WHERE PL.PACKLISTNO = @lcPackListNo
			--	-- 11/13/2017 : Satish B : Added the filter of wmNoteRelationship.ImagePath
			--	and wmNoteRel.ImagePath=''
			--) ,
			---- 11/01/2017 : Satish B : Create cte to get foot note
			--WmFootNote AS(
			--	SELECT ROW_NUMBER() OVER (PARTITION BY PM.PACKLISTNO ORDER BY wmNoteRelation.CreatedDate DESC) RowNum, PM.PACKLISTNO,Note 
			--	FROM PLMAIN PM 
			--		LEFT OUTER JOIN wmNotes w on PM.PACKLISTNO=w.RecordId	-- Used to get PkFoot note
			--		LEFT JOIN wmNoteRelationship wmNoteRelation on wmNoteRelation.FkNoteId=w.NoteID
			--	WHERE PM.PACKLISTNO  = @lcPackListNo
			--	-- 11/13/2017 : Satish B : Added the filter of wmNoteRelationship.ImagePath
			--	and wmNoteRelation.ImagePath=''
			--) ,
			-- 11/15/19 VL End}

		-- 11/15/19 VL changed from Packlist CTE to inert into @tResults directly
		INSERT #tResults
			select	plmain.PACKLISTNO,PLMAIN.CUSTNO,CUSTNAME,ISNULL(SOMAIN.PONO,SPACE(20)) AS PONO,ISNULL(somain.sono,space(10))as SONO,SHIPDATE,ORDERDATE
				,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No
				,ISNULL(sodetail.line_no,'X'+dbo.padl(rtrim(substring(pldetail.uniqueln,2,6)),6,'0')) as sortby
				,isnull(sodetail.uniq_key,space(10))as Uniq_key
				,isnull(inventor.PART_NO,SPACE(35)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev
				,ISNULL(CASt(Inventor.Descript AS CHAR(45)),ISNULL(CAST(Sodet_Desc AS CHAR(45)),CAST(cDescr AS CHAR(45)))) AS Descript
				--,ISNULL(cast(inventor.descript as CHAR(45)),CAST(pldetail.cdescr as CHAR(45))) as Descript
				,ISNULL(i2.custpartno,SPACE(35)) as CustPartNo,ISNULL(i2.custrev,space(8)) as CustRev, ISNULL(cast(i2.DESCRIPT as CHAR (45)),cast (pldetail.cdescr as CHAR(45))) as CDescript
				--	10/27/16 YS : replaced invtmfhd table with 2 new tables
				,PLDETAIL.UOFMEAS,sodetail.w_key
				-- 11/15/19 VL update MfgrMaster later to speed up
				--,M.PARTMFGR,M.MFGR_PT_NO,M.matltype	--12/06/16 DRP:  Added
				,SPACE(8) AS PARTMFGR, SPACE(30) AS MFGR_PT_NO, SPACE(10) AS matltype
				,pldetail.CERTDONE
				,case when plmain.SONO = '' then pldetail.SHIPPEDQTY else sodetail.ORD_QTY end as OrdQty,pldetail.SHIPPEDQTY,pldetail.SOBALANCE
				-- 10/25/2017 Satish B : Select PKFOOTNOTE from Note table instade of PLDETAIL table
				--,pldetail.NOTE
				-- 11/01/2017 : Satish B : Change selection of note from wmNoteRel.Note to wmLine.NOTE
				--,wmNoteRel.Note
				-- 11/15/19 VL update wm Note later
				--,wmLine.NOTE
				,'' AS NOTE
				--,CAST(stuff((select','+ps.Serialno	from FinalSerialno PS
				--									where	PS.PACKLISTNO = PLMAIN.PACKLISTNO
				--											AND PS.UNIQUELN = PLDETAIL.UNIQUELN
				--									ORDER BY SERIALNO FOR XML PATH ('')),1,1,'') AS VARCHAR (MAX)) AS Serialno	--02/13/2015 DRP:  replace with the below
				-- 11/15/19 VL will update serialno later to speed up
				--,CAST(stuff((select', '+ps.Serialno	from #FinalSerialno PS
				--									where	PS.PACKLISTNO = PLMAIN.PACKLISTNO
				--											AND PS.UNIQUELN = PLDETAIL.UNIQUELN
				--									ORDER BY SERIALNO FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) AS Serialno
				,'' AS Serialno
				,isnull(cast (rtrim(ccontact.LASTNAME) + ', ' + RTRIM(ccontact.FIRSTNAME) as varCHAR (200)),cast('' as varCHAR(200))) as Attn,plmain.PACK_FOOT
				,s.SHIPTO
				--,s.ADDRESS1 as ShipAdd1,case when s.ADDRESS2 = '' then RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) else s.address2 end as ShipAdd2
				--,case when s.address2 = '' then s.country else RTRIM(s.city) + ',  '+RTRIM(s.state)+'     '+RTRIM(s.zip) end as ShipAdd3
				--,case when s.address2 <> '' then s.country else '' end as ShipAdd4	--08/10/16 DRP:  Replaced with the individual ShipToAddress
				,rtrim(s.Address1)+case when s.address2<> '' then char(13)+char(10)+rtrim(s.address2) else '' end+
							  case when s.address3<> '' then char(13)+char(10)+rtrim(s.address3) else '' end+
							  case when s.address4<> '' then char(13)+char(10)+rtrim(s.address4) else '' end+
								CASE WHEN s.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.City)+',  '+rtrim(s.State)+'      '+RTRIM(s.zip)  ELSE '' END +
								CASE WHEN s.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(s.Country) ELSE '' end+
								case when s.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(s.PHONE) else '' end+
								case when s.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(s.FAX) else '' end  as ShipToAddress
				-- 10/25/2017 Satish B : Select PKFOOTNOTE from wmNoteRelationship table instade of SHIPBILL table
				--,s.PKFOOTNOTE
				-- 11/01/2017 : Satish B : Change selection of note from wmNoteRelation.Note to wmFoot.Note
				--,wmNoteRelation.Note AS PKFOOTNOTE
				-- 11/15/19 VL update PKFOOTNOTE later
				--,wmFoot.Note AS PKFOOTNOTE
				,'' AS PKFOOTNOTE
				,b.SHIPTO as BillTo
				--,b.ADDRESS1 as BillAdd1,case when b.ADDRESS2 = '' then RTRIM(b.city) + ',  '+RTRIM(B.state)+'     '+RTRIM(b.zip) else b.address2 end as BillAdd2
				--,case when b.address2 = '' then b.country else RTRIM(b.city) + ',  '+RTRIM(b.state)+'     '+RTRIM(b.zip) end as BillAdd3
				--,case when b.address2 <> '' then b.country else '' end as BillAdd4	--08/10/16 DRP:  Replaced with the individual BillToAddress
				,rtrim(b.Address1)+case when b.address2<> '' then char(13)+char(10)+rtrim(b.address2) else '' end+
							  case when b.address3<> '' then char(13)+char(10)+rtrim(b.address3) else '' end+
							  case when b.address4<> '' then char(13)+char(10)+rtrim(b.address4) else '' end+
								CASE WHEN b.City<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.City)+',  '+rtrim(b.State)+'      '+RTRIM(b.zip)  ELSE '' END +
								CASE WHEN b.Country<>' ' THEN  CHAR(13)+CHAR(10)+RTRIM(b.Country) ELSE '' end+
								case when b.phone <> '' then CHAR(13)+CHAR(10)+'Phone:  '+RTRIM(b.PHONE) else '' end+
								case when b.FAX <> '' then CHAR(13)+CHAR(10)+'Fax:  '+RTRIM(b.FAX) else '' end  as BillToAddress
				,plmain.FOB,plmain.SHIPVIA,plmain.BILLACOUNT,plmain.WAYBILL,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA, pkinvlot.LOTCODE,pkinvlot.expdate,PKINVLOT.REFERENCE,pkinvlot.ALLOCQTY,PLDETAIL.UNIQUELN
				--01/09/2017 Satish B - Added ITAR column in report grid
				--04/16/18 Satish B : Check null for ITAR
				,case when inventor.ITAR = 0 OR inventor.ITAR IS NULL then 'No' else 'Yes' end as ITAR
				--01/13/2017 Satish B - Added RoHS column in report grid
				,inventor.MATLTYPE as RoHS
				,[dbo].[fn_packListSignaturePath] () as packListSignature		--03/21/17 DRP:  added
				-- 06/8/2018 : Satish B : Select IpKey from #PLSid against each row
				-- 11/15/19 VL will update Ipkey later to speed up
				 --,CAST(stuff((select', '+ s.IpKey	from #PLSid s
					--								where	s.PACKLISTNO = PLMAIN.PACKLISTNO
					--										AND s.UNIQUELN = PLDETAIL.UNIQUELN
					--								ORDER BY IpKey FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) AS IpKey
				,'' AS IpKey
				-- 11/15/19 VL added Uniqmfgrhd for update partmfgr, mfgr_pt_no, matltype purpose
				, Invtmfgr.UNIQMFGRHD
				-- 11/15/19 VL added Inv_link
				,Pldetail.Inv_link
		--		10/05/2012 DRP:  Found that if the users did not have a Shipping address selected that it would not pull the packing List detail forward at all.
		--						 Changed from <<inner join SHIPBILL as S on plmain.LINKADD = s.LINKADD>> 	
		--						 To:  <<LEFT outer join SHIPBILL as S on plmain.LINKADD = s.LINKADD>>
				from	PLMAIN
				inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO
				LEFT OUTER JOIN SOMAIN ON PLMAIN.SONO = SOMAIN.SONO
				left outer join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
				--- 01/27/16 YS move pkinvlot and pkalloc next to pldetail and invtmfgr and invtmfhd next to sodetail
				left outer join PKALLOC on pldetail.PACKLISTNO = PKALLOC.PACKLISTNO and pldetail.UNIQUELN = PKALLOC.UNIQUELN
				left outer join PKINVLOT on pkalloc.PACKLISTNO = pkalloc.PACKLISTNO and pkalloc.UNIQ_ALLOC = PKINVLOT.UNIQ_ALLOC
				left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
				--- 01/27/16 YS move pkinvlot and pkalloc next to pldetail and invtmfgr and invtmfhd next to sodetail
				--left outer join INVTMFGR on sodetail.W_KEY = invtmfgr.W_KEY	--12/06/16 DRP:  replaced with the below
				left outer join INVTMFGR on pkalloc.W_KEY = invtmfgr.W_KEY
				--	10/27/16 YS : replaced invtmfhd table with 2 new tables
				--left outer join INVTMFHD on invtmfgr.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
				-- 11/15/19 comment out these two tables and update later
				--left outer join InvtMPNLink L ON Invtmfgr.UNIQMFGRHD=L.uniqmfgrhd
				--LEFT OUTER JOIN MfgrMaster M On l.mfgrMasterId=m.MfgrMasterId
				left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
--10/21/2013 DRP:  I needed to add the "and i2.CUSTNO = plmain.CUSTNO" whern i2 is joined otherwise I was getting every Customer Part number record that existed for the inventory part regardless which customer was selected for the packing list. 				
				--left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ 
				left outer join INVENTOR as i2 on inventor.UNIQ_KEY = i2.INT_UNIQ and i2.CUSTNO = plmain.CUSTNO
				left outer join CCONTACT on plmain.attention = ccontact.cid
				LEFT outer join SHIPBILL as S on plmain.LINKADD = s.LINKADD
				left outer join SHIPBILL as B on Plmain.BLINKADD = B.LINKADD 	
				-- 11/15/19 comment out these two tables and update later
				--LEFT JOIN WmLineNote wmLine ON PLDETAIL.INV_LINK = wmLine.INV_LINK AND wmLine.ROWNUM = 1
				--LEFT JOIN WmFootNote wmFoot ON plmain.PACKLISTNO = wmFoot.PACKLISTNO AND wmFoot.RowNum = 1 

				-- 10/25/2017 Satish B : Added join of wmNotes and wmNoteRelationship table to get Pl foot note and pl line note
				-- 11/01/2017 : Satish B : Comment the join of wmNotes and wmNoteRelationship table
				--LEFT OUTER JOIN wmNotes wmn on PLDETAIL.INV_LINK=wmn.RecordId -- Used to get line note
				--LEFT JOIN wmNoteRelationship wmNoteRel on wmNoteRel.FkNoteId=wmn.NoteID
				--LEFT OUTER JOIN wmNotes w on PLMAIN.PACKLISTNO=w.RecordId	-- Used to get PkFoot note
				--LEFT JOIN wmNoteRelationship wmNoteRelation on wmNoteRelation.FkNoteId=w.NoteID
				----- 01/27/16 YS move pkinvlot and pkalloc next to pldetail and invtmfgr and invtmfhd next to sodetail
				--left outer join PKALLOC on pldetail.PACKLISTNO = PKALLOC.PACKLISTNO and pldetail.UNIQUELN = PKALLOC.UNIQUELN
				--left outer join PKINVLOT on pkalloc.PACKLISTNO = pkalloc.PACKLISTNO and pkalloc.UNIQ_ALLOC = PKINVLOT.UNIQ_ALLOC
				--- 01/27/16 YS move pkinvlot and pkalloc next to pldetail and invtmfgr and invtmfhd next to sodetail
				--left outer join INVTMFGR on sodetail.W_KEY = invtmfgr.W_KEY
				--left outer join INVTMFHD on invtmfgr.UNIQMFGRHD = invtmfhd.UNIQMFGRHD
				
				Where	plmain.PACKLISTNO = @lcPackListNo
						--01/16/2017 Satish B - Does not display record with zero quantity in report 
						-- 11/15/19 VL found next line slow down, will add this critria at last select, comment out here
						--and pldetail.SHIPPEDQTY>0
						and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)	--08/10/16 DRP:  added with the /*CUSTOMER LIST*/

		-- 11/15/19 VL comment out the code, has changed to insert directly	 
		--	)
		 
		--INSERT @tResults
		--select * from PackList
		-- 11/15/19 VL End}

		-- 11/15/19 VL didn't update some fields in upper SQL statment and updte now to speed up
		--------------------------------------------------------------------------------------------------------------------------------
		UPDATE #tResults SET Partmfgr = M.PartMfgr, Mfgr_pt_no = M.mfgr_pt_no, MatlType = M.MatlType
			FROM #tResults t
			left outer join InvtMPNLink L ON t.UNIQMFGRHD=L.uniqmfgrhd
			LEFT OUTER JOIN MfgrMaster M On l.mfgrMasterId=m.MfgrMasterId

		-- 11/15/19 VL now will update two note fields from wmLineNote and WmFootNote
		;WITH WmLineNote AS(
			SELECT ROW_NUMBER() OVER (PARTITION BY PL.INV_LINK ORDER BY wmNoteRel.CreatedDate DESC) AS ROWNUM,PL.INV_LINK,wmNoteRel.Note Note
			FROM PLDETAIL PL 
				LEFT JOIN wmNotes wmn ON PL.INV_LINK=wmn.RecordId -- Used to get line note
				LEFT JOIN wmNoteRelationship wmNoteRel ON wmNoteRel.FkNoteId=wmn.NoteID
			WHERE PL.PACKLISTNO = @lcPackListNo
			-- 11/13/2017 : Satish B : Added the filter of wmNoteRelationship.ImagePath
			and wmNoteRel.ImagePath=''
		)
		UPDATE #tResults SET Note = wmLine.NOTE FROM WmLineNote wmLine WHERE [#tResults].INV_LINK = wmLine.INV_LINK AND wmLine.ROWNUM = 1

		-- 11/01/2017 : Satish B : Create cte to get foot note
		;WITH WmFootNote AS(
			SELECT ROW_NUMBER() OVER (PARTITION BY PM.PACKLISTNO ORDER BY wmNoteRelation.CreatedDate DESC) RowNum, PM.PACKLISTNO,Note 
			FROM PLMAIN PM 
				LEFT OUTER JOIN wmNotes w on PM.PACKLISTNO=w.RecordId	-- Used to get PkFoot note
				LEFT JOIN wmNoteRelationship wmNoteRelation on wmNoteRelation.FkNoteId=w.NoteID
			WHERE PM.PACKLISTNO  = @lcPackListNo
			-- 11/13/2017 : Satish B : Added the filter of wmNoteRelationship.ImagePath
			and wmNoteRelation.ImagePath=''
		) 
		
		UPDATE #tResults SET PKFOOTNOTE = wmFoot.Note FROM WmFootNote wmFoot WHERE [#tResults].PACKLISTNO = wmFoot.PACKLISTNO AND wmFoot.RowNum = 1 	
		
		-- 11/15/19 VL move the code from big SQL statment to here to speed up
		-- 06/8/2018 : Satish B : Select IpKey from #PLSid against each row
		UPDATE #tResults SET IpKey = CAST(stuff((select', '+ s.IpKey	from #PLSid s
													where	s.PACKLISTNO = [#tResults].PACKLISTNO
															AND s.UNIQUELN = [#tResults].UNIQUELN
													ORDER BY IpKey FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX)) 

		-- 11/15/19 VL update Serialno, only update if SN exists
		IF EXISTS(SELECT 1 FROM Packlser WHERE Packlistno = @lcPackListNo)
			UPDATE #tResults SET Serialno = CAST(stuff((select', '+ps.Serialno	from #FinalSerialno PS
													where UNIQUELN = PS.UNIQUELN 
													ORDER BY SERIALNO FOR XML PATH ('')),1,2,'') AS VARCHAR (MAX))

 		--------------------------------------------------------------------------------------------------------------------------------
		-- 11/15/19 VL End}




		Select * from #tResults T  cross apply  (SELECT D.PKINPGNMUK,T.PAGEDESC,T.PAGENO FROM  @tPageD D,@tPageDesc T  WHERE D.PKINPGNMUK = T.PKINPGNMUK) W
			-- 11/15/19 VL added Shippedqty> 0 criteria here
			WHERE ShippedQty > 0
			order by Pageno,sortby		--08/21/17 DRP:  added the order by
		-- 06/06/12 VL added 'PkPostDate' to save when the PK is posted, enhancement ticket #6674
		if(@isPreviewOnly=0)
		BEGIN
			UPDATE PLMAIN SET Printed = 1, IS_PKPRINT = 1, PkPostDate = GETDATE() WHERE PLMAIN.packlistno =@lcPackListNo    
		END

		-- 04/22/15 VL added to update PrevStat to save last batch
		INSERT INTO PrevStat (FIELDTYPE, FIELDKEY) VALUES ('PACKLIST', @lcPackListNo)

			--03/09/2012 DRP:  I originally had the below code setup incorrect to match off of the Invoiceno instead of PackListNO field.  So if the Invoice and Packing List numbering was setup to be different it would not update aspmnx_ActiveUsers posted. 
			--UPDATE PLMAIN SET Printed = 1, IS_PKPRINT = 1 WHERE PLMAIN.INVOICENO =@lcPackListNo    

		-- 01/10/18 VL added code to drop temp tables
		IF OBJECT_ID('tempdb..#PLSerial') IS NOT NULL
			DROP TABLE #PLSerial	
		IF OBJECT_ID('tempdb..#startingPoints') IS NOT NULL
			DROP TABLE #startingPoints	
		IF OBJECT_ID('tempdb..#EndingPoints') IS NOT NULL
			DROP TABLE #EndingPoints	
		IF OBJECT_ID('tempdb..#StartEndSerialno') IS NOT NULL
			DROP TABLE #StartEndSerialno	
		IF OBJECT_ID('tempdb..#FinalSerialno') IS NOT NULL
			DROP TABLE #FinalSerialno	
		-- 06/8/2018 : Satish B : Drop temp table #PLSid
		IF OBJECT_ID('tempdb..#PLSid') IS NOT NULL
			DROP TABLE #PLSid	
		-- 11/15/19 VL added #tResults	
		IF OBJECT_ID('tempdb..#tResults') IS NOT NULL
			DROP TABLE #tResults							
		end