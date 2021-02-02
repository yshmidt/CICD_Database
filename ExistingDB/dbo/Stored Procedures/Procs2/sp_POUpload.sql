


-- =============================================

	-- Author: Yelena Shmidt

	-- Create date: 02/02/2014

	-- Description: Purchase Order Upload

	-- Modified: 02/19/14 YS stuff "T" into the first position when PO is in auto mode

	--- 02/19/14 YS added firstarticle

	--  02/24/14 YS added different code for the validation. Remove fatal error

	--- check the cvode in the calling procedure/form

	--- do not fail on FOB/SHIPVIA/ - replace with empty and continue, but let the user know

	--- modified importPoErrors - added stopUpload bit column (default = 1). To indicate if the upload was stopped or not

	--- create exit code, use dual system to return multiple codes in order validation was taken

	-- 1. Invalid Item Type - fatal

	-- 2. Invalid Work Order information - Fatal

	-- 3. Invalid Project information - Fatal

	-- 4. Invalid warehouse information - Fatal

	-- 5. Supplier name is empty or invalid - Fatal

	-- 6. Invalid Buyer name - Not fatal

	-- 7. Some records do not have any Part No entered - Fatal

	-- 8. Some part Numbers entered are not part of the Inventory records or are not active - Fatal

	-- 9. Invalid Terms - Not fatal

	--10. Invalid GL # for MRO parts - Fatal

	--11. Invalid ShipCharge - Not fatal

	--12. Invalid FOB - Not fatal

	--13. Invalid Ship Via - Not fatal

	--14. One or number of required fields are empty -Fatal

	--15. Invalid MPN - Fatal

	--16. Some MPNs are on the 'Disallow for Purchasing' list - Fatal

	--17. Missing Wh/Location in Manex - Fatal

	--18. Duplicate PO # for different suppliers was entered - Fatal

	--19. Some PO Numbers have duplicate item numbers for the different items - Fatal

	--20. Duplicate PO Header information - Fatal

	-- 02/28/14 YS fix validation specify t.uniq_key
	---03/09/14 YS return sqlresult instead of return a code (having issue with XP machine for some reason)
	-- 04/10/14 YS added new parameters to be able to auto approve need to know total amount allowed to the user
	-- 04/14/14 YS moved end of the if @lValid=1 to the bottom to avoid errors when validation is failed prior to mpn and wh/loc
	-- 07/29/15 YS check if warehous is not empty and then validate. If empty validation #17 will find if autolocation allowed
	-- 07/29/15 YS add ValidationInfo column to all validation error result sets
	-- 08/12/15 YS remove inactive and disqualified
	---04/08/16 YS added code to populate NOTEASSIGN for the item if inventory record attached to the note
	-- 04/20/16 - 04/27/16 YS added code for FC upload
	--- 07/01/16 YS make sure that b_link is not null. Penang did not have any billing address setup
	-- 07/01/16 YS return using GOTO label from the catch block, instead of using return -1
	--- 09/09/16 YS added code to populate pomain.ponote, poitems.note1, poitschd.req_date and poitschd.origcommitdt 
	--09/14/16 YS make sure shiptime is not null when updating pomain
	-- 01/11/17 VL added one more parameter for dbo.fn_Convert4FCHC(), remove bidprice from fcused
	--			01/23/17 YS make sure the records for tax info is seleceted only once
	-- 01/24/17 VL added functional currency code
	-- 06/01/17 VL re-check functional currency code
	-- 06/27/19 VL we used to only add MRO requesttp for MRO item, but in desktop, user can added WO/PRJ for MRO item if the requesttp is 'WO/PRJ', so I added requesttp in template, if user does have wo/prj for requettp for MRO item, user can add it
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	-- =============================================

CREATE PROCEDURE [dbo].[sp_POUpload]

-- Add the parameters for the stored procedure here
@tUpload tPoCreate READONLY,
-- upload from mrp ='MRP'
@upLoadModule varchar(10),
@desktopUserInitials char(8),
@ApproveINvtAmt	numeric(15,5)=0,
@ApproveMroAmt numeric(15,5)=0
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from

	-- interfering with SELECT statements.

	SET NOCOUNT ON;
	--02/27/14 YS added return code
	--04/09/14 YS added autoapprove,@nSignatures code when uploaded from PO
	DECLARE @lValid bit=1,@AutoAppr4UpLoad bit,@nSignatures int,
			@AutoPoNum bit ,@nReturnCode int=0,
			@UniqSupno char(10),@ponum char(15)=' ',@oldPonum char(15),
			--04/19/16 YS added check if FC is installed
			@FcInstalled bit

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
		@nSignatures=PoDeflts.Signatures
	FROM PoDeflts

	
	-- validate data

	DECLARE @tImport tPoCreate

	INSERT INTO @tImport SELECT * FROM @tUpload

	--04/20/16 YS added new tax calculation based on the poitems is_tax and using new table poitemsTax
	declare @poitemsTax table (uniqpoitemstax char(10),ponum char(15),uniqlnno char(10),tax_id char(8),tax_rate numeric(8,4))

	


	--- mValidatePoItemValue
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	SELECT DISTINCT 'Item Type has to be ''MRO'' or ''INVT Part''' as ValidationInfo,PoitType 
		FROM @tImport
		WHERE PoitType NOT IN('MRO','INVT PART')

	IF @@ROWCOUNT > 0
	BEGIN
		-- !!! need to create an output maybe xml to show the problem
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Item Type',1)
		--02/27/14 YS added @nReturnCode=2 to indicate that validation failed
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid=0
	END --IF @@ROWCOUNT > 0 item type validation
	-- replace all values that supposed to be UPPER case in manex with upper(values) .
	-- 09/09/16 YS replace note1, ponote with empty if null
	UPDATE @tImport SET Part_no = UPPER(RTRIM(Part_no)),
		Revision = RTRIM(Revision),
		PartMfgr = UPPER(RTRIM(PartMfgr)),
		Mfgr_pt_no = RTRIM(Mfgr_pt_no),
		Buyer = UPPER(RTRIM(Buyer)),
		Warehouse = UPPER(warehouse),
		ShipCharge = UPPER(RTRIM(ShipCharge)),
		ShipVia = UPPER(RTRIM(ShipVia)),
		Terms = RTRIM(Terms) ,
		FOB = UPPER(RTRIM(FOB)),
		Itemno = CASE WHEN Itemno<>'' THEN dbo.PADL(RTRIM(Itemno),3,'0') ELSE ItemNo END,
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

	-- validate Work order
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	
	SELECT DISTINCT 'Work Order Number record is not found in Woentry table' as ValidationInfo,WoNumber
		FROM @tImport
	WHERE woNumber<>' '
	AND WoNumber NOT In (SELECT Wono FROM WoEntry)
	IF @@ROWCOUNT>0
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Work Order information',1)
		--02/27/14 YS added @nReturnCode=2 to indicate that validation failed
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0
	END -- IF @@ROWCOUNT>0
	-- validate project
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	SELECT DISTINCT 'Project record is not found in PjctMain table' as ValidationInfo,PrjNumber
		FROM @tImport
	WHERE PrjNumber<>' ' 
	AND PrjNumber NOT In (SELECT PrjNumber FROM PjctMain)
	IF @@ROWCOUNT>0
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Project information',1)
		--02/27/14 YS added @nReturnCode=2 to indicate that validation failed
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0

	END -- @@ROWCOUNT>0
	-- validate package
	-- update with empty value if not in the system setup, will be populated from the default values later
	UPDATE @tImport set Package ='' WHERE Package NOT IN (SELECT left(text,10) FROM SUpport where Fieldname = 'PART_PKG');
	-- validate warehous
	-- 07/29/15 YS check if warehous is not empty and then validate. If empty validation #17 will find if autolocation allowed
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	SELECT 'Warehouse: ' +RTRIM(Warehouse)+' is not found in Warehous table' as ValidationInfo,*
		FROM @tImport
		WHERE Poittype='Invt Part' 
		AND Warehouse<>' ' and Warehouse NOT IN (SELECT Warehouse FROM warehous WHERE warehouse<>'WIP' AND warehouse<>'WO-WIP' AND warehouse<>'MRB');

	IF @@ROWCOUNT>0
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid warehouse information',1)
		--02/27/14 YS added @nReturnCode=2 to indicate that validation failed
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0
	END  --- @@ROWCOUNT>0
	ELSE
	BEGIN
		UPDATE @tImport SET UniqWH=Warehous.UniqWH,GL_NBR=Warehous.Wh_gl_nbr FROM Warehous INNER JOIN @tImport t ON Warehous.warehouse=t.Warehouse WHERE t.Poittype<>'MRO'
	END ---- @@ROWCOUNT>0
	-- check supplier
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	-- 08/12/15 YS remove inactive and disqualified
	SELECT DISTINCT 'Supplier: ' +RTRIM(SupName )+' is not found in Supinfo table' as ValidationInfo
	FROM @tImport
		WHERE supname=SPACE(LEN(SupName)) OR dbo.PADR(UPPER(RTRIM(supname)),LEN(SupName),' ')
		NOT in (SELECT UPPER(supname) FROM supinfo where Status<>'INACTIVE'
		AND Status<>'DISQUALIFIED');
	IF @@ROWCOUNT>0
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Supplier name is empty or invalid.',1)
		set @lValid =0
		--02/27/14 YS added @nReturnCode=2 to indicate that validation failed
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
	END   --- @@ROWCOUNT>0
	-- validate buyer
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	DECLARE @badBuyer Table (Buyer char(3),ValidationInfo varchar(50))
	INSERT INTO @badBuyer
	SELECT buyer,'Buyer is not part of buyerini table' 
		FROM @tImport
	WHERE buyer<>' ' 
	AND dbo.PADR(RTRIM(buyer),LEN(buyer),' ')
	NOT IN (SELECT ini FROM buyerini) ;
	IF @@ROWCOUNT>0
	BEGIN
		--02/24/14 YS added stopUpload column
		-- since empty buyer is allowed will replace with an empty value and continue, but record the problem
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Buyer name.',0)
		--set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 3
							WHEN @nReturnCode=2 THEN 5
							ELSE 3 END
		update @tImport set BUYER = ' ' 
			where BUYER<>' ' AND dbo.PADR(RTRIM(buyer),LEN(buyer),' ')
			IN (SELECT Buyer FROM @badBuyer)
	END  -- @@ROWCOUNT>0
	-- validate part number/revision
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	
	SELECT ponum,itemno,PoitType,'Missing Part Number Information' as ValidationInfo
		FROM @tImport
	WHERE part_no=' ' AND PoitType='Invt Part'
	UNION
	SELECT ponum,itemno,PoitType,'Missing Part Number Information' as ValidationInfo
		FROM @tImport
	WHERE part_no='' AND Descript='' AND PoitType<>'Invt Part' ;
	IF @@ROWCOUNT>0
	BEGIN
		--02/24/14 YS added stopUpload column
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
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	
	SELECT 'Missing Part Numbers or Inactive Parts' as ValidationInfo,*
	FROM @tImport
	WHERE RTRIM(poittype)='Invt Part'
	AND Part_no+Revision NOT in
		(SELECT part_no+revision FROM inventor WHERE (inventor.part_sourc = 'BUY'
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
	-- update default terms
	UPDATE @tImport SET t.terms = s.terms
		FROM @tImport t INNER JOIN supinfo s on t.Supname= s.Supname
		WHERE t.terms=' '
	--if terms are not empty we need to validate from PmtTerms table.
	--02/24/14 YS added stopUpload column
	-- since empty terms are allowed will replace with an empty value and continue, but record the problem
	--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	DECLARE @badTerms TABLE (ValidationInfo varchar(100),Terms char(15))
	INSERT INTO @badTerms
		SELECT distinct 'Invalid Terms' as ValidationInfo, Terms
		FROM @tImport
	WHERE Terms<>' ' 
	AND	UPPER(terms) NOT IN (SELECT UPPER(descript) FROM pmtterms) ;
	IF @@ROWCOUNT>0
	BEGIN

		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Terms.',0)
		--set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 3
					WHEN @nReturnCode=2 THEN 5
						ELSE 3 END
		update @tImport set Terms = ' ' where Terms<>' ' AND Terms
			IN (SELECT Terms FROM @badTerms)
	END ---  @@ROWCOUNT>0
	-- check if GL installed
	IF (SELECT Installed from ITEMS where ScreenName = 'GLREL')=1
	BEGIN
		-- check gl_nbrs for mro items
		--07/29/15 YS added column to indicate what was validating. When user gets an Xl file the first column will give them more information
	
		SELECT 'Empty or Missing GL # for none Inventory Items' as ValidationInfo , *
			FROM @tImport t
		WHERE poittype='MRO' AND
		(gl_nbr=' ' OR RTRIM(gl_nbr)
		NOT in (SELECT gl_nbr FROM invtgls WHERE invtgls.rec_type=('M') ));
	END
	IF @@ROWCOUNT>0
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid GL # for MRO parts.',1)
		set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
			WHEN @nReturnCode=3 THEN 5
			ELSE 2 END
	END --  @@ROWCOUNT>0
	--04/20/16 ys new code to update i_link and foreign currency field
	--default i_link, b_link, c_link , r_link, uniqsupno
	update @tImport set t.b_link=Res.b_link,
			t.c_link=Res.c_link,
			t.I_link=Res.i_link,
			t.r_link = res.r_link,
			DELTIME=res.SHIPTIME,
			t.uniqsupno= res.uniqsupno,
			t.shipcharge=case when t.shipcharge=''  then res.shipcharge else t.shipcharge end,
			t.fob=case when t.fob=''  then res.fob else t.fob end,
			t.shipvia=case when t.shipvia='' then res.shipvia else t.shipvia end ,
			fcused_uniq = case when @FcInstalled=1 then res.fcused_uniq else '' end,
			t.UseDefaultTax = res.UseDefaultTax, 
			--- this tax id defaulted and saved in the supinfo table
			t.defaultTaxid = res.tax_id
			from @tImport t INNER JOIN 
			--- 07/01/16 YS make sure that b_link is not null. Penang did not have any billing address setup
			(select s.supname,s.uniqsupno,s.supid,s.r_link,s.C_LINK,s.fcused_uniq, case when b.shipto is null then bd.linkadd else s.AD_LINK end as i_link, 
			isnull(sb.b_link,space(10)) as b_link,
			--09/14/16 YS make sure shiptime is not null when updating pomain
			isnull(b.SHIPTIME , space(8)) as shipTime,isnull(b.SHIPCHARGE,bd.SHIPCHARGE) as shipCharge,isnull(b.FOB,bd.fob) as FOB,isnull(b.shipvia,bd.SHIPVIA) as shipVia,
			isnull(b.UseDefaultTax,1) as UseDefaultTax,s.TAX_ID
			from supinfo s left outer join shipbill b on s.ad_link=b.LINKADD and b.RECORDTYPE='I' and b.custno=''
			outer apply (select shipbill.linkadd ,shipbill.SHIPCHARGE,fob,shipvia from shipbill  where shipbill.RECORDTYPE='I' 
			and shipbill.custno='' and RECV_DEFA=1) BD 
			outer apply (select shipbill.linkadd as b_link from shipbill  where RECORDTYPE='P' and custno='' and RECV_DEFA=1) SB
			) res on t.supname=res.SUPNAME
	
	if (@FcInstalled=1)
	BEGIN
		;with
		FC
		as
		(
		select ROW_NUMBER() over (partition by FCUSED_UNIQ order by FCDATETIME desc) as nrecord, 
			-- 01/11/17 VL remove bidprice
			FCHIST_KEY,FCUSED_UNIQ,FCDATETIME,FGNCNCY,ASKPRICE  
			from FCHISTORY 
		)
		update @tImport set t.Fchist_key=H.fchist_key from @tImport t inner join FC H on h.FCUSED_UNIQ=t.fcused_uniq and h.nrecord=1
		-- 06/01/17 VL added PRFcused_uniq and FuncFcused_uniq
		UPDATE @tImport SET PRFCUSED_UNIQ = dbo.fn_GetPresentationCurrency(), FUNCFCUSED_UNIQ = dbo.fn_GetFunctionalCurrency()
	END	
	UPDATE @tImport SET is_sctax = 1 WHERE NOT sctaxpct<>0
--	@cType: Conversion FC to Home (F), Home to FC (H)
--	@cFcused_uniq: Foreign currency fcused_uniq
--	@nAmt home: currency amount to be converted
--	@cFCHist_Key: the FCHist_key

	-- 01/24/17 VL added functional currency code
	-- 06/01/17 VL changed the 4th parameter from dbo.fn_GetFunctionalCurrency() to FuncFcused_uniq
	update @timport set costEach=CASE WHEN @FcInstalled=1 then dbo.fn_Convert4FCHC('F',fcused_uniq,costEachFC,FUNCFCUSED_UNIQ,Fchist_key) else costeach end,
		SHIPCHG = case when @FcInstalled=1 then  dbo.fn_Convert4FCHC('F',fcused_uniq,SHIPCHGfc,FUNCFCUSED_UNIQ,Fchist_key) else SHIPCHG end,
		costEachPR=CASE WHEN @FcInstalled=1 then dbo.fn_Convert4FCHC('F',fcused_uniq,costEachfc,PRFCUSED_UNIQ,Fchist_key) else costeachPR end,
		SHIPCHGPR = case when @FcInstalled=1 then  dbo.fn_Convert4FCHC('F',fcused_uniq,SHIPCHGfc,PRFCUSED_UNIQ,Fchist_key) else SHIPCHGPR end
			
	--select * from @timport



	--04/20/16 ys replace by new code above to update i_link and foreign currency field
	--UPDATE @tImport SET b_link=ShipBill.LinkAdd
	--	FROM Shipbill WHERE Shipbill.custno = SPACE(10) AND Shipbill.recordtype = ( 'P' ) AND Recv_Defa=1;
	--UPDATE @tImport SET t.c_link = s.c_link,t.r_link = s.r_link, t.uniqsupno= s.uniqsupno
	--	from @tImport t INNER JOIN supinfo s on S.Supname=t.supname ;
	
	--UPDATE @tImport SET is_sctax = 1 WHERE NOT sctaxpct<>0
	--select * from @tImport
	--UPDATE @tImport SET i_link=s.LinkAdd,
	--					delTime =s.ShipTime
	--	from ShipBill s 
	--	WHERE s.custno = ' '
	--	AND s.recordtype = 'I'
	--	AND Recv_Defa=1
	
	--UPDATE @tImport SET t.shipcharge=ShipBill.shipcharge
	--	from ShipBill,@tImport t 
	--	WHERE Shipbill.custno=' '
	--	AND Shipbill.recordtype = 'I' AND Recv_Defa=1
	--	AND t.shipcharge=' ' ;

	--UPDATE @tImport SET t.fob=Shipbill.fob
	--	from ShipBill,@tImport t WHERE Shipbill.custno =' '
	--	AND Shipbill.recordtype = 'I'
	--	AND Recv_Defa=1
	--	AND t.fob=' ' ;

	--UPDATE @tImport SET t.ShipVia =Shipbill.ShipVia
	--	from ShipBill,@tImport t 
	--	WHERE Shipbill.custno =' '
	--	AND Shipbill.recordtype = 'I'
	--	AND Recv_Defa=1
	--	AND t.ShipVia=' ' ;

	-- allow empty
	--02/24/14 YS added stopUpload column
	-- since empty value is allowed, replace all the bad values with an empty andcontinue. Record the problem
	---04/20/16 ys}

	DECLARE @badShipCharge table (ValidationInfo varchar(100),ShipCharge char(15))

	INSERT INTO @badShipCharge
		SELECT distinct 'Invalid ShipCharge' as ValidationInfo,ShipCharge 
			FROM @tImport
		WHERE ShipCharge<>' '
		AND shipcharge
		NOT in (SELECT LEFT([TEXT],15) FROM SUPPORT WHERE FIELDNAME = 'SHIPCHARGE')

	IF @@ROWCOUNT>0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid ShipCharge.',0)
		--set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 3
						WHEN @nReturnCode=2 THEN 5
					ELSE 3 END
		update @tImport set ShipCharge = ' ' 
				where ShipCharge<>' ' AND ShipCharge
				IN (SELECT ShipCharge FROM @badShipCharge)

	END  -- @@ROWCOUNT>0
	-- allow empty
	--02/24/14 YS added stopUpload column
	-- since empty value is allowed, replace all the bad values with an empty and continue. Record the problem
	--07/29/15 YS added ValidationInfo column
	DECLARE @badFob table (ValidationInfo varchar(100),Fob char(15))

	INSERT INTO @badFob
		SELECT distinct 'Inavlid FOB' as ValidationInfo,Fob 
			FROM @tImport
		WHERE FOB<>' '
		AND fob
		NOT in (SELECT LEFT([TEXT],15) FROM SUPPORT WHERE FIELDNAME = 'FOB') ;
	IF @@ROWCOUNT>0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid FOB.',0)
		--set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 3
						WHEN @nReturnCode=2 THEN 5
						ELSE 3 END
		update @tImport set FOB = ' ' where FOB<>' ' AND FOB
				IN (SELECT FOB FROM @badFob)

	END --- @@ROWCOUNT>0
	-- allow empty
	--02/24/14 YS added stopUpload column
	-- since empty value is allowed, replace all the bad values with an empty and continue. Record the problem
	--07/29/15 YS added ValidationInfo column
	DECLARE @badShipVia table (ValidationInfo varchar(100),ShipVia char(15))
	INSERT INTO @badShipVia
	SELECT distinct 'Invalid Ship Via' as ValidationInfo,ShipVia FROM @tImport
		WHERE ShipVia<>' ' AND ShipVia
		NOT in (SELECT LEFT([TEXT],15) FROM SUPPORT WHERE FIELDNAME = 'SHIPVIA') ;

	IF @@ROWCOUNT>0
	BEGIN

		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Ship Via.',0)
		--set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 3
							WHEN @nReturnCode=2 THEN 5
						ELSE 3 END
		update @tImport set ShipVia = ' ' where ShipVia<>' ' AND ShipVia
				IN (SELECT ShipVia FROM @badShipVia)

	END   --- @@ROWCOUNT>0
	-- mValidateEmpty

	IF EXISTS
		(SELECT Ponum,ItemNo,Part_no,Revision,Poittype,requestor,partmfgr,Schd_date,Schd_qty
				FROM @tImport
				WHERE itemno=' ' OR poittype=' '
					OR (PoitType='MRO' AND REQUESTOR=' ')
					OR (PoitType<>'MRO' AND partmfgr=' ')
					OR schd_date IS null OR schd_qty=0.00 )

	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('One or number of required fields are empty.',1)
		set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
						WHEN @nReturnCode=3 THEN 5
						ELSE 2 END
	END  -- EXISTS	(SELECT Ponum....
	-- mUpdateSchdDates update schedule dates
	--09/09/16 YS added reqdate and ORIGCOMMITDT date to the template. Populate only if template columns were empty
	UPDATE @tImport SET req_date=ISNULL(req_date,schd_date),origcommitdt=isnull(ORIGCOMMITDT,schd_date)
	--UPDATE @tImport SET req_date=schd_date,origcommitdt=schd_date
	-- populate information from Inventor table
	-- 02/19/14 YS added firstarticle
	-- 04/20/16 YS update taxable from inventor
	UPDATE @tImport SET t.uniq_key=i.uniq_key,
				t.PUR_UOFM=i.PUR_UOFM,
				t.U_OF_MEAS=i.U_OF_MEAS,
				t.Package = CASE WHEN t.Package=' ' THEN i.Package ELSE t.Package END,
				t.firstarticle=i.firstarticle,
				t.is_tax=i.Taxable
		FROM inventor i inner join @tImport t on i.PART_NO=t.part_no and i.REVISION =t.revision
		WHERE t.poittype='Invt Part' AND i.part_sourc <> 'CONSG'
		-- 07/01/16 this was for testing only
		--select * from @tImport
	-- validate MPN
	--02/28/14 YS fix validation specify t.uniq_key
	--10/10/14 YS replaced invtmfhd tabler with 2 new tables
	-- use if exists in stead of select and @@rowcount
	IF EXISTS(SELECT 1 FROM @tImport t
		WHERE poittype<>'MRO'
		AND NOT EXISTS
			--10/10/14 YS replaced invtmfhd tabler with 2 new tables
			-- and use not exists
			--(SELECT partmfgr+mfgr_pt_no FROM invtmfhd WHERE invtmfhd.uniq_key = t.uniq_key AND Invtmfhd.is_deleted=0);
			(SELECT 1 FROM InvtMPNLink L INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId 
			WHERE l.uniq_key = t.uniq_key 
			and m.PartMfgr=t.PARTMFGR
			and m.mfgr_pt_no=t.MFGR_PT_NO
			AND l.is_deleted=0 and m.IS_DELETED=0))

	--IF @@ROWCOUNT>0
	BEGIN
		
		--07/29/15 ys added ValidationInfo
		SELECT 'PrtMfgr and MPN combination is not part of the MfgrMaster Table for selected part' as ValidationInfo,* FROM @tImport t
		WHERE t.poittype<>'MRO'
		AND NOT exists
		(SELECT 1 FROM MfgrMaster M inner join Invtmpnlink L on l.mfgrMasterId=M.MfgrMasterId  
		WHERE L.uniq_key = t.uniq_key AND L.is_deleted=0 and m.is_deleted=0 and m.partmfgr=t.partmfgr and m.mfgr_pt_no=t.Mfgr_pt_no);
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid MPN.',1)
		set @lValid =0
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
					WHEN @nReturnCode=3 THEN 5
					ELSE 2 END
	END   ---  @@ROWCOUNT>0
	ELSE
	BEGIN
	-- validate MPN
	--02/28/14 YS fix validation specify t.uniq_key
	--10/10/14 YS replaced invtmfhd tabler with 2 new tables
	-- use if exists in stead of select and @@rowcount
	IF EXISTS(SELECT 1 FROM @tImport t
		WHERE poittype<>'MRO'
		AND NOT EXISTS
			--10/10/14 YS replaced invtmfhd tabler with 2 new tables
			-- and use not exists
			--(SELECT partmfgr+mfgr_pt_no FROM invtmfhd WHERE invtmfhd.uniq_key = t.uniq_key AND Invtmfhd.is_deleted=0);
			(SELECT 1 FROM InvtMPNLink L INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId 
			WHERE l.uniq_key = t.uniq_key 
			and m.PartMfgr=t.PARTMFGR
			and m.mfgr_pt_no=t.MFGR_PT_NO
			AND l.is_deleted=0 and m.IS_DELETED=0))

	--IF @@ROWCOUNT>0
	BEGIN
		
		--07/29/15 ys added ValidationInfo
		SELECT 'PrtMfgr and MPN combination is not part of the MfgrMaster Table for selected part' as ValidationInfo,* FROM @tImport t
		WHERE t.poittype<>'MRO'
		AND NOT exists
		(SELECT 1 FROM MfgrMaster M inner join Invtmpnlink L on l.mfgrMasterId=M.MfgrMasterId  
		WHERE L.uniq_key = t.uniq_key AND L.is_deleted=0 and m.is_deleted=0 and m.partmfgr=t.partmfgr and m.mfgr_pt_no=t.Mfgr_pt_no);

			--02/24/14 YS added stopUpload column
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
		--10/10/14 YS replaced invtmfhd table with 2 new tables
		UPDATE @tImport SET t.uniqmfgrhd=l.uniqmfgrhd,
						t.Mfgr_pt_no=m.Mfgr_pt_no
			FROM InvtMPNLink L inner join Mfgrmaster M on l.mfgrMasterId=M.MfgrMasterId
			inner join @tImport t ON l.uniq_key=t.Uniq_key
				AND m.PartMfgr=t.PartMfgr
				AND m.Mfgr_pt_no=t.Mfgr_pt_no ;
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
				--10/10/14 YS replaced invtmfhd table with 2 new tables
				FROM @tImport as ZimportPO INNER JOIN InvtMPNLink L ON L.Uniqmfgrhd=ZimportPo.Uniqmfgrhd
				INNER JOIN MfgrMaster M ON l.mfgrMasterId=M.MfgrMasterId
			WHERE M.autolocation=0
			AND Poittype<>'MRO'
		)
		--for those parts that cannot create a new location at receiving check if location exists in the Invtmfgr
		--07/29/15 YS added ValidationInfo column
		SELECT 'Warehouse and Location entered are not assigned to the part' as ValidationInfo,notauto.*
		FROM notauto
		where Uniqmfgrhd+uniqwh+location
		NOT IN (SELECT Uniqmfgrhd+uniqwh+location FROM invtmfgr WHERE invtmfgr.uniq_key=notauto.Uniq_key)
		IF @@ROWCOUNT>0
		BEGIN
			--02/24/14 YS added stopUpload column
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
	-- mPoNumDistribute
	-- if from PO upload module
	--- check for autapprove and po numberring setup 
	IF (@upLoadModule ='PO' and @AutoAppr4UpLoad=1 and @AutoPoNum =0)
	BEGIN
		-- if from PO upload and auto-approve and manual number
		-- check if user left empty PO #
		---mValidateEmptyPo
		-- 07/29/15 Ys added ValidationInfo
		SELECT 'Manual Purcahse Order Number required' as ValidationInfo,* 
			FROM @tImport 
		WHERE Ponum =' '
		IF @@ROWCOUNT <> 0
		BEGIN
			--02/24/14 YS added stopUpload column
			INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Missing Purchase Order Number(s).',1)
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
			--RETURN @nReturnCode
			-- 04/10/14 YS use GOTO LABEL to alter the execution
			GOTO RETURNCODE 
		END -- @@ROWCOUNT <> 0
		-- mChkSamePODiffSupplier
		--check if same PO for the different suppler
		--07/29/15 ys added ValidationInfo column
		SELECT 'Dupliocate PO # for different suppliers was entered.' as ValidationInfo,
		Ponum,COUNT(DISTINCT SupName) as n 
			FROM @tImport GROUP BY PoNum 
		HAVING COUNT(DISTINCT SupName)>1 
		IF @@ROWCOUNT <>0
		BEGIN	
			INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Dupliocate PO # for different suppliers was entered.',1)
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
			--RETURN @nReturnCode
			-- 04/10/14 YS use GOTO LABEL to alter the execution
			GOTO RETURNCODE 
		END ---- @@ROWCOUNT <>0
		-- append leading zeros and check if exists 
		-- 07/29/15 YS added ValidationInfo column
		SELECT DISTINCT 'Purchase Order Number already exists' as ValidationInfo,Ponum 
			FROM @tImport
			WHERE dbo.PADL(RTRIM(LTRIM(UPPER(Ponum))),15,'0') IN (SELECT Ponum FROM Pomain)

		IF @@ROWCOUNT <>0
		BEGIN
			INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Some PO Numbers are already in use.',1)
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
			--RETURN @nReturnCode
			-- 04/10/14 YS use GOTO LABEL to alter the execution
			GOTO RETURNCODE 
		END -- @@ROWCOUNT <>0
	
		UPDATE @tImport SET Ponum = dbo.PADL(RTRIM(LTRIM(UPPER(Ponum))),15,'0')
		 
	END --- (@upLoadModule ='PO' and @AutoAppr4UpLoad=1 and @AutoPoNum =0)
	
	--04/09/14 added @upLoadModule = 'PO'
	IF (@upLoadModule='MRP') OR (@upLoadModule='PO' AND ((@AutoAppr4UpLoad=1 AND @AutoPoNum =1) OR @AutoAppr4UpLoad=0))
	BEGIN
		SELECT * FROM @tImport
		WHERE PoNum=' '
		IF @@ROWCOUNT <>0
		BEGIN
			--some lines have empty PO #
			--will ignore PO # all together
			--group by supplier #
			-- have to use a cursor because GetNextPoNumber procedure and I will not able to update multiple records using SELECT
			-- have to use procedure because when next number is selected have to update micssys
			DECLARE NewPonum CURSOR FORWARD_ONLY FOR
			SELECT Distinct Uniqsupno
				FROM @tImport
			OPEN NewPonum
			FETCH NewPonum INTO @uniqsupno
			
			WHILE (@@fetch_status = 0)
			BEGIN
				IF (@AutoPoNum=1)
				BEGIN
					EXEC GetNextPoNumber @pcNextNumber=@ponum OUTPUT
					--02/19/14 YS stuff "T" into the first position 
					-- 04/09/14 YS only if from MRP or @AutoAppr4UpLoad=0
					IF (@upLoadModule='MRP' OR (@upLoadModule='PO' AND @AutoAppr4UpLoad=0))
					BEGIN
						SET @ponum=STUFF(@ponum,1,1,'T') ;
					END	---(@upLoadModule='MRP' OR (@upLoadModule='PO' AND @AutoAppr4UpLoad=0))
				END	-- (@AutoPoNum=1)
				ELSE
				EXEC GetNextTempPONumber @pcNextNumber=@ponum OUTPUT
	
				UPDATE @tImport SET PoNum=@ponum WHERE UniqSupno=@UniqSupno ;
				FETCH NewPonum INTO @uniqsupno
			END  --  (@@fetch_status = 0)
			CLOSE NewPonum
			DEALLOCATE NewPonum
		END -- IF @@ROWCOUNT <>0 found empty PO
		ELSE -- PO was entered by user
		BEGIN
			-- check if same PO different supplier is entered
			IF EXISTS (SELECT Ponum,COUNT(DISTINCT UniqSUpno)
				FROM @tImport GROUP BY Ponum HAVING COUNT(DISTINCT UniqSUpno)>1)
			BEGIN
				--02/24/14 YS added stopUpload column
				INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Duplicate PO # for different suppliers was entered.',1)
				--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
				set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
									WHEN @nReturnCode=3 THEN 5
									ELSE 2 END
				--RETURN @nReturnCode
				-- 04/10/14 YS use GOTO LABEL to alter the execution
				GOTO RETURNCODE 
			END		-- IF EXISTS (SELECT Ponum,COUNT(DISTINCT UniqSUpno)
						
			DECLARE NewPonum CURSOR FORWARD_ONLY FOR
			SELECT Distinct Ponum
				FROM @tImport ORDER BY Ponum
			OPEN NewPonum
			FETCH NewPonum INTO @oldPonum
			WHILE (@@fetch_status = 0)
			
			BEGIN
				IF (@AutoPoNum=1)
				BEGIN
					EXEC GetNextPoNumber @pcNextNumber=@ponum OUTPUT
					--02/28/14 YS stuff "T" into the first position
					-- 04/09/14 YS only if from MRP or @AutoAppr4UpLoad=0
					IF (@upLoadModule='MRP' OR (@upLoadModule='PO' AND @AutoAppr4UpLoad=0))
					BEGIN
						SET @ponum=STUFF(@ponum,1,1,'T') ;
					END --- @upLoadModule='MRP' OR (@upLoadModule='PO' AND @AutoAppr4UpLoad=0))
					
				END --- (@AutoPoNum=1)
				ELSE
					EXEC GetNextTempPONumber @pcNextNumber=@ponum OUTPUT
			
				UPDATE @tImport SET PoNum=@ponum WHERE ponum=@oldPonum
				FETCH NewPonum INTO @oldPonum
			END -- WHILE (@@fetch_status = 0)
			CLOSE NewPonum
			DEALLOCATE NewPonum
		END -- PO was entered by user
	END --- IF (@upLoadModule='MRP')
	
	--calculate PO total
	

		
	--- move calcualting po total after tax table is created
	--;WITH PoTotal
	--AS
	--(
	--SELECT PoNum,SUM(ROUND(CostEach * Schd_qty,2)) AS PoTotal
	--,SUM(ROUND((CostEach * Schd_qty * Tax_Pct)/100,2)) AS TaxTotal
	--FROM @tImport
	--GROUP BY Ponum
	--)
	--UPDATE @tImport SET t.PoTotal=PoTotal.PoTotal,
	--			t.PoTax = PoTotal.TaxTotal from PoTotal INNER JOIN @tImport t ON PoTotal.Ponum=t.Ponum

	--UPDATE @tImport SET PoTotal=PoTotal + ShipChg,
	--				PoTax = PoTax+
	--				CASE WHEN ShipChg=0 OR ScTaxPct=0 THEN 0 ELSE ROUND((ShipChg * ScTaxPct)/100,2) END

	-- make sure that header info repeats for the same PO
	--BUYER,Terms,SHIPCHG,IS_SCTAX,SCTAXPCT,CONFNAME,CONFIRMBY,SHIPCHARGE,Fob,ShipVia,DelTime,LFREIGHTINCLUDE
	-- 06/01/17 VL also update ShipChgFC
	update @tImport set BUYER=case when t1.buyer IS NOT null and t1.buyer<>' ' then t1.buyer else b.buyer end,
						Terms= case when t1.terms IS NOT null and t1.terms<>' ' then t1.terms else t.terms end,
						SHIPCHG =case when t1.SHIPCHG IS NOT null and t1.SHIPCHG<>0 then t1.SHIPCHG else SH.SHIPCHG end,
						IS_SCTAX =case when t1.IS_SCTAX IS NOT null and t1.IS_SCTAX<>0 then t1.IS_SCTAX else STAX.IS_SCTAX end,
						SCTAXPCT=case when t1.SCTAXPCT IS NOT null and t1.SCTAXPCT<>0 then t1.SCTAXPCT else ST.SCTAXPCT end,
						CONFNAME=case when t1.CONFNAME IS NOT null and t1.CONFNAME<>' ' then t1.CONFNAME else C.CONFNAME end,
						CONFIRMBY=case when t1.CONFIRMBY IS NOT null and t1.CONFIRMBY<>' ' then t1.CONFIRMBY else CB.CONFIRMBY end,
						SHIPCHARGE=case when t1.SHIPCHARGE IS NOT null and t1.SHIPCHARGE<>' ' then t1.SHIPCHARGE else S.SHIPCHARGE end,
						Fob=case when t1.Fob IS NOT null and t1.Fob<>' ' then t1.Fob else F.Fob end,
						ShipVia=case when t1.ShipVia IS NOT null and t1.ShipVia<>' ' then t1.ShipVia else V.ShipVia end,
						DelTime=case when t1.DelTime IS NOT null and t1.DelTime<>' ' then t1.DelTime else D.DelTime end,
						LFREIGHTINCLUDE=case when t1.LFREIGHTINCLUDE IS NOT null and t1.LFREIGHTINCLUDE<>0 then t1.LFREIGHTINCLUDE else l.LFREIGHTINCLUDE end,
						SHIPCHGFC =case when t1.SHIPCHGFC IS NOT null and t1.SHIPCHGFC<>0 then t1.SHIPCHGFC else SH.SHIPCHGFC end
			FROM @tImport t1 inner join (SELECT ponum,buyer from @tImport where buyer is not null and buyer<>' ') b ON t1.ponum = b.ponum
					INNER JOIN (SELECT ponum,terms from @tImport where terms is not null and terms<>' ') t ON t1.ponum = t.ponum
					INNER JOIN (SELECT ponum,SHIPCHG, SHIPCHGFC from @tImport where SHIPCHG is not null and SHIPCHG<>0) SH ON t1.ponum = sh.ponum
					INNER JOIN (SELECT ponum,IS_SCTAX from @tImport where IS_SCTAX is not null and IS_SCTAX<>0) STAX ON t1.ponum = STAX.ponum
					INNER JOIN (SELECT ponum,SCTAXPCT from @tImport where SCTAXPCT is not null and SCTAXPCT<>0) ST ON t1.ponum = ST.ponum
					INNER JOIN (SELECT ponum,CONFNAME from @tImport where CONFNAME is not null and CONFNAME<>' ') c ON t1.ponum = c.ponum
					INNER JOIN (SELECT ponum,CONFIRMBY from @tImport where CONFIRMBY is not null and CONFIRMBY<>' ') cb ON t1.ponum = cb.ponum
					INNER JOIN (SELECT ponum,SHIPCHARGE from @tImport where SHIPCHARGE is not null and SHIPCHARGE<>' ') s ON t1.ponum = s.ponum
					INNER JOIN (SELECT ponum,Fob from @tImport where Fob is not null and Fob<>' ') f ON t1.ponum = f.ponum
					INNER JOIN (SELECT ponum,ShipVia from @tImport where ShipVia is not null and ShipVia<>' ') v ON t1.ponum = v.ponum
					INNER JOIN (SELECT ponum,DelTime from @tImport where DelTime is not null and DelTime<>' ') d ON t1.ponum = d.ponum
					INNER JOIN (SELECT ponum,LFREIGHTINCLUDE from @tImport where LFREIGHTINCLUDE is not null and LFREIGHTINCLUDE<>0) l ON t1.ponum = l.ponum

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
	-- 01/24/17 VL added functional currency code, also added FC code
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	DECLARE @PoItemsUnique Table (Ponum char(15),part_no char(35),revision char(8),costeach numeric(13,5),itemno char(3),uniqlnno char(10),is_tax bit,costeachFC numeric(13,5),costeachPR numeric(13,5))
	INSERT INTO @PoItemsUnique (Ponum,part_no,revision,costeach,Itemno,is_tax,costeachfc, costeachPR)
		SELECT Distinct Ponum,part_no,revision,costeach,Itemno,is_tax,costeachfc, costeachPR
		FROM @tImport

	UPDATE @PoItemsUnique SET UniqLnno = dbo.fn_GenerateUniqueNumber()
	UPDATE @tImport SET t.Uniqlnno=i.uniqlnno from @PoItemsUnique I inner join @tImport t on I.Ponum=t.Ponum AND I.Itemno=t.Itemno
	--04/27/16 YS added tax table
		--01/23/17 YS make sure the records seleceted only once
	;with poitemstaxinfo
	as
	(
	select distinct poi.ponum,poi.uniqlnno,st.tax_id,st.Tax_rate 
	--- check default tax for the default receiving location 
	from @PoItemsUnique POI inner join @tImport t on poi.ponum=t.ponum
	inner join shiptax ST on t.I_LINK=st.LINKADD and 
	((t.defaultTaxid<>' ' and t.defaultTaxid=st.tax_id) OR (t.defaultTaxid=' ' and t.UseDefaultTax=1 and st.DEFAULTTAX=1))
	where poi.is_tax=1
	--- insert all the taxes for the location if UseDefaultTax=0
	UNION
	select DISTINCT poi.ponum,poi.uniqlnno,st.tax_id,st.Tax_rate 
		--- check default tax for the default receiving location 
		from @PoItemsUnique POI inner join @tImport t on poi.ponum=t.ponum and t.UseDefaultTax=0 
		inner join shiptax ST on t.I_LINK=st.LINKADD 
		where poi.is_tax=1
	)
	insert into @poitemsTax (uniqpoitemstax,ponum,uniqlnno,tax_id,tax_rate)
	select dbo.fn_GenerateUniqueNumber(),ponum,uniqlnno,
	tax_id,Tax_rate 
	from poitemstaxinfo

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
		
		
		
	
	


	-- Calculate Ord_qty,balance

	UPDATE @tImport SET t.Ord_qty=SumOrder.Qty_sum ,
					t.Balance=SumOrder.Qty_sum,
					t.s_ord_qty=dbo.fn_ConverQtyUOM(t.PUR_UOFM,t.U_of_meas,SumOrder.Qty_sum)
		FROM (SELECT Ponum,UniqLnno,SUM(schd_qty) as Qty_sum from @tImport GROUP BY Ponum,Uniqlnno) SumOrder INNER JOIN @tImport t on
				SumOrder.Ponum=t.Ponum and SumOrder.UniqLnno=t.Uniqlnno
	--04/20/16 YS update for FC			
	-- calculate extended amount
	-- 01/24/17 VL added functional currency code
	;WITH PoTotal
	AS
	(
	SELECT PoNum,SUM(ROUND(CostEach * Schd_qty,2)) AS PoTotal,
			SUM(round(CosteachFc*Schd_qty,2)) as PoTotalFc,
			SUM(round(CosteachPR*Schd_qty,2)) as PoTotalPR
	--,SUM(ROUND((CostEach * Schd_qty * Tax_Pct)/100,2)) AS TaxTotal
	FROM @tImport
	GROUP BY Ponum
	)
	-- 01/24/17 VL added functional currency code
	UPDATE @tImport SET t.PoTotal=PoTotal.PoTotal,
				t.pototalFc=poTotal.PoTotalFc,
				t.pototalPR=poTotal.PoTotalPR
	--			t.PoTax = PoTotal.TaxTotal 
		from PoTotal INNER JOIN @tImport t ON PoTotal.Ponum=t.Ponum

	-- 01/24/17 VL added functional currency code
	UPDATE @tImport SET PoTotal=PoTotal + ShipChg,
					POTOTALfc=Pototalfc+SHIPCHGfc,
					POTOTALPR=PototalPR+SHIPCHGPR
	--				PoTax = PoTax+
	--				CASE WHEN ShipChg=0 OR ScTaxPct=0 THEN 0 ELSE ROUND((ShipChg * ScTaxPct)/100,2) END
	

	-- mSaveUploadedPO
	-- YS added PoChanges memo field
	--04/20/16 YS added fc columns
	---09/09/16 YS added PONOTE
	-- 01/24/17 VL added functional currency code
	DECLARE @Pomain TABLE (PONUM char(15),PODATE smalldatetime,POSTATUS char(8),CONUM numeric(3,0),VERDATE smalldatetime,
			BUYER char(3),APPVNAME char(8),FINALNAME char(8),POTAX numeric(10,2),POTOTAL numeric(12,2),TERMS char(15),
			CLOSDDATE smalldatetime,IS_PRINTED bit,C_LINK char(10),R_LINK char(10),I_LINK char(10),B_LINK char(10),
			SHIPCHG numeric(8,2),IS_SCTAX bit,SCTAXPCT numeric(7,4),CONFNAME char(20),CONFIRMBY char(6),SHIPCHARGE char(15),
			FOB char(15),SHIPVIA char(15),DELTIME char(8),ISINBATCH bit,RECONTODT numeric(12,2),ARCSTAT char(8),
			POPRIORITY char(10),POACKNDOC char(200),VERINIT char(8),UNIQSUPNO char(10),LFREIGHTINCLUDE bit,PoChanges varchar(max),
			PoUnique char(10),CurrChange varchar(max), Acknowledged bit,fcUsed_uniq char(10),fcHist_key char(10),PoTaxfc numeric(10,2),
			PoTotalFc numeric(18,2),ShipChgFc numeric(8,2),POnote varchar(max) default '',
			PoTaxPR numeric(10,2),PoTotalPR numeric(18,2),ShipChgPR numeric(8,2))  ;

	-- 01/24/17 VL added functional currency code
	INSERT INTO @Pomain (PONUM,PODATE,POSTATUS,CONUM,VERDATE,BUYER,APPVNAME,FINALNAME,POTAX,POTOTAL,TERMS,CLOSDDATE,
						IS_PRINTED,C_LINK,R_LINK,I_LINK,B_LINK,SHIPCHG,IS_SCTAX,SCTAXPCT,CONFNAME,CONFIRMBY,SHIPCHARGE,FOB,SHIPVIA,
						DELTIME,ISINBATCH,RECONTODT,ARCSTAT,POPRIORITY,POACKNDOC,VERINIT,UNIQSUPNO,LFREIGHTINCLUDE,
						fcUsed_uniq ,fcHist_key,PoTaxfc ,PoTotalFc,ShipChgFc,
						PoTaxPR ,PoTotalPR,ShipChgPR )
		SELECT DISTINCT PONUM,PODATE,POSTATUS,CONUM,VERDATE,BUYER,APPVNAME,FINALNAME,POTAX,POTOTAL,TERMS,CLOSDDATE,
						IS_PRINTED,C_LINK,R_LINK,I_LINK,B_LINK,SHIPCHG,IS_SCTAX,SCTAXPCT,CONFNAME,CONFIRMBY,SHIPCHARGE,FOB,SHIPVIA,
						DELTIME,ISINBATCH,RECONTODT,ARCSTAT,POPRIORITY,POACKNDOC,@desktopUserInitials,UNIQSUPNO,LFREIGHTINCLUDE,
						fcUsed_uniq ,fcHist_key,PoTaxfc ,PoTotalFc,ShipChgFc,
						PoTaxPR ,PoTotalPR,ShipChgPR
			FROM @tImport ;

	UPDATE @Pomain SET PoChanges='New PO created from '+
					CASE WHEN @upLoadModule='MRP' THEN 'MRP Action list'
					ELSE 'PO Upload' +'by User: '+RTRIM(@desktopUserInitials)+', on '+CONVERT(char,GETDATE(),120)+', PO Total: '+CONVERT(char,POTOTAL) END,
	PoUnique = dbo.fn_GenerateUniqueNumber()

	--09/09/16 YS update ponote after inserting. Cannot use as part of the insert because varchar(max) cannot be selected as part of the distinct
	update @pomain set ponote=isnull(t.ponote,'') from @timport t inner join @pomain p on t.ponum=p.ponum where t.ponote<>'' and t.PONOTE is not null


	--check for the duplicate po # one more time
	IF EXISTS(SELECT Ponum,COUNT(*) FROM @Pomain
		GROUP BY Ponum
		HAVING COUNT(*)>1)
	BEGIN
		--02/24/14 YS added stopUpload column
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Duplicate PO Header information.',1)
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
						WHEN @nReturnCode=3 THEN 5
						ELSE 2 END
		--RETURN @nReturnCode
		-- 04/10/14 YS use GOTO LABEL to alter the execution
		GOTO RETURNCODE 
	END --- EXISTS(SELECT Ponum...
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
	--04/20/16 ys added fc columns
	--- 09/09/16 YS added Note1 (item note) to the template
	-- 01/24/17 VL added functional currency code
	-- 06/01/17 VL changed costeachfc and costeachpr from numeric(15,7) to numeric(13,5)
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	DECLARE @PoItems TABLE (PONUM char(15),UNIQLNNO char(10),UNIQ_KEY char(10),ITEMNO char(3),COSTEACH numeric(13,5),
			ORD_QTY numeric(10,2),IS_TAX bit,OVERAGE numeric(5,2),POITTYPE char(9),
			L_PRINT bit,NO_PKG numeric(9,2), Part_no char(35),Revision char(8),Descript char(45),
			PARTMFGR char(8),MFGR_PT_NO char(30),PACKAGE char(15),
			Part_class char(8), Part_type char(8), U_OF_MEAS char(4),PUR_UOFM char(4),
			S_ORD_QTY numeric(10,2),ISFIRM bit,UNIQMFGRHD char(10),FIRSTARTICLE bit,INSPEXCEPT bit,
			INSPEXCEPTION char(20),INSPEXCINIT char(8), INSPEXCDT smalldatetime,INSPEXCDOC varchar(20),LCANCEL bit, uniqmfsp char(10) ,costeachfc numeric(13,5), Note1 varchar(max) default '',
			costeachPR numeric(13,5))

	
	--09/09/16 YS list all the columns in the insert
	-- 01/24/17 VL added functional currency code
	INSERT INTO @PoItems 
	(PONUM,UNIQLNNO,UNIQ_KEY,ITEMNO,COSTEACH,ORD_QTY,IS_TAX,
		OVERAGE,POITTYPE,L_PRINT,NO_PKG,
		 Part_no ,Revision ,Descript,
		 PARTMFGR,MFGR_PT_NO,PACKAGE,
		 Part_class , Part_type ,
		 U_OF_MEAS,PUR_UOFM,
		S_ORD_QTY,ISFIRM,UNIQMFGRHD,FIRSTARTICLE,INSPEXCEPT,INSPEXCEPTION,INSPEXCINIT,
		INSPEXCDT,INSPEXCDOC,LCANCEL,UniqMfsp,costeachfc,costeachPR)
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
	
	--09/09/16 YS update note1 after inserting. Cannot use as part of the insert because varchar(max) cannot be selected as part of the distinct
	update @PoItems set note1=isnull(t.note1,'') from @timport t inner join @poitems p on t.uniqlnno=p.UNIQLNNO where t.note1<>'' and t.note1 is not null

	-- update tax amount if any
	-- 01/24/17 VL added functional currency code
	-- 06/01/17 VL added code for Potax to consider ShipChg
	update @pomain set POTAX =tax.TotalTax + CASE WHEN (ShipChg = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChg*ScTaxPct/100,2) END,
	PoTaxfc = tax.TotalTaxFc + CASE WHEN (ShipChgFC = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChgFC*ScTaxPct/100,2) END,
	PoTaxPR = tax.TotalTaxPR + CASE WHEN (ShipChgPR = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChgPR*ScTaxPct/100,2) END
	from @pomain p inner join (
	select t.ponum, t.uniqlnno,ROUND(ISNULL(SUM(d.ExtAmt*t.tax_rate/100),0.00),2) as TotalTax,
		case when @FcInstalled=1 then ROUND(isnull(SUM(ExtAmtFC*Tax_rate/100),0.00),2) else 0.00 end as TotalTaxFc,
		case when @FcInstalled=1 then ROUND(isnull(SUM(ExtAmtPR*Tax_rate/100),0.00),2) else 0.00 end as TotalTaxPR
	from @poitemsTax t
	cross apply (select i.IS_TAX, i.ORD_QTY*costeach as ExtAmt,i.ORD_QTY*costeachfc as ExtAmtFc, i.ORD_QTY*costeachPR as ExtAmtPR, uniqlnno from @poitems I where i.UNIQLNNO=t.uniqlnno and I.IS_TAX=1) D
	where tax_rate<>0 and d.IS_TAX=1
	GROUP BY  t.ponum,t.uniqlnno
	) Tax on p.ponum= tax.ponum


		-- if au-to approval check if the amount allowed to be approved >= then amount in the PO 			
	If (@AutoAppr4UpLoad = 1 AND @upLoadModule<>'MRP')
	BEGIN	
		SELECT Ponum,Poittype,SUM(CostEach*Ord_qty) AS Amt
			FROM @PoItems
		WHERE Poittype<>'MRO'
		GROUP BY Ponum,PoitType
		HAVING SUM(CostEach*Ord_qty)>@ApproveINvtAmt 
		UNION 
		SELECT Ponum,Poittype,SUM(CostEach*Ord_qty) AS Amt
			FROM @PoItems
		WHERE Poittype='MRO'
		GROUP BY PONUM,PoitType
		HAVING SUM(CostEach*Ord_qty)>@ApproveMroAmt  
		IF @@ROWCOUNT <>0
		BEGIN
			INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('The total of one or more purchase orders on the upload list exceeds your approval limit.',1)
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
						ELSE 2 END
			--RETURN @nReturnCode
			-- 04/10/14 YS use GOTO LABEL to alter the execution
			GOTO RETURNCODE 

		
		END -- IF @@ROWCOUNT <>0

		
	END  -- (@AutoAppr4UpLoad = 1) 

	--select * from @pomain
	--	select * from @poitemsTax
	--	select * from @PoItems
	--	select * from @tImport 

	
	
	
	BEGIN TRANSACTION
	BEGIN TRY
		--- 04/09/14 YS added code for auto-approval if from PO upload
		--09/09/16 YS add ponote
		-- 01/24/17 VL added functional currency code
		INSERT INTO POMAIN (PONUM,PODATE,POSTATUS,CONUM,VERDATE,BUYER,APPVNAME,FINALNAME,POTAX,POTOTAL,TERMS,CLOSDDATE,
						IS_PRINTED,C_LINK,R_LINK,I_LINK,B_LINK,SHIPCHG,IS_SCTAX,SCTAXPCT,CONFNAME,CONFIRMBY,SHIPCHARGE,FOB,SHIPVIA,
						DELTIME,ISINBATCH,RECONTODT,ARCSTAT,POPRIORITY,POACKNDOC,VERINIT,UNIQSUPNO,LFREIGHTINCLUDE,PoChanges,POUNIQUE,
						fcUsed_uniq,Fchist_key,potaxfc,POTOTALFC,SHIPCHGFC,ponote,
						potaxPR,POTOTALPR,PRFcused_uniq, FuncFcused_uniq)
			SELECT PONUM,PODATE,
					CASE WHEN @upLoadModule='PO' AND @AutoAppr4UpLoad=1 THEN 'OPEN' ELSE POSTATUS END,
					CONUM,VERDATE,BUYER,
					CASE WHEN @upLoadModule='PO' AND @AutoAppr4UpLoad=1 THEN @desktopUserInitials ELSE  ' ' END ,  --- APPVNAME
					CASE WHEN @upLoadModule='PO' AND @AutoAppr4UpLoad=1 THEN @desktopUserInitials ELSE  ' ' END ,   ---Finalname
					POTAX,POTOTAL,TERMS,CLOSDDATE,
					IS_PRINTED,C_LINK,R_LINK,I_LINK,B_LINK,SHIPCHG,IS_SCTAX,SCTAXPCT,CONFNAME,CONFIRMBY,SHIPCHARGE,FOB,SHIPVIA,
					DELTIME,ISINBATCH,RECONTODT,ARCSTAT,POPRIORITY,POACKNDOC,VERINIT,UNIQSUPNO,LFREIGHTINCLUDE,PoChanges,POUNIQUE,
					fcUsed_uniq,Fchist_key,potaxfc,POTOTALFC,SHIPCHGFC,ponote,
					potaxPR,POTOTALPR,dbo.fn_GetPresentationCurrency() AS PRFcused_uniq, dbo.fn_GetFunctionalCurrency() AS FuncFcused_uniq
			FROM @Pomain
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
		-- 07/01/16 YS return using GOTO label from the catch block, instead of using return -1
		--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
				WHEN @nReturnCode=3 THEN 5
				ELSE 2 END
			GOTO RETURNCODE 
	END CATCH
	BEGIN TRY
	-- 09/09/16 ys added note1
	-- 01/24/17 VL added functional currency code
		INSERT INTO POITEMS (PONUM,UNIQLNNO,UNIQ_KEY,ITEMNO,COSTEACH,ORD_QTY,IS_TAX,
				OVERAGE,POITTYPE,L_PRINT,NO_PKG,
				PART_NO,REVISION ,DESCRIPT ,
				PARTMFGR,MFGR_PT_NO,PACKAGE,
				PART_CLASS ,PART_TYPE,U_OF_MEAS,PUR_UOFM,
				S_ORD_QTY,ISFIRM,UNIQMFGRHD,FIRSTARTICLE,INSPEXCEPT,INSPEXCEPTION,INSPEXCINIT,
				INSPEXCDT,INSPEXCDOC,LCANCEL,UniqMfsp,costeachfc,note1, costeachPR )
		SELECT PONUM,UNIQLNNO,UNIQ_KEY,ITEMNO,COSTEACH,ORD_QTY,IS_TAX,
			OVERAGE,POITTYPE,L_PRINT,NO_PKG,
			PART_NO,REVISION ,DESCRIPT ,
			PARTMFGR,MFGR_PT_NO,PACKAGE,
			PART_CLASS ,PART_TYPE,U_OF_MEAS,PUR_UOFM,
			S_ORD_QTY,ISFIRM,UNIQMFGRHD,FIRSTARTICLE,INSPEXCEPT,INSPEXCEPTION,INSPEXCINIT,
			INSPEXCDT,INSPEXCDOC,LCANCEL,UniqMfsp,costeachfc,note1, costeachPR
		FROM @poitems
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
			-- 07/01/16 YS return using GOTO label from the catch block, instead of using return -1
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
				WHEN @nReturnCode=3 THEN 5
				ELSE 2 END
			GOTO RETURNCODE 
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
			-- 07/01/16 YS return using GOTO label from the catch block, instead of using return -1
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
				WHEN @nReturnCode=3 THEN 5
				ELSE 2 END
			GOTO RETURNCODE 
	END CATCH
	BEGIN TRY
		INSERT INTO Poitschd (UNIQLNNO,UniqDetno,SCHD_DATE,REQ_DATE,
			Schd_qty,RecdQty, BALANCE,GL_NBR,REQUESTTP,REQUESTOR,
			UNIQWH,LOCATION,WOPRJNUMBER,COMPLETEDT,PONUM,ORIGCOMMITDT)
			SELECT UNIQLNNO,UniqDetno,SCHD_DATE,REQ_DATE,
				Schd_qty,RecdQty, BALANCE,GL_NBR,REQUESTTP,REQUESTOR,
				UNIQWH,LOCATION,WOPRJNUMBER,COMPLETEDT,PONUM,ORIGCOMMITDT
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
			VALUES ('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
			'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
			'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
			'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
			'Error Message: '+@ERRORMESSAGE)
			-- 07/01/16 YS return using GOTO label from the catch block, instead of using return -1
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
				WHEN @nReturnCode=3 THEN 5
				ELSE 2 END
			GOTO RETURNCODE 
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
			-- 07/01/16 YS return using GOTO label from the catch block, instead of using return -1
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
				WHEN @nReturnCode=3 THEN 5
				ELSE 2 END
			GOTO RETURNCODE 
	END CATCH

	--04/09/14 YS check if called by MRP module
	IF (@upLoadModule='MRP')
	BEGIN
		BEGIN TRY
			UPDATE MRPACT SET POUNIQLNNO = U.Uniqlnno FROM @tImport U WHERE U.UniqMrpAct=MrpAct.UNIQMRPACT and U.UniqLnno<>' '
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
			set @lValid =0
			-- 07/01/16 YS return using GOTO label from the catch block, instead of using return -1
			--02/27/14 YS added @nReturnCode=3 to indicate that there were some codes replaced with empty string
			set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
				WHEN @nReturnCode=3 THEN 5
				ELSE 2 END
			GOTO RETURNCODE 
		END CATCH
	END  -- IF (@upLoadModule='MRP')
	IF @@TRANCOUNT>0
		COMMIT TRANSACTION
	
	-- 04/10/14 YS use GOTO LABEL to alter the execution
	GOTO RETURNCODE 
		
	---03/09/14 YS return sqlresult instead of return a code (having issue with XP machine for some reason)
	-- 04/10/14 YS use GOTO LABEL to alter the execution
	-- define LABEL 
	RETURNCODE: 
	SELECT @nReturnCode as ReturnCode
	
END