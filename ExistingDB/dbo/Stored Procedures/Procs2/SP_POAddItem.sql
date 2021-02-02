

-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/15/2014
-- Description:	Procedure for import a new item to an existing PO
-- Modified:
-- 04/22/14 YS if not auto approve re-set approval names
-- 04/23/14 YS close cursor
-- 04/24/14 YS status and approval changes
-- 10/10/14 YS replace invtmfhd table with 2 new
-- 12/16/14 YS missing rollback
-- 12/17/14 ys CHANGE WHERE FOR THE change order variable
-- 04/14/15 YS Location length is changed to varchar(256)
-- 04/08/16 YS added code to populate NOTEASSIGN for the item if inventory record attached to the note
-- 06/06/16 YS added code for FC
-- 09/13/16 YS added code to populate pomain.ponote, poitems.note1, poitschd.req_date and poitschd.origcommitdt 
-- 01/11/17 VL added one more parameter for dbo.fn_Convert4FCHC()
-- 01/23/17 YS make sure the records for tax info is seleceted only once
-- 01/24/17 VL added functional currency code
-- 06/01/17 VL re-check functional currency code and made minor changes
-- 07/12/18 YS changed size of the column supname from 30 to 50
-- 06/27/19 VL we used to only add MRO requesttp for MRO item, but in desktop, user can added WO/PRJ for MRO item if the requesttp is 'WO/PRJ', so I added requesttp in template, if user does have wo/prj for requettp for MRO item, user can add it
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[SP_POAddItem] 
	@tAddPO tPoCreate READONLY,
	@desktopUserInitials char(8) = '',
	@ApproveINvtAmt	numeric(15,5)=0.00,
	@ApproveMroAmt numeric(15,5)=0.00,
	-- message from the calling program will ask if the user wants to increase CO when @lAssignNewCo=0
	-- will pass 1 if @lAssignNewCo=1, have to check later for individual PO what the current status to decide if the Co needs to be changed
	@IncreaseCO bit =1

As
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	
    -- Insert statements for procedure here
		--04/09/14 YS added autoapprove,@nSignatures code when uploaded from PO
		-- 04/18/14 YS added @poStatus and @conum
	DECLARE @lValid bit=1,@AutoAppr4UpLoad bit,@nSignatures int,
			@AutoPoNum bit ,@nReturnCode int=0,@lAssignNewCo bit,
			@nIncreaseCO int ,    ---- will assign 0 if no increase and 1 to increase by 1 
			@lNeed2Approve bit , --- will assign 1 if approval needed and 0 if not
			@APPRVVALUE int , --- read from podeflts if 1 - approval based on the original order value, 2- based on current balance
			@UniqSupno char(10),@ponum char(15)=' ',@oldPonum char(15),@PoStatus varchar(10),@coNum numeric(3,0),
			@CurrChange varchar(max),
			--06/06/16 YS added check if FC is installed
			@FcInstalled bit,
			--09/13/16 YS added ponote
			@ponote varchar(max)=''

			select @FcInstalled=dbo.fn_IsFCInstalled()
	
	--02/27/14 YS remove records from prior error log for the upload

	DELETE FROM importPoErrors

	-- variable to hold an error information

	DECLARE @ERRORNUMBER Int= 0
		,@ERRORSEVERITY int=0
		,@ERRORPROCEDURE varchar(max)=''
		,@ERRORLINE int =0
		,@ERRORMESSAGE varchar(max)=' '

	SELECT @AutoPoNum = Micssys.XxPoNoSys from MICSSYS
	--04/09/14 YS added autoapprove code when uploaded from PO
	select @AutoAppr4UpLoad=AutoAppr4UpLoad, 
		@nSignatures=PoDeflts.Signatures,
		@lAssignNewCo = podeflts.LASSIGNNEWCO,
		@APPRVVALUE = podeflts.APPRVVALUE
	FROM PoDeflts

	
	-- validate data

	DECLARE @tImport tPoCreate

	INSERT INTO @tImport SELECT * FROM @tAddPO

	--06/06/16 YS added new tax calculation based on the poitems is_tax and using new table poitemsTax
	declare @poitemsTax table (uniqpoitemstax char(10),ponum char(15),uniqlnno char(10),tax_id char(8),tax_rate numeric(8,4))


	
	--- mValidatePoItemValue
	SELECT DISTINCT PoitType 
		FROM @tImport
		WHERE PoitType NOT IN('MRO','INVT PART')

	IF @@ROWCOUNT > 0
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Item Type',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		-- 04/10/14 YS use GOTO LABEL to alter the execution
		GOTO RETURNCODE 
	END --IF @@ROWCOUNT > 0 item type validation
	-- replace all values that supposed to be UPPER case in manex with upper(values) .
	-- 09/13/16 YS replace note1, ponote with empty if null
	UPDATE @tImport SET Ponum=CASE WHEN POnum=' ' OR PONUM is null THEN space(15) 
						ELSE dbo.padl(UPPER(LTRIM(RTRIM(PONUM))),15,'0') END,
		Part_no = UPPER(RTRIM(Part_no)),
		Revision = RTRIM(Revision),
		PartMfgr = UPPER(RTRIM(PartMfgr)),
		Mfgr_pt_no = RTRIM(Mfgr_pt_no),
		Warehouse = UPPER(warehouse),
		Itemno = CASE WHEN Itemno<>' ' THEN dbo.PADL(RTRIM(Itemno),3,'0') ELSE ItemNo END,
		WoNumber = CASE WHEN WoNumber<>'' THEN UPPER(dbo.PADL(RTRIM(WoNumber),10,'0')) ELSE WoNumber END ,
		PrjNumber = CASE WHEN PrjNumber<>'' THEN dbo.PADL(RTRIM(PrjNumber),10,'0') ELSE PrjNumber END,
		Poittype = CASE WHEN UPPER(Poittype)='INVT PART' THEN 'Invt Part' ELSE 'MRO' END ,
		Package = UPPER(Package),
		-- 06/27/19 VL we used to only add MRO requesttp for MRO item, but in desktop, user can added WO/PRJ for MRO item if the requesttp is 'WO/PRJ', so I added requesttp in template, if user does have wo/prj for requettp for MRO item, user can add it
		--RequestTp = CASE WHEN Poittype='MRO' THEN 'MRO'
		--WHEN Poittype='Invt Part' AND WoNumber='' AND PrjNumber='' THEN 'Invt Recv'
		--WHEN Poittype='Invt Part' AND WoNumber<>' ' THEN 'WO Alloc'
		--WHEN Poittype='Invt Part' AND PrjNumber<>' ' THEN 'Prj Alloc' END,
		RequestTp = CASE  
		WHEN Poittype='Invt Part' AND WoNumber='' AND PrjNumber='' THEN 'Invt Recv'
		WHEN Poittype='Invt Part' AND WoNumber<>' ' THEN 'WO Alloc'
		WHEN Poittype='Invt Part' AND PrjNumber<>' ' THEN 'Prj Alloc'
		WHEN Poittype = 'MRO' AND WoNumber = '' AND PrjNumber = '' THEN 'MRO'
		WHEN Poittype = 'MRO' AND WoNumber <> '' THEN 'WO Alloc'
		WHEN Poittype = 'MRO' AND PrjNumber <> '' THEN 'Prj Alloc'
		ELSE Requesttp END,
		Ponote=ISNULL(Ponote,''),
		Note1=ISNULL(Note1,'')

	--- mValidateEmptyPo
	SELECT * 
		FROM @tImport 
	WHERE Ponum =' '
	IF @@ROWCOUNT <> 0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Missing Purchase Order Number(s).',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0

	END -- @@ROWCOUNT <> 0
	--- mValidateExistingPo
	SELECT Ponum
		FROM @tImport 
	WHERE Ponum NOT IN (SELECT Ponum FROM Pomain )

	IF @@ROWCOUNT <> 0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Cannot find some of the Purchase Order Number(s) in the existing records.',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		-- 04/10/14 YS use GOTO LABEL to alter the execution
		GOTO RETURNCODE 
	END --- IF @@ROWCOUNT <> 0	
	---- mValidateMatchSupplier
	-- 07/12/18 YS changed size of the column supname from 30 to 50
	SELECT t.Ponum,t.SupName,ISNULL(S.Supname,space(50)) as Supname ,ISNULL(p.Uniqsupno,space(10)) as Uniqsupno
		FROM @tImport t INNER JOIN Pomain P ON t.Ponum=P.Ponum
		LEFT OUTER JOIN Supinfo S ON P.UniqSupno=S.UniqSupno
		WHERE UPPER(RTRIM(S.Supname))<>UPPER(RTRIM(LTRIM(t.Supname))) OR t.Supname=' '
	
	IF @@ROWCOUNT <> 0
	BEGIN
		
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Supplier entered into the XL file doesn''t match to the supplier entered in the PO module.',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		
		set @lValid =0
	END --- IF @@ROWCOUNT <> 0	
	-- validate Work order
	SELECT DISTINCT WoNumber
		FROM @tImport
	WHERE woNumber<>' '
	AND WoNumber NOT In (SELECT Wono FROM WoEntry)
	IF @@ROWCOUNT>0
	BEGIN
		
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Work Order information',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0
	END -- IF @@ROWCOUNT>0
	-- validate project
	SELECT DISTINCT PrjNumber
		FROM @tImport
	WHERE PrjNumber<>' ' 
	AND PrjNumber NOT In (SELECT PrjNumber FROM PjctMain)
	IF @@ROWCOUNT>0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Project information',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0
	END -- @@ROWCOUNT>0

	-- validate package
	-- update with empty value if not in the system setup, will be populated from the default values later
	UPDATE @tImport set Package ='' WHERE Package NOT IN (SELECT left(text,10) FROM SUpport where Fieldname = 'PART_PKG');


	-- validate warehous
	SELECT * 
		FROM @tImport
		WHERE Poittype='Invt Part' 
		AND Warehouse NOT IN (SELECT Warehouse FROM warehous WHERE warehouse<>'WIP' AND warehouse<>'WO-WIP' AND warehouse<>'MRB');

	IF @@ROWCOUNT>0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid warehouse information',1)
		
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0
	END  --- @@ROWCOUNT>0
	ELSE
	BEGIN
		UPDATE @tImport SET UniqWH=Warehous.UniqWH,GL_NBR=Warehous.Wh_gl_nbr FROM Warehous INNER JOIN @tImport t ON Warehous.warehouse=t.Warehouse WHERE t.Poittype<>'MRO'
	END ---- @@ROWCOUNT>0
	
	--- mValidatePartRev
	-- validate part number/revision
	SELECT ponum,itemno,PoitType
		FROM @tImport
	WHERE part_no=' ' AND PoitType='Invt Part'
	UNION
	SELECT ponum,itemno,PoitType
		FROM @tImport
	WHERE part_no=' ' AND Descript=' ' AND PoitType<>'Invt Part' ;
	IF @@ROWCOUNT>0
	BEGIN
		
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Some records do not have any Part No entered.',1)
		set @lValid = 0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END

	END   -- @@ROWCOUNT>0
	ELSE
	BEGIN
		--for not inventory parts if part_no is empty copy it from the descript
		UPDATE @tImport SET Part_no=Descript WHERE part_no=' ' AND PoitType<>'Invt Part'
	END  -- @@ROWCOUNT>0
	
	--check for the active parts
	SELECT *
		FROM @tImport t
	WHERE RTRIM(t.poittype)='Invt Part'
	--06/06/16 YS change the SQL 
	--AND Part_no+Revision NOT in
	and not exists 
		(SELECT 1 FROM inventor WHERE inventor.part_no=t.part_no and inventor.revision = t.REVISION 
		AND	(inventor.part_sourc = 'BUY'
		OR (part_sourc='MAKE' AND Make_buy=1)) AND Inventor.Status='Active')
	IF @@ROWCOUNT>0
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Some part Numbers entered are not part of the Inventory records or are not active.',1)
		set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
	END   -- @@ROWCOUNT>0
	-- check if GL installed
	IF (SELECT Installed from ITEMS where ScreenName = 'GLREL')=1
	BEGIN
		-- check gl_nbrs for mro items
		SELECT *
			FROM @tImport t
		WHERE poittype='MRO' AND
		(gl_nbr=' ' OR RTRIM(gl_nbr)
		NOT in (SELECT gl_nbr FROM invtgls WHERE invtgls.rec_type=('M') ));
	END
	IF @@ROWCOUNT>0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid GL # for MRO parts.',1)
		set @lValid =0
	
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
			WHEN @nReturnCode=3 THEN 5
			ELSE 2 END
	END --  @@ROWCOUNT>0
	--- mRenumberItemNumbers
	;
	WITH
	PoItMaxNum
	as
	(
	SELECT MAX(CAST(ItemNo as int)) as maxNum,Ponum 
	from POITEMS 
	WHERE EXISTS (SELECT 1 from @tImport t WHERE t.ponum=POitems.Ponum)
	GROUP BY Ponum  
	 ),
	tItems
	AS
	(
	 select distinct ponum,itemno
	 from @tImport
	 ),
	 newItemNum
	 as
	 (
	 SELECT t.Ponum, t.itemno, ROW_NUMBER () OVER (Partition by t.ponum order by t.itemno) +M.maxNum as nItemno
	  from tItems t  inner join PoItMaxNum M on t.ponum=M.ponum 
	 )
	  UPDATE @tImport SET t.itemno=dbo.padl(RTRIM(convert(varchar(5),n.nitemno)),3,'0')
			FROM @tImport t INNER JOIN newItemNum N ON t.ponum=n.ponum and t.itemno=N.itemno
		
	-- mValidateEmpty
	IF EXISTS
		(SELECT Ponum,ItemNo,Part_no,Revision,Poittype,requestor,partmfgr,Schd_date,Schd_qty
				FROM @tImport
				WHERE itemno=' ' OR poittype=' '
					OR (PoitType='MRO' AND REQUESTOR=' ')
					OR (PoitType<>'MRO' AND partmfgr=' ')
					OR schd_date IS null OR schd_qty=0.00 )

	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('One or number of required fields are empty.',1)
		set @lValid =0
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
						WHEN @nReturnCode=3 THEN 5
						ELSE 2 END
	END  -- EXISTS	(SELECT Ponum....	

	-- mUpdateSchdDates
	-- update schedule dates
	--09/13/16 YS added reqdate and ORIGCOMMITDT date to the template. Populate only if template columns were empty
	--UPDATE @tImport SET req_date=schd_date,origcommitdt=schd_date
	UPDATE @tImport SET req_date=ISNULL(req_date,schd_date),origcommitdt=isnull(ORIGCOMMITDT,schd_date)
	-- populate information from Inventor table
	-- 06/06/16 YS update taxable from inventor
	UPDATE @tImport SET t.uniq_key=i.uniq_key,
				t.PUR_UOFM=i.PUR_UOFM,
				t.U_OF_MEAS=i.U_OF_MEAS,
				t.Package = CASE WHEN t.Package=' ' THEN i.Package ELSE t.Package END,
				t.firstarticle=i.firstarticle,
				t.is_tax=i.Taxable
		FROM inventor i inner join @tImport t on i.PART_NO=t.part_no and i.REVISION =t.revision
		WHERE t.poittype='Invt Part' AND i.part_sourc <> 'CONSG'


    --- 06/06/16 YS get i_link add from pomain and find tax information
	-- 06/01/17 VL added to update PRFcused_uniq and FuncFcused_uniq, will be used later to update functional and presentation currency values
	update @tImport set t.I_link=Res.i_link,
			t.uniqsupno= res.uniqsupno,
			fcused_uniq = res.fcused_uniq ,
			t.UseDefaultTax = res.UseDefaultTax, 
			--- this tax id defaulted and saved in the supinfo table
			t.defaultTaxid = res.tax_id,
			fchist_key = case when @FcInstalled=1 THEN res.Fchist_key else '' end,
			t.PRFcused_uniq = res.PRFcused_uniq, 
			t.FuncFcused_uniq = res.FuncFcused_uniq
			from @tImport t INNER JOIN 
			(select p.ponum,p.uniqsupno,s.tax_id,i.UseDefaultTax,p.Fchist_key,p.I_LINK,p.FcUsed_uniq, p.PRFcused_uniq, p.FuncFcused_uniq 
				from Pomain P inner join Supinfo S on p.UNIQSUPNO=s.UNIQSUPNO
				inner join shipbill I on p.I_LINK=I.LINKADD ) as res on t.ponum=res.ponum


			
	
	
--	@cType: Conversion FC to Home (F), Home to FC (H)
--	@cFcused_uniq: Foreign currency fcused_uniq
--	@nAmt home: currency amount to be converted
--	@cFCHist_Key: the FCHist_key

-- 06/01/17 VL changed 4th parameter from dbo.fn_GetFunctionalCurrency() to FuncFcused_uniq
	update @timport set costEach=CASE WHEN @FcInstalled=1 then dbo.fn_Convert4FCHC('F',fcused_uniq,costEachfc,FuncFcused_uniq,Fchist_key) else costeach end,
		SHIPCHG = case when @FcInstalled=1 then  dbo.fn_Convert4FCHC('F',fcused_uniq,SHIPCHGfc,FuncFcused_uniq,Fchist_key) else SHIPCHG end,
		-- 01/24/17 VL added functional currency code
		costEachPR=CASE WHEN @FcInstalled=1 then dbo.fn_Convert4FCHC('F',fcused_uniq,costEachfc,PRFcused_uniq,Fchist_key) else costeachPR end,
		SHIPCHGPR = case when @FcInstalled=1 then  dbo.fn_Convert4FCHC('F',fcused_uniq,SHIPCHGfc,PRFcused_uniq,Fchist_key) else SHIPCHGPR end
	
	
	-- validate MPN
	--10/10/14 YS replace invtmfhd table with 2 new tables
	--SELECT * FROM @tImport t
	--	WHERE poittype<>'MRO'
	--	AND partmfgr + mfgr_pt_no NOT IN
	--(SELECT partmfgr+mfgr_pt_no FROM invtmfhd WHERE invtmfhd.uniq_key = t.uniq_key AND Invtmfhd.is_deleted=0);

	--IF @@ROWCOUNT>0
	IF EXISTS(SELECT 1 FROM @tImport t
		WHERE poittype<>'MRO'
		AND NOT EXISTS (SELECT 1 FROM Invtmpnlink L INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
						  WHERE l.uniq_key = t.uniq_key 
						  AND M.PartMfgr=t.PARTMFGR
						  and m.mfgr_pt_no=t.MFGR_PT_NO
						  AND l.is_deleted=0 and m.IS_DELETED=0))
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid MPN.',1)
		set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
					WHEN @nReturnCode=3 THEN 5
					ELSE 2 END
	END   ---  @@ROWCOUNT>0
	ELSE
	BEGIN
	--10/10/14 YS replace invtmfhd table with 2 new tables
		--SELECT * 
		--	FROM @tImport t
		--WHERE poittype<>'MRO'
		--AND partmfgr + mfgr_pt_no IN
		--	(SELECT partmfgr+mfgr_pt_no FROM invtmfhd WHERE invtmfhd.uniq_key = t.uniq_key AND Invtmfhd.lDisallowbuy=1);
		--IF @@ROWCOUNT>0

		IF EXISTS(SELECT 1 
				FROM @tImport t INNER JOIN Invtmpnlink L ON t.Uniq_key=L.Uniq_key
				INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
				AND M.PartMfgr=t.PARTMFGR
				and m.mfgr_pt_no=t.MFGR_PT_NO
				WHERE poittype<>'MRO' AND m.lDisallowbuy=1)
		BEGIN
			INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Some MPNs are on the ''Disallow for Purchasing'' list.',1)
			set @lValid =0
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		END --  @@ROWCOUNT>0
	END ---  @@ROWCOUNT>0
	if (@lValid=1)
	BEGIN
	-- populate data from Invtmfhd
	--10/10/14 YS replace invtmfhd table with 2 new tables
		--UPDATE @tImport SET t.uniqmfgrhd=invtmfhd.uniqmfgrhd,
		--				t.Mfgr_pt_no=Invtmfhd.Mfgr_pt_no
		--	FROM invtmfhd inner join @tImport t ON
		--		invtmfhd.uniq_key=t.Uniq_key
		--		AND Invtmfhd.PartMfgr=t.PartMfgr
		--		AND Invtmfhd.Mfgr_pt_no=t.Mfgr_pt_no
		UPDATE @tImport SET t.uniqmfgrhd=L.uniqmfgrhd,
						t.Mfgr_pt_no=M.Mfgr_pt_no
			FROM invtmpnlink L INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
			 inner join @tImport t ON
				L.uniq_key=t.Uniq_key
				AND M.PartMfgr=t.PartMfgr
				AND M.Mfgr_pt_no=t.Mfgr_pt_no
		-- validate location
		;with notauto
		as 
		(
			SELECT ZImportPO.Ponum,ZImportPO.Part_no,ZImportPO.Revision,ZImportPO.uniqmfgrhd,ZImportPO.warehouse,ZImportPO.location,ZImportPO.uniqwh,
			ZImportPO.partmfgr,ZImportPO.mfgr_pt_no,Warehous.autolocation,ZImportPO.Uniq_key
			FROM @tImport as ZImportPO INNER JOIN Warehous ON zimportpo.uniqwh=warehous.uniqwh
			WHERE Warehous.autolocation=0
			AND Poittype<>'MRO'
			UNION
			SELECT ZImportPO.Ponum,ZImportPO.Part_no,ZImportPO.Revision,ZImportPO.uniqmfgrhd,ZImportPO.warehouse,ZImportPO.location,ZImportPO.uniqwh,
			ZImportPO.partmfgr,ZImportPO.mfgr_pt_no,M.autolocation,ZImportPO.Uniq_key
				--10/10/14 YS replace invtmfhd table with 2 new tables
				--FROM @tImport as ZimportPO INNER JOIN Invtmfhd ON Invtmfhd.Uniqmfgrhd=ZimportPo.Uniqmfgrhd
				FROM @tImport as ZimportPO INNER JOIN InvtMPNLink L ON L.Uniqmfgrhd=ZimportPo.Uniqmfgrhd
				INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
			WHERE M.autolocation=0
			AND Poittype<>'MRO'
		)
		--for those parts that cannot create a new location at receiving check if location exists in the Invtmfgr
		SELECT notauto.*
		FROM notauto
		where Uniqmfgrhd+uniqwh+location
		NOT IN (SELECT Uniqmfgrhd+uniqwh+location FROM invtmfgr WHERE invtmfgr.uniq_key=notauto.Uniq_key)
		IF @@ROWCOUNT>0
		BEGIN
			INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Missing Wh/Location in Manex.',1)
			set @lValid =0
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
				WHEN @nReturnCode=3 THEN 5
				ELSE 2 END
		END  -- @@ROWCOUNT>0
	END -- (@lValid=1)	--- 04/14/14 YS moved end to the bottom to avoid errors when validation is failed prior to mpn and wh/loc
	if (@lValid=0)
	--02/27/14 YS return the code
	BEGIN
		--RAISERROR ('Data validation failed. Cannot continue with upload'
		-- ,16 -- Severity.
		-- ,1 -- State
		-- )
		-- 04/10/14 YS use GOTO LABEL to alter the execution
		GOTO RETURNCODE 
		--RETURN @nReturnCode
	END -- if (@lValid=0)
	--if valid continue
	--- mPoItemsDistribute
	IF EXISTS (SELECT Ponum,Itemno,COUNT(DISTINCT uniq_key+Part_no+revision)
		FROM @tImport GROUP BY Ponum,Itemno HAVING COUNT(DISTINCT uniq_key+Part_no+revision)>1)
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Some PO Numbers have duplicate item numbers for the different items.',1)
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
						ELSE 2 END
		--RETURN @nReturnCode
		-- 04/10/14 YS use GOTO LABEL to alter the execution
		GOTO RETURNCODE 

	END -- IF EXISTS (SELECT Ponum,COUNT(DISTINCT itemno)

	--04/27/16 YS added is_tax 
	-- 01/24/17 VL added functional currency code and FC code
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	DECLARE @PoItemsUnique Table (Ponum char(15),part_no char(35),revision char(8),costeach numeric(13,5),itemno char(3),uniqlnno char(10),is_tax bit, costeachFC numeric(13,5), costeachPR numeric(13,5))
	INSERT INTO @PoItemsUnique (Ponum,part_no,revision,costeach,Itemno,is_tax,costeachFC,costeachPR)
		SELECT Distinct Ponum,part_no,revision,costeach,Itemno,is_tax,costeachFC, costeachPR
		FROM @tImport


	
	UPDATE @PoItemsUnique SET UniqLnno = dbo.fn_GenerateUniqueNumber()
	UPDATE @tImport SET t.Uniqlnno=i.uniqlnno from @PoItemsUnique I inner join @tImport t on I.Ponum=t.Ponum AND I.Itemno=t.Itemno
	
	--06/06/16 YS added tax table
	--01/23/17 YS make sure the records seleceted only once
	;with poitemstaxinfo
	as
	(
	select DISTINCT poi.ponum,poi.uniqlnno,	st.tax_id,st.Tax_rate 
	--- check default tax for the default receiving location 
	from @PoItemsUnique POI inner join @tImport t on poi.ponum=t.ponum
	inner join shiptax ST on t.I_LINK=st.LINKADD and 
	((t.defaultTaxid<>' ' and t.defaultTaxid=st.tax_id) OR (t.defaultTaxid=' ' and t.UseDefaultTax=1 and st.DEFAULTTAX=1))
	where poi.is_tax=1
	--- insert all the taxes for the location if UseDefaultTax=0
	UNION
	select DISTINCT poi.ponum,poi.uniqlnno,	st.tax_id,st.Tax_rate 
		--- check default tax for the default receiving location 
		from @PoItemsUnique POI inner join @tImport t on poi.ponum=t.ponum and t.UseDefaultTax=0 
		inner join shiptax ST on t.I_LINK=st.LINKADD 
		where poi.is_tax=1
	)
	insert into @poitemsTax (uniqpoitemstax,ponum,uniqlnno,tax_id,tax_rate)
	select dbo.fn_GenerateUniqueNumber(),ponum,uniqlnno,tax_id,tax_rate from poitemstaxinfo

	--insert into @poitemsTax (uniqpoitemstax,ponum,uniqlnno,tax_id,tax_rate)
	--	select dbo.fn_GenerateUniqueNumber(),poi.ponum,poi.uniqlnno,
	--st.tax_id,st.Tax_rate 
	----- check default tax for the default receiving location 
	--from @PoItemsUnique POI inner join @tImport t on poi.ponum=t.ponum
	--inner join shiptax ST on t.I_LINK=st.LINKADD and 
	--((t.defaultTaxid<>' ' and t.defaultTaxid=st.tax_id) OR (t.defaultTaxid=' ' and t.UseDefaultTax=1 and st.DEFAULTTAX=1))
	--where poi.is_tax=1
	----- insert all the taxes for the location if UseDefaultTax=0
	--UNION
	--select dbo.fn_GenerateUniqueNumber(),poi.ponum,poi.uniqlnno,
	--	st.tax_id,st.Tax_rate 
	--	--- check default tax for the default receiving location 
	--	from @PoItemsUnique POI inner join @tImport t on poi.ponum=t.ponum and t.UseDefaultTax=0 
	--	inner join shiptax ST on t.I_LINK=st.LINKADD 
	--	where poi.is_tax=1
---- !! remove after debug
--select * from @poitemsTax

	-- Calculate Ord_qty,balance

	UPDATE @tImport SET t.Ord_qty=SumOrder.Qty_sum ,
					t.Balance=SumOrder.Qty_sum,
					t.s_ord_qty=dbo.fn_ConverQtyUOM(t.PUR_UOFM,t.U_of_meas,SumOrder.Qty_sum)
		FROM (SELECT Ponum,UniqLnno,SUM(schd_qty) as Qty_sum from @tImport GROUP BY Ponum,Uniqlnno) SumOrder INNER JOIN @tImport t on
				SumOrder.Ponum=t.Ponum and SumOrder.UniqLnno=t.Uniqlnno

	-- mSaveUploadedAddItems
	-- 04/14/15 YS Location length is changed to varchar(256)
	DECLARE @poitschd TABLE (UNIQLNNO char(10),UniqDetno char(10),SCHD_DATE smalldatetime,REQ_DATE smalldatetime,
			Schd_qty numeric(10,2),RecdQty numeric(10,2), BALANCE numeric(10,2),
			GL_NBR char(13),REQUESTTP char(10),REQUESTOR char(40), UNIQWH char(10),LOCATION varchar(256),
			WOPRJNUMBER char(10), COMPLETEDT smalldatetime,PONUM char(15),ORIGCOMMITDT smalldatetime)

	INSERT INTO @poitschd
		SELECT UNIQLNNO,SPACE(10) as UniqDetno,SCHD_DATE,REQ_DATE,SUM(SCHD_QTY) as Schd_qty,SUM(RECDQTY) as RecdQty,SUM(SCHD_QTY) as BALANCE,
		GL_NBR,REQUESTTP,REQUESTOR, UNIQWH,LOCATION,
		-- 06/27/19 VL changed to allow enter woprjnumber even for MRO item if use does select requesttp = 'WO Alloc' or 'Prj Alloc'
		--CASE WHEN Poittype='Invt Part' AND WONumber<>' ' THEN WONumber
		--WHEN Poittype='Invt Part' AND PrjNumber<>' ' THEN PrjNumber ELSE SPACE(10) END AS WOPRJNUMBER,
		CASE WHEN Poittype='Invt Part' AND WONumber<>' ' THEN WONumber
		WHEN Poittype='Invt Part' AND PrjNumber<>' ' THEN PrjNumber 
		WHEN Requesttp = 'WO Alloc' AND WoNumber<>' ' THEN WoNumber
		WHEN Requesttp = 'Prj Alloc' AND PrjNumber<>' ' THEN PrjNumber
		ELSE SPACE(10) END AS WOPRJNUMBER,
		COMPLETEDT,PONUM,ORIGCOMMITDT
	FROM @tImport
		GROUP BY UNIQLNNO,SCHD_DATE,REQ_DATE,GL_NBR,REQUESTTP,REQUESTOR, UNIQWH,LOCATION,Poittype,WONumber,PrjNumber,COMPLETEDT,PONUM,ORIGCOMMITDT


	UPDATE @poitschd SET UniqDetno=dbo.fn_GenerateUniqueNumber()
	
	
	


	--06/06/16 ys added fc columns
	--- 09/13/16 YS added Note1 (item note) to the template
	-- 01/24/17 VL added functional currency code
	-- 06/01/17 VL changed the CosteachFC from numeric(15,7) to numeric(13,5)
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	DECLARE @PoItems TABLE (PONUM char(15),UNIQLNNO char(10),UNIQ_KEY char(10),ITEMNO char(3),COSTEACH numeric(13,5),
			ORD_QTY numeric(10,2),IS_TAX bit,OVERAGE numeric(5,2),POITTYPE char(9),
			L_PRINT bit,NO_PKG numeric(9,2), Part_no char(35),Revision char(8),Descript char(45),
			PARTMFGR char(8),MFGR_PT_NO char(30),PACKAGE char(15),
			Part_class char(8), Part_type char(8), U_OF_MEAS char(4),PUR_UOFM char(4),
			S_ORD_QTY numeric(10,2),ISFIRM bit,UNIQMFGRHD char(10),FIRSTARTICLE bit,INSPEXCEPT bit,
			INSPEXCEPTION char(20),INSPEXCINIT char(8), INSPEXCDT smalldatetime,INSPEXCDOC varchar(20),LCANCEL bit, uniqmfsp char(10) ,
			costeachfc numeric(13,5),
			note1 varchar(max)  default '',
			COSTEACHPR numeric(13,5) )
--09/13/16 YS list all the columns in the insert
	-- 01/24/17 VL added functional currency code
	INSERT INTO @PoItems 
	(PONUM,UNIQLNNO,UNIQ_KEY,ITEMNO,COSTEACH,ORD_QTY,IS_TAX,
		OVERAGE,POITTYPE,L_PRINT,NO_PKG,
		 Part_no ,Revision ,Descript,
		 PARTMFGR,MFGR_PT_NO,PACKAGE,
		 Part_class , Part_type ,
		 U_OF_MEAS,PUR_UOFM,
		S_ORD_QTY,ISFIRM,UNIQMFGRHD,FIRSTARTICLE,INSPEXCEPT,INSPEXCEPTION,INSPEXCINIT,
		INSPEXCDT,INSPEXCDOC,LCANCEL,UniqMfsp,costeachfc, COSTEACHPR)
	SELECT DISTINCT PONUM,UNIQLNNO,UNIQ_KEY,ITEMNO,COSTEACH,ORD_QTY,IS_TAX,
		OVERAGE,POITTYPE,L_PRINT,NO_PKG,
		CASE WHEN Poittype='Invt Part' THEN ' ' ELSE PART_NO END,
		CASE WHEN Poittype='Invt Part' THEN ' ' ELSE REVISION END,
		CASE WHEN Poittype='Invt Part' THEN ' ' ELSE DESCRIPT END ,
		PARTMFGR,MFGR_PT_NO,PACKAGE,
		CASE WHEN Poittype='Invt Part' THEN ' ' ELSE PART_CLASS END ,
		CASE WHEN Poittype='Invt Part' THEN ' ' ELSE PART_TYPE END,
		U_OF_MEAS,PUR_UOFM,
		S_ORD_QTY,ISFIRM,UNIQMFGRHD,FIRSTARTICLE,INSPEXCEPT,INSPEXCEPTION,INSPEXCINIT,
		INSPEXCDT,INSPEXCDOC,LCANCEL,UniqMfsp,costeachfc,costeachPR
	FROM @tImport
	BEGIN TRANSACTION
	BEGIN TRY
	--06/06/16 YS insert into poitems changed , added fc
	-- 09/13/16 ys added note1
	-- 01/24/17 VL added functional currency code
		INSERT INTO POITEMS (PONUM,UNIQLNNO,UNIQ_KEY,ITEMNO,COSTEACH,ORD_QTY,IS_TAX,
				OVERAGE,POITTYPE,L_PRINT,NO_PKG,
				PART_NO,REVISION ,DESCRIPT ,
				PARTMFGR,MFGR_PT_NO,PACKAGE,
				PART_CLASS ,PART_TYPE,U_OF_MEAS,PUR_UOFM,
				S_ORD_QTY,ISFIRM,UNIQMFGRHD,FIRSTARTICLE,INSPEXCEPT,INSPEXCEPTION,INSPEXCINIT,
				INSPEXCDT,INSPEXCDOC,LCANCEL,UniqMfsp,costeachfc ,note1,costeachPR)
		SELECT PONUM,UNIQLNNO,UNIQ_KEY,ITEMNO,COSTEACH,ORD_QTY,IS_TAX,
			OVERAGE,POITTYPE,L_PRINT,NO_PKG,
			PART_NO,REVISION ,DESCRIPT ,
			PARTMFGR,MFGR_PT_NO,PACKAGE,
			PART_CLASS ,PART_TYPE,U_OF_MEAS,PUR_UOFM,
			S_ORD_QTY,ISFIRM,UNIQMFGRHD,FIRSTARTICLE,INSPEXCEPT,INSPEXCEPTION,INSPEXCINIT,
			INSPEXCDT,INSPEXCDOC,LCANCEL,UniqMfsp,costeachfc,note1,costeachPR
		FROM @poitems
		--09/13/16 YS update note1 after inserting. Cannot use as part of the insert because varchar(max) cannot be selected as part of the distinct
		update @PoItems set note1=isnull(t.note1,'') from @timport t inner join @poitems p on t.uniqlnno=p.UNIQLNNO where t.note1<>'' and t.note1 is not null

	END TRY
	BEGIN CATCH
		SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION
		INSERT INTO importPoErrors (ErrorMessage)
				VALUES 
		('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
		'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
		'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
		'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
		'Error Message: '+@ERRORMESSAGE)
		return -1
	END CATCH
	BEGIN TRY
	
	---04/08/16 YS added code to populate NOTEASSIGN for the item if inventory record attached to the note
	INSERT INTO NoteAssign (FKNOTEUNIQUE,TABLENAME,TABLEUNIQUE,ASSIGNUNIQUE,cAssignId)
		SELECT n.FkNoteUnique,'POITEMS' as TableName,p.Uniqlnno as TableUnique,dbo.fn_GenerateUniqueNumber() as AssignUnique,@desktopUserInitials as cAssignId
		FROM @PoItems P inner join NoteAssign N on p.UNIQ_KEY=n.TableUnique and n.TABLENAME='INVENTOR'

	end try
	BEGIN CATCH
		SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
		IF @@TRANCOUNT>0
		ROLLBACK TRANSACTION
			INSERT INTO importPoErrors (ErrorMessage)
			VALUES ('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
			'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
			'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
			'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
			'Error Message: '+@ERRORMESSAGE)
		return -1
	END CATCH
	BEGIN TRY
		INSERT INTO Poitschd 
		(
			UNIQLNNO,
			UniqDetno,
			SCHD_DATE,
			REQ_DATE,
			Schd_qty,
			RecdQty, 
			BALANCE,
			GL_NBR,
			REQUESTTP,
			REQUESTOR,
			UNIQWH,
			LOCATION,
			WOPRJNUMBER,
			COMPLETEDT,
			PONUM,
			ORIGCOMMITDT
		)
		SELECT UNIQLNNO,
			UniqDetno,
			SCHD_DATE,
			REQ_DATE,
			Schd_qty,
			RecdQty, 
			BALANCE,
			GL_NBR,
			REQUESTTP,
			REQUESTOR,
			UNIQWH,
			LOCATION,
			WOPRJNUMBER,
			COMPLETEDT,
			PONUM,
			ORIGCOMMITDT
		FROM @poitschd 
	END TRY
	BEGIN CATCH
		SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION

		INSERT INTO importPoErrors (ErrorMessage)
				VALUES 
		('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
		'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
		'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
		'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
		'Error Message: '+@ERRORMESSAGE)
		return -1

	END CATCH

	-- 04/27/16 YS added poitemstax
	BEGIN TRY
		INSERT INTO poitemstax (UNIQPOITEMSTAX,UNIQLNNO,Ponum,tax_id,Tax_rate)
			SELECT UNIQPOITEMSTAX,UNIQLNNO,Ponum,tax_id,Tax_rate
			FROM @poitemsTax
	END TRY
	BEGIN CATCH
		SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
		IF @@TRANCOUNT>0
		ROLLBACK TRANSACTION
			INSERT INTO importPoErrors (ErrorMessage)
			VALUES ('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
			'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
			'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
			'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
			'Error Message: '+@ERRORMESSAGE)
		return -1
	END CATCH

	BEGIN TRY
		DECLARE cPoNum CURSOR FORWARD_ONLY FOR
			SELECT Distinct t.PoNum,Pomain.Postatus,Pomain.Conum
				FROM @tImport t inner join Pomain on t.ponum=pomain.ponum
			OPEN cPonum
			FETCH cPoNum INTO @ponum,@postatus,@coNum
			WHILE (@@fetch_status = 0)
			BEGIN
			--09/13/16 YS get new ponote if entered
				SELECT @ponote = f.ponote from (select 1 ponote from @tImport where ponum=@ponum) f
			-- check if rolling the change order automatically
				select @nIncreaseCo = 
					CASE WHEN @lAssignNewCo=0 and @IncreaseCO=1 and @postatus<>'NEW' and @postatus<>'PENDING' THEN 1
					WHEN @lAssignNewCo=0 and @IncreaseCO=0 and @postatus<>'NEW' and @postatus<>'PENDING' THEN 0
					WHEN @lAssignNewCo=0 or @postatus='NEW' or @postatus='PENDING' Then 0
					WHEN @POSTATUS='OPEN' OR @postatus='CANCEL' THEN 1 ELSE 1 END
				
				-- check if need approval
				select @lNeed2Approve =
				CASE WHEN @AutoAppr4UpLoad = 0 THEN 0
					 WHEN @postatus='NEW' or @postatus='PENDING' or @postatus='EDITING' Then 0	
					 ELSE 1 END		
				 
				-- if approval is required check the amount allowed to approved vs amount on the PO
				If (@lNeed2Approve = 1)
				BEGIN	
					SELECT Ponum,Poittype, CASE WHEN @APPRVVALUE=1 THEN SUM(CostEach*Ord_qty) ELSE SUM(CostEach*(poitems.Ord_qty-poitems.ACPT_QTY)) END AS Amt
						FROM PoItems
					WHERE Poittype<>'MRO'
					and Poitems.ponum=@ponum
					GROUP BY Ponum,PoitType
					HAVING CASE WHEN @APPRVVALUE=1 THEN SUM(CostEach*Ord_qty) ELSE SUM(CostEach*(poitems.Ord_qty-poitems.ACPT_QTY)) END>@ApproveINvtAmt 
					UNION 
					SELECT Ponum,Poittype,CASE WHEN @APPRVVALUE=1 THEN SUM(CostEach*Ord_qty) ELSE SUM(CostEach*(poitems.Ord_qty-poitems.ACPT_QTY)) END AS Amt
					FROM PoItems
					WHERE Poittype='MRO'
					and Poitems.ponum=@ponum
					GROUP BY PONUM,PoitType
					HAVING CASE WHEN @APPRVVALUE=1 THEN SUM(CostEach*Ord_qty) ELSE SUM(CostEach*(poitems.Ord_qty-poitems.ACPT_QTY)) END>@ApproveMroAmt  
				
					IF @@ROWCOUNT <>0
					BEGIN
						--12/16/14 YS missing rollback
						IF @@TRANCOUNT>0
						ROLLBACK TRANSACTION
						
						INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Add Item Upload: The total of PO # '+@ponum+' exceeds your approval limit.',1)
						set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
								WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
						GOTO RETURNCODE 
					END -- IF @@ROWCOUNT <>0
				END  -- (@lNeed2Approve = 1) 
				--- update POmain 
				--04/22/14 YS if not auto approve re-set approval names
				--04/24/14 YS work on status and approval name here the logic
				--1. Auto Approve On 
				--   Original Status = 'OPEN' or 'CLOSED' or 'CANCEL' - New status ='OPEN', both  approval names entered
				--   Original Status = 'NEW' or 'PENDING' or 'EDITING' - New Status is 'NEW', 'NEW' , 'EDITING' correspondingly, both approval names cleared. 
				--   Even if auto approve but the po was in 'EDITING' prior to adding new items and was  not approve, has to be manually approve
				--2. Auto Approve Off
				--   Original Status = 'OPEN' or 'CLOSED' or 'CANCEL' - New status ='EDITING', both approval names cleared
				--   Original Status = 'NEW' or 'PENDING' or 'EDITING' - New Status is 'NEW', 'NEW' , 'EDITING' correspondingly, both approval names cleared .  
				--09/13/16 YS update ponote if provided
				-- 01/24/17 VL added functional currency code
				-- 06/01/17 VL comment out PoTax update part because later will have separate code to update Potax from PoitemsTax and also need to consider ShipChg
				UPDATE Pomain SET 
					POmain.VERINIT = @desktopUserInitials ,
					Pomain.PoTotal = PI.POTotal +Pomain.ShipChg,
					-- 06/01/17 VL comment out PoTax part
					--Pomain.PoTax = PI.TaxTotal+CASE WHEN Pomain.ShipChg=0 OR POmain.ScTaxPct=0 THEN 0 ELSE ROUND((POmain.ShipChg * POmain.ScTaxPct)/100,2) END,
					Pomain.FinalName = CASE WHEN POSTATUS='NEW' OR POSTATUS='PENDING' OR POSTATUS='EDITING' THEN ' '
											WHEN @lNeed2Approve=1 AND (POSTATUS = 'OPEN' OR Pomain.PoStatus='CLOSED' OR Pomain.PoStatus='CANCEL') THEN @desktopUserInitials 
											ELSE ' ' END,
					Pomain.AppvName = CASE WHEN POSTATUS='NEW' OR POSTATUS='PENDING' OR POSTATUS='EDITING' THEN ' '
											WHEN @lNeed2Approve=1 AND (POSTATUS = 'OPEN' OR Pomain.PoStatus='CLOSED' OR Pomain.PoStatus='CANCEL') THEN @desktopUserInitials 
											ELSE ' ' END,
					Pomain.Postatus = CASE WHEN @lNeed2Approve=1 AND (Pomain.PoStatus='OPEN' OR Pomain.PoStatus='CLOSED' OR Pomain.PoStatus='CANCEL') THEN 'OPEN' 
											WHEN Pomain.POSTATUS = 'NEW' OR POSTATUS='PENDING' THEN 'NEW' 
											WHEN POSTATUS='EDITING' THEN 'EDITING'
											WHEN @lNeed2Approve=0 AND (Pomain.PoStatus='OPEN' OR Pomain.PoStatus='CLOSED' OR Pomain.PoStatus='CANCEL') THEN 'EDITING'
										ELSE Pomain.Postatus END ,
					Pomain.Conum = Pomain.Conum+@nIncreaseCO ,
					--09/13/16 YS update ponote if provided
					Pomain.Ponote = CASE WHEN @ponote is null or @ponote='' THEN Pomain.Ponote ELSE @ponote END,
					-- 01/24/17 VL added functional currency code and FC code
					Pomain.PoTotalFC = PI.POTotalFC +Pomain.ShipChgFC,
					-- 06/01/17 VL comment out PoTax part
					--Pomain.PoTaxFC = PI.TaxTotalFC+CASE WHEN Pomain.ShipChgFC=0 OR POmain.ScTaxPct=0 THEN 0 ELSE ROUND((POmain.ShipChgFC * POmain.ScTaxPct)/100,2) END,
					Pomain.PoTotalPR = PI.POTotalPR +Pomain.ShipChgPR
					-- 06/01/17 VL comment out PoTax part
					--Pomain.PoTaxPR = PI.TaxTotalPR+CASE WHEN Pomain.ShipChgPR=0 OR POmain.ScTaxPct=0 THEN 0 ELSE ROUND((POmain.ShipChgPR * POmain.ScTaxPct)/100,2) END
								FROM (SELECT SUM(ROUND(CostEach * Ord_qty,2)) as POTotal, SUM(ROUND((CostEach * Ord_qty * Tax_Pct)/100,2)) as TaxTotal,
											SUM(ROUND(CostEachFC * Ord_qty,2)) as POTotalFC, SUM(ROUND((CostEachFC * Ord_qty * Tax_Pct)/100,2)) as TaxTotalFC,
											SUM(ROUND(CostEachPR * Ord_qty,2)) as POTotalPR, SUM(ROUND((CostEachPR * Ord_qty * Tax_Pct)/100,2)) as TaxTotalPR 
												FROM Poitems WHERE Ponum=@ponum) PI
					WHERE Pomain.Ponum=@ponum
				-- change order
				---06/06/16 YS update pomain totaltx
				-- 01/24/17 VL added functional currency code
				-- 06/01/17 VL added code to consider ShipChg
				UPDATE pomain set POTAX = tax.TotalTax + CASE WHEN (ShipChg = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChg*ScTaxPct/100,2) END,
					PoTaxfc = tax.TotalTaxFc + CASE WHEN (ShipChgFC = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChgFC*ScTaxPct/100,2) END,
					PoTaxPR = tax.TotalTaxPR + CASE WHEN (ShipChgPR = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChgPR*ScTaxPct/100,2) END
					from pomain p inner join (
					select t.ponum, t.uniqlnno,ROUND(ISNULL(SUM(d.ExtAmt*t.tax_rate/100),0.00),2) as TotalTax,
					case when @FcInstalled=1 then ROUND(isnull(SUM(ExtAmtFC*Tax_rate/100),0.00),2) else 0.00 end as TotalTaxFc,
					case when @FcInstalled=1 then ROUND(isnull(SUM(ExtAmtPR*Tax_rate/100),0.00),2) else 0.00 end as TotalTaxPR
					from @poitemsTax t
						cross apply (select i.IS_TAX, i.ORD_QTY*costeach as ExtAmt,i.ORD_QTY*costeachfc as ExtAmtFc, i.ORD_QTY*costeachPR as ExtAmtPR, uniqlnno from @poitems I where i.UNIQLNNO=t.uniqlnno and I.IS_TAX=1) D
						where tax_rate<>0 and d.IS_TAX=1
					GROUP BY  t.ponum,t.uniqlnno
					) Tax on p.ponum= tax.ponum
				
								
			   SELECT @CurrChange = 'CO # :'+CONVERT(char(3), Pomain.Conum)+', Date/Time: '+CONVERT(varchar(30),getdate(),126)+
							', By User: '+RTRIM(@desktopUserInitials)+', PO Total:$'+ CONVERT(varchar(15),Pomain.POTOTAL)+
							'. Changes were made using XL automation for adding new items to an existing PO. List of changes:'
							FROM Pomain WHERE PONUM=@ponum
				--12/17/14 YS changed where
				SELECT @CurrChange = @CurrChange +CHAR(13)+CHAR(9)+
						'Added Item Number '+CONVERT(varchar(3),D.ITEMNO) +
						CASE WHEN D.UNIQ_KEY <>' ' THEN ', Part # '+RTRIM(I.Part_no)+	
															CASE WHEN i.REVISION<>' ' THEN ', Rev '+RTRIM(I.Revision) ELSE '' END
								WHEN D.UNIQ_KEY = ' ' and D.Part_no<>' ' THEN ', Part # '+RTRIM(D.Part_no)
								WHEN D.UNIQ_KEY = ' ' and D.Descript<>' ' THEN ', Part '+RTRIM(D.Descript)
								ELSE '' END 								
						FROM @PoItems D	LEFT OUTER JOIN INVENTOR I on D.UNIQ_KEY =I.uniq_key WHERE PONUM=@ponum Order By ITEMNO 		
				Update POMAIN SET CurrChange =@CurrChange where PONUM=@ponum
					
				FETCH cPoNum INTO @ponum,@postatus,@coNum	 	
			END  --  (@@fetch_status = 0)
			--04/23/14 YS close cursor
			CLOSE cPoNum
			DEALLOCATE cPoNum
	END TRY
	BEGIN CATCH
		SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
		
			IF @@TRANCOUNT>0
				ROLLBACK TRANSACTION
			INSERT INTO importPoErrors (ErrorMessage)
				VALUES ('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
				'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
				'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
				'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
				'Error Message: '+@ERRORMESSAGE)
			
		return -1
	END CATCH
	IF @@TRANCOUNT>0
		COMMIT TRANSACTION
	-- use GOTO LABEL to alter the execution
	GOTO RETURNCODE 
	--  use GOTO LABEL to alter the execution
	-- define LABEL 
	RETURNCODE: 
	SELECT @nReturnCode as ReturnCode
END