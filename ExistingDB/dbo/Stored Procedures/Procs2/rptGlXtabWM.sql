
-- =============================================
-- Author:		Debbie
-- Create date: 08/08/2012
-- Description:	Created for the Detailed Cross-tabbed Report
-- Reports Using Stored Procedure:  glxtab4.rpt / glxtab5.rpt
-- Modifications:	09/21/2012 DRP:  through testing it was found that the report was not properly pulling records fwd if it happen that the particular GL nbr had never had transactions against it before
--					09/26/2012 YS:	Yelena found that there were some changes that could be made to my original code to make it faster (particularly for larger data sets.) 
--									We replaced code where I was using Group By with the Select Distinct, the way that the Beginning Balance was calculated was also modified and where we had the most time saving.
--					04/15/2013 DRP:  it was reported that for new inventory transfer transactions created in SQL that the X-tab reports were displaying the source as no back link found.  
--									upon review of the code and data files it was found that VFP was recording the TransactionType as "INVTTRANS" and new records in SQL were recording "INVTTRNS"
--									the original code was only looking for transactiontype of INVTTRANS and that is why it could not find the back link for new SQL records.  Below has been changed to look for only "INVTTRNS". 
--					12/19/2013 DRP: requested for inventory issues that we added the Work Order # into the reference.
--					11/07/2014 DRP: found that the TransDescr field was not large enough in some cases and increased it from <<TransDescr varchar(100)>> to <<TransDescr varchar(110)>>
--					02/19/2015 DRP: copied this over for the Clound Version.  Added the /*GL NUMBER LIST*/ and filter criteria for it. Added the SaveInit.
--					12/04/2015 DRP: added <<,RunningTotal =  BegBal + sum(debit-credit) over (partition by gl_nbr order by trans_dt range unbounded preceding) >> to the select statement at the end. 
--					09/15/16 DRRP:  updated the TransDescr to char (200), then added the invoice # to the AP Check section so that it will display the Invoice number as extra reference.
--					09/30/16 DRP:	 it was found that if the check records were generated for example from auto bank deductions where no supplier was associated with the apchkmst record that the GenrRef would then just return NULL as soon as it could not find a matching supplier      
--					11/23/16 DRP:	added isnull(TransDescr,'Cannot link back to Source') as TransDescr to the last select statement so when the code is unable to link back to the source we will display that in the results. 
--				    01/05/2017 VL:  added functional currency fields
---					07/27/17 YS Need a sequence number for proper calculation of the running total	
-- 09/27/17 VL fixed BegBalPR which took begbal incorrectly, should be begbalPR
-- 06/21/19 VL added all missing code 04/17/18-05/14/18
-- 04/17/18 DRP:  per request all of the different detailed information that was displayed within the TransDescr was broken out into individual columns.  This was to hopefully make it easier for the end users to dump the information to XLS format and do their own sorting/investigating 
--				on transactions records themselves.  Keep in mind that all of these individual fields will display in the quickview, but the end users do have the ability to hide them if desired. 
--				added the following columns to the end results **ponum,supname,invno,custname,je_no,reason,checkno,bk_acct_no,cmemono ,wono ,part_no,revision,descript,qty,OLDMATLCST,newmatlcst,dmemono,whse,cost,rec_advice,receiverno,conum,itemno,origtablesaveinit**
-- 04/25/18 VL added nsequence column, so in Stimulsoft report, it will sort gl_nbr, trans_dt, trans_no plus nsequence, to show correct running total at the end
-- 05/14/18 VL added supname for PURVAR, request by CM solutions #1980
-- 06/21/19 VL added 3 temp tables to speed up
-- 10/11/19 VL changed part_no from char(25) to char(35)
-- 12/06/19 VL changed back to use table to calculate BegBal, not the temp table which only contains the data for selected date range, need to find data before current date range
-- 04/03/20 VL Added FUNC fields to the temp tables
-- =============================================
CREATE PROCEDURE [dbo].[rptGlXtabWM]

--declare
		 @lcGlNbr as varchar(max) = 'All'
		,@lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		,@userId uniqueidentifier= null
		
		
as
begin

/*GL NUMBER LIST*/
DECLARE  @tGLNumber as table(gl_nbr char(13))
	declare @GLNumber as table (gl_nbr char(13))
insert into @tGLNumber select gl_nbr from gl_nbrs

		IF @lcGlNbr is not null and @lcGlNbr <>'' and @lcGlNbr<>'All'
			insert into @GLNumber select * from dbo.[fn_simpleVarcharlistToTable](@lcGlNbr,',')
					where CAST (id as CHAR(13)) in (select gl_nbr from @tGLNumber)
		ELSE
		IF  @lcGlNbr='All'	
		BEGIN
			INSERT INTO @GLNumber SELECT gl_nbr FROM @tGLNumber
		END

-- 06/21/19 VL added 3 temp tables and get smaller data to use so speed up
-- 04/03/20 VL Added FUNC fields to the temp tables
CREATE TABLE #GetGLTransHeader (GlTransUnique char(10), TransactionType varchar(50), SourceTable varchar(25), cIdentifier char(30), Post_date smalldatetime,
								Trans_no int, Trans_dt smalldatetime, Period numeric(2,0), Fy char(4), Saveinit char(8), fk_fydtluniq char(36), FuncFCUsed_uniq char(10), PRFCUsed_uniq char(10), saveUserId uniqueidentifier )
CREATE TABLE #GetGlTrans (GlUniq_key char(10), Gl_nbr char(13), Debit numeric(14,2), Credit numeric(14,2), cIdentifier char(30), SourceTable varchar(25),
								SourceSubTable varchar(25), cSubIdentifier char(30), Fk_GlTransUnique char(10), DebitPR numeric(14,2), CreditPR numeric(14,2))
CREATE TABLE #GetGlTransDetails (fk_Gluniq_key char(10), cDrill varchar(50), cSubDrill varchar(50), Debit numeric(14,2), Credit numeric(14,2),
									GlTransDUnique char(36), TrGroupIdNumber int, TransactionType varchar(50), DebitPR numeric(14,2), CreditPR numeric(14,2))
CREATE NONCLUSTERED INDEX Fy ON #GetGlTransHeader (Fy)
CREATE NONCLUSTERED INDEX Period ON #GetGlTransHeader (Period)
CREATE NONCLUSTERED INDEX GlTransUnique ON #GetGlTrans (Fk_GLTRansUnique)
CREATE NONCLUSTERED INDEX Gl_nbr ON #GetGlTrans (Gl_nbr)
CREATE NONCLUSTERED INDEX GlUniq_key ON #GetGlTrans (GlUniq_key)
CREATE NONCLUSTERED INDEX Fk_Gluniq_key ON #GetGlTransDetails (Fk_GlUniq_key)

INSERT #GetGLTransHeader 
	SELECT * 
		FROM GLTRANSHEADER
		WHERE GLTRANSHEADER.trans_dt>=@lcDateStart AND GLTRANSHEADER.TRANS_DT<@lcDateEnd+1

INSERT #GetGlTrans 
	SELECT * 
		FROM GLTrans
		WHERE EXISTS (SELECT 1 FROM #GetGlTransHeader WHERE GlTransUnique = GlTrans.Fk_GLTRansUnique)
		AND EXISTS (SELECT 1 FROM @GLNumber G1 where g1.gl_nbr=GLTRANS.GL_NBR)
	
INSERT #GetGlTransDetails
	SELECT *
		FROM GlTransDetails
		WHERE EXISTS (SELECT 1 FROM #GetGlTrans WHERE GlUniq_key = GlTransDetails.fk_gluniq_key)
-- 06/21/19 VL End}

-- 01/05/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	/*SELECT STATEMENT SECTION*/
	---	07/27/17 YS Need a sequence number for proper calculation of the running total
	--- 04/17/18 DRP:  added individual columns at the end that breaks out the TransDescr detail
	-- 07/11/18 VL Changed Supname from char(30) to char(35)
	-- 10/11/19 VL changed part_no from char(25) to char(35)
	declare @glxtab as table	(FY char (4),Period numeric (2),Trans_no int,TransactionType varchar(50),Post_Date smalldatetime,Trans_Dt smalldatetime
								,gl_nbr char(13),GL_Descr char (30),Debit numeric(14,2),Credit numeric (14,2),SourceTable varchar(25),Cidentifier char(30),cDrill varchar(50)
								,SourceSubTable varchar(25),cSubIdentifier char(30),cSubDrill varchar (50), TransDescr varchar(200),BegBal numeric(14,2),Reference varchar(max),
								saveinit char(8),nsequence int
								,ponum varchar(15),supname varchar(35),invno varchar(100),custname char(35),je_no varchar (6),reason varchar (100),checkno char(10),bk_acct_no char(15)
								,cmemono char(10),wono char(10),part_no char(35),revision char(8),descript char(45),qty numeric(12,2),OLDMATLCST numeric(12,2),newmatlcst numeric(12,2)
								,dmemono char(10),whse char(6),cost numeric(12,5),rec_advice char(10),receiverno char(10),conum numeric(3),itemno char(3),OrigTablesaveinit char(8))
														
							
	Insert @glxtab
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case 
				WHEN gltransheader.TransactionType = 'APPREPAY' THEn(SELECT CAST('AP Offset against Prepay: '+RTRIM(apmaster.ponum)  as varchar(100)) 
					FROM apmaster
					where apmaster.UNIQAPHEAD = RTRIM(GlTransDetails.cSubDrill))
				WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'UniqueAr' THEN 
					(SELECT distinct CAST(CASE WHEN Acctsrec.lPrepay=1 THEN  'AR Offset using Prepay: '+ RTRIM(ACCTSREC.invno) 
					ELSE 'AR Offset against Prepay: '+ RTRIM(ACCTSREC.invno) END  as varchar(100))
					from AROFFSET,ACCTSREC 
					where aroffset.CTRANSACTION = RTRIM(gltransdetails.cdrill) and acctsrec.uniquear = rtrim(gltransdetails.csubdrill))
				WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'CTRANSACTION' THEN (SELECT CAST(rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim(cDrill) as varchar(100)))

				when gltransheader.TransactionType = 'ARWO'  then (select CAST('Cust: '+rtrim(customer.custname)+'  Inv#: '+acctsrec.INVNO as varchar(100)) 
					from AR_WO
					INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR
					INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					where AR_WO.ARWOUNIQUE =RTRIM(gltransdetails.CDRILL)) 
				WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill 
					THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST('Check#: '+RTRIM(apchkmst.checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  *No Supplier Assigned' as varchar(200))
							else CAST('Supplier: '+rtrim(supinfo.supname)+'  '+'Check Number: '+apchkmst.checkno +'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)  as varchar(200)) end	
						FROM APCHKMST
						left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
						INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
						WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
				WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  
					THEN (SELECT CAST('Check#: '+RTRIM(apchkmst.checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+ isnull(rtrim(supinfo.supname),'')+ ' Invoice # '+ISNULL(Apmaster.Invno,Item_desc) as varchar(200))	--09/15/16 DRP:  added the Invoice # as extra detail
						FROM APCHKMST
						left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
						INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
						inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	--09/15/16 DRP:  added the apchkdet and apmaster tables in order to get the invoice # as reference
						left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead
						 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL)
						 and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
				--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Check#: '+RTRIM(apchkmst.checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  Supp: '+rtrim(supinfo.supname)+' Invoice #'+ISNULL(Apmaster.Invno,space(20)) as varchar(200))	--09/30/16 DRP:  	
				--	FROM APCHKMST
				--	INNER JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
				--	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
				--	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	--09/15/16 DRP:  added the apchkdet and apmaster tables in order to get the invoice # as reference
				--	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead
				--	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL)
				--	 and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
				when gltransheader.TransactionType = 'CM'  then (select cast('Customer: ' +RTRIM(CustName)+', Credit Memo: '+ rtrim(cmemono) as CHAR (80))
					from cmmain 
					inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)
				WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST('WO#: '+Confgvar.wono+'  Date: '+ cast(cast(confgvar.datetime as DATE)as varchar(10))+' Part/Rev: '+rtrim(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty Trns: '+ cast(CAST(qtytransf as numeric(12,0))as varchar(12)) as varchar(100)) 
					FROm CONFGVAR 
					inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY
					where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
				when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST('PN/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+ '  QtyOH: '+ rtrim(updtstd.QTY_OH)+'  Old: '+rtrim(updtstd.OLDMATLCST)+'  New: '+RTRIM(updtstd.newmatlcst) as varchar(80))
					FROM UPDTSTD
					inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY
					where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
				WHEN gltransheader.TransactionType = 'DEP' then (select cast('Deposit Number: ' + rtrim(cDrill)+'  Bank Acct# '+RTRIM(deposits.bk_acct_no)  as varchar (100))	
					from DEPOSITS
					where deposits.DEP_NO = RTRIM(gltransdetails.cdrill))
				WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(Dmemono)+'  Supp: '+rtrim(supname)+', '+CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END+ '  Against Inv' as varchar(100)) 
					when dmemos.dmtype = 2 then cast (RTRIM(dmemono)+'  Supp: '+ rtrim(supname)+','+  CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END + '  Against Acct' as varchar(100)) end 
					FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  
					WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
				WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'PO#: '+confgvar.ponum+'  Qty: '+cast(CAST(confgvar.QTYTRANSF as numeric(12,0))as varchar(12)) as varchar(100)) 
					else cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'WO#: '+confgvar.wono+'  Qty: '+ cast(CAST(confgvar.QTYTRANSF as numeric(12,0))as varchar(12)) as varchar (100))end 
					FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
	--12/19/2013 DRP: when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST ('PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) as varchar (100))
				when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (case when wono = '' then '' else 'WO:'+ WONO end +' PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) as varchar (100))
					FROm Invt_ISU
					inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY
					inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY
					inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
					where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
				WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST('PN/Rev: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(invt_rec.qtyrec)+'  Cost: '+RTRIM(invt_rec.stdcost) as varchar (100)) 
					FROm Invt_rec
					inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY
					inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY
					inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
					where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
	--			04/15/2013 DRP: needed to look for INVTTRNS in SQL
				--when gltransheader.TransactionType = 'INVTTRANS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) as varchar (100))
				when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) as varchar (100))
					FROM INVTTRNS
					INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY
					WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
				WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(rtrim(gljehdr.JETYPE)+' JE# '+cast(rtrim(gljehdr.JE_NO) as char (6))+'  Reason: '+RTRIM(GLJEHDR.REASON) as varCHAR (100)) 
					FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST('WO#: '+RTRIM(MFGRVAR.WONO)+'  Date:'+cast(cast(mfgrvar.datetime as DATE)as varchar(10))+'  Part/Rev: '+rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+' Desc: '+RTRIM(inventor.descript) as varchar(100)) 
					FROm MFGRVAR,INVENTOR
					where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)
					and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
				when gltransheader.TransactionType = 'NSF' then (select 'NSF: '+cast(RTRIM(cdrill) + ' for Dep#: ' + rtrim(ARRETCK.DEP_NO)+'  Receipt Advice: '+RTRIM(arretck.rec_advice)+'  Cust: '+RTRIM(custname)  as varchar(100)) 
					from ARRETCK
					inner join CUSTOMER on arretck.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = arretck.UNIQRETNO) 
				WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(' Inv#: '+rtrim(apmaster.invno)+'  PO#: '+rtrim(apmaster.ponum)+ '  Supp: '+RTRIM(Supname)  as varchar(100)) 
					FROM Apmaster 
					inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 
					where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
				WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST('Recv#: '+rtrim(Sinvoice.receiverno)+'  '+'Inv#: '+rtrim(sinvoice.INVNO)+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) as varchar(100)) 
					FROM pur_var
					inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ
					inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ
					inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO
					inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
					where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
				WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))

				WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(100)) 
					FROM Plmain 
					inner join Customer on Plmain.custno = customer.CUSTNO 
					where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('WO#: '+SCRAPREL.wono+'  Date: '+ cast(cast(SCRAPREL.datetime as DATE)as varchar(10))+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+cast(CAST(scraprel.QTYTRANSF as numeric(12,0))as varchar(12))+'  Cost: '+cast(scraprel.stdcost as varchar(17)) as varchar(100)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST('Recv# '+Porecloc.RECEIVERNO+'  '+'PO# '+RTRIM(poitems.ponum)+'  CO# '+RTRIM(pomain.conum)+'  Item# '+RTRIM(poitems.ITEMNO)+'  Supp:'+RTRIM(supinfo.supname)  as varchar(100)) 
					FROM porecrelgl 
					INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 
					inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL
					inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno
					inner join POMAIN on poitems.PONUM = pomain.ponum
					inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
					where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
				ELSE CAST('Cannot Link back to source' as varchar(100))
				end as GenrRef
				,ISNULL(b.begbal,0.00) as BegBal,' ',SAVEINIT 	,
				---	07/27/17 YS Need a sequence number for proper calculation of the running total
			row_number() OVER (partition by gltrans.gl_nbr order by trans_dt,trans_no) as nSequence 	
	-- 09/21/2012 DRP:  Made changes to the BegBal to cast it as numeric and added the insull  
--- 04/17/18 DRP:  added individual columns at the end that breaks out the TransDescr detail

			/*ponum*/,case WHEN gltransheader.TransactionType = 'APPREPAY' THEn(SELECT CAST(RTRIM(apmaster.ponum)  as varchar(15)) FROM apmaster where apmaster.UNIQAPHEAD = RTRIM(GlTransDetails.cSubDrill))
			WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE RTRIM(DMEMOS.PONUM)END as varchar(15)) 
			when dmemos.dmtype = 2 then cast (CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END as varchar(15)) end FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (confgvar.ponum as varchar(15)) else cast ('' as varchar(15)) end FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(rtrim(apmaster.ponum)as varchar(15)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
			when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(poitems.ponum)as varchar(15)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno inner join POMAIN on poitems.PONUM = pomain.ponum inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST('' as varchar(15)) end as ponum

			/*supplier*/,case WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST('*No Supplier Assigned' as varchar(30)) else CAST(rtrim(supinfo.supname)  as varchar(30)) end FROM APCHKMST left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  THEN (SELECT CAST(isnull(rtrim(supinfo.supname),'') as varchar(30)) FROM APCHKMST left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(supname) as varchar(30)) when dmemos.dmtype = 2 then cast (rtrim(supname) as varchar(30)) end FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(RTRIM(Supname)  as varchar(30)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
			when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(supinfo.supname)  as varchar(30)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno inner join POMAIN on poitems.PONUM = pomain.ponum inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			-- 05/14/18 VL added supname for PURVAR, request by CM solutions #1980
			when gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(RTRIM(supinfo.supname)  as varchar(30)) FROM pur_var inner join Apmaster on Pur_Var.fk_UniqApHead = Apmaster.UniqAphead inner join supinfo on Apmaster.UNIQSUPNO = Supinfo.UNIQSUPNO where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			ELSE CAST('' as varchar(30)) end as supname
			/*invno*/,case WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'UniqueAr' THEN (SELECT distinct CAST(CASE WHEN Acctsrec.lPrepay=1 THEN  RTRIM(ACCTSREC.invno) ELSE RTRIM(ACCTSREC.invno) END  as varchar(100))	from AROFFSET,ACCTSREC 	where aroffset.CTRANSACTION = RTRIM(gltransdetails.cdrill) and acctsrec.uniquear = rtrim(gltransdetails.csubdrill))
			when gltransheader.TransactionType = 'ARWO'  then (select CAST(acctsrec.INVNO as varchar(100))from AR_WO	INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR	INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO where AR_WO.ARWOUNIQUE =RTRIM(gltransdetails.CDRILL)) 
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  THEN (SELECT CAST(ISNULL(Apmaster.Invno,Item_desc) as varchar(100))	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(rtrim(apmaster.invno)  as varchar(100)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
			WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(rtrim(sinvoice.INVNO) as varchar(100)) FROM pur_var	inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ	inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST(InvoiceNo as varchar(100)) FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
			ELSE CAST('' as varchar(100)) end as invno
			/*custname*/,case when gltransheader.TransactionType = 'ARWO'  then (select CAST(rtrim(customer.custname) as varchar(35))	from AR_WO	INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR	INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO	where AR_WO.ARWOUNIQUE =RTRIM(gltransdetails.CDRILL)) 
			when gltransheader.TransactionType = 'CM'  then (select cast(RTRIM(CustName)as CHAR (35)) from cmmain 	inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique) 			
			when gltransheader.TransactionType = 'NSF' then (select cast(RTRIM(custname)  as varchar(35)) from ARRETCK	inner join CUSTOMER on arretck.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = arretck.UNIQRETNO) 	
			WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST(RTRIM(CustName) as varchar(35))	FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO 	where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
			ELSE CAST('' as varchar(35))end as custname
			/*je_no*/,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(cast(rtrim(gljehdr.JE_NO) as char (6)) as varCHAR (6))  FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
			ELSE CAST('' as varchar(6)) end as je_no
			/*reason*/,case	when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON) as varchar (100))	FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(RTRIM(GLJEHDR.REASON) as varCHAR (100))	FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)		
			ELSE CAST('' as varchar(100)) end as reason
			/*checkno*/,case WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST(RTRIM(apchkmst.checkno) as varchar(10))	else CAST(apchkmst.checkno as varchar(10)) end	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  THEN (SELECT CAST(RTRIM(apchkmst.checkno) as varchar(10))	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			ELSE CAST('' as varchar(10)) end as checkno
			/*bank_acct_no*/,case WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST(RTRIM(BANKS.BK_ACCT_NO) as char(15)) else CAST(RTRIM(BANKS.BK_ACCT_NO)  as char(15)) end	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill THEN (SELECT CAST(RTRIM(BANKS.BK_ACCT_NO) as char(15))FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			WHEN gltransheader.TransactionType = 'DEP' then (select cast(RTRIM(deposits.bk_acct_no)  as char (15)) from DEPOSITS	where deposits.DEP_NO = RTRIM(gltransdetails.cdrill))
			ELSE CAST('' as varchar(15)) end as bk_acct_no

			/*dep_no*/  --did not break out the dep_no records because those are the unique keys that are already available in the drills
			/*cmemono*/,case when gltransheader.TransactionType = 'CM'  then (select cast(rtrim(cmemono) as CHAR (10)) from cmmain 	inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)	
			ELSE CAST('' as varchar(10)) end as cmemono
			/*wono*/,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST(Confgvar.wono as char(10)) FROm CONFGVAR 	inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast ('' as char(10)) else cast (confgvar.wono as char (10))end FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (case when wono = '' then '' else  WONO end  as char (10)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(RTRIM(MFGRVAR.WONO) as char(10)) FROm MFGRVAR,INVENTOR	where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL) and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST(mfgrvar.WONO  as varchar(10)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(SCRAPREL.wono as char(10))  FROM SCRAPREL,INVENTOR where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)	and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST('' as varchar(10)) end as wono
			-- 10/11/19 VL changed part_no from char(25) to char(35)
			/*part_no*/,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST(rtrim(inventor.part_no) as char(35)) FROm CONFGVAR inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))			
			when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(RTRIM(inventor.part_no) as char(35)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no) as varchar(35)) else cast (rtrim(inventor.part_no) as char (35))end FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (case when wono = '' then '' else RTRIM(inventor.part_no) end as varchar (35)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(RTRIM(inventor.part_no) as varchar (35)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST ( rTRIM(inventor.part_no) as varchar (35)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(rtrim(inventor.part_no) as varchar(35)) FROm MFGRVAR,INVENTOR	where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)	and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(RTRIM(inventor.part_no) as varchar(35)) FROM pur_var inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ	inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(RTRIM(inventor.part_no)as varchar(35)) FROM SCRAPREL,INVENTOR where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL) and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST('' as varchar(35)) end as part_no
			/*revision*/,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST(RTRIM(inventor.revision) as varchar(8))	FROm CONFGVAR inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY	where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
			when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(RTRIM(inventor.revision) as varchar(8)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.revision)as varchar(8)) else cast (rtrim(inventor.revision)as varchar (8))end FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (case when wono = '' then '' else RTRIM(inventor.revision) end as varchar (8)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(RTRIM(inventor.revision) as varchar (8)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (RTRIM(inventor.revision) as varchar (8)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill)) 
			WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(rtrim(inventor.revision) as varchar(8)) FROm MFGRVAR,INVENTOR where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL) and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(RTRIM(inventor.revision) as varchar(8)) FROM pur_var	inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ	inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(RTRIM(inventor.revision) as varchar(8)) FROM SCRAPREL,INVENTOR	where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)	and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST('' as char(8)) end as revision
			/*descr*/,case WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(RTRIM(inventor.descript) as char(45)) FROm MFGRVAR,INVENTOR where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)	and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			ELSE CAST('' as char(45)) end as descript
			/*qty*/,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST(qtytransf as numeric(12,2)) FROm CONFGVAR 	inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY	where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
			when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.QTY_OH as numeric(12,2))	FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (confgvar.QTYTRANSF as numeric(12,2)) 	else cast (confgvar.QTYTRANSF as numeric(12,2))end 	FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (INVT_ISU.QTYISU as numeric(12,2))	FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(invt_rec.qtyrec as numeric(12,2))	FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (invtTRNS.QTYXFER as numeric(12,2))	FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(scraprel.QTYTRANSF as numeric(12,2))	FROM SCRAPREL,INVENTOR	where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)	and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE null end as qty
			/*OLDMATLCST*/,case when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.OLDMATLCST as numeric (12,2)) FROM UPDTSTD inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill)) 
			ELSE null end as oldmatlcst
			/*newmatlcst*/,case when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.newmatlcst as numeric(12,2)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			ELSE null end as newmatlcst
			/*dmemono*/,case WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(Dmemono) as char(10)) when dmemos.dmtype = 2 then cast (RTRIM(dmemono)as char(10)) end 	FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))	
			ELSE CAST('' as char(10)) end as dmemono
			/*whse*/,case when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (RTRIM(warehous.WAREHOUSE) as char (6)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(RTRIM(warehous.WAREHOUSE) as char (6)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			ELSE CAST('' as char(6)) end as whse
			/*cost*/,case when gltransheader.TransactionType = 'INVTISU' THEN (SELECT cast(invt_ISU.stdcost as numeric(12,5)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT cast(invt_rec.stdcost as numeric(12,5)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST(INVTTRNS.stdcost as numeric (12,5)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(scraprel.stdcost as numeric(12,5)) FROM SCRAPREL,INVENTOR where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL) and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST(null as numeric(12,5)) end as cost
			/*rec_advice*/,case when gltransheader.TransactionType = 'NSF' then (select cast(RTRIM(arretck.rec_advice)as char(10)) from ARRETCK	inner join CUSTOMER on arretck.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = arretck.UNIQRETNO) 
			ELSE CAST('' as char(10)) end as rec_advice
			/*receiverno*/,case	WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(rtrim(Sinvoice.receiverno)as char(10)) FROM pur_var	inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(rtrim(Porecloc.RECEIVERNO) as char(10)) FROM porecrelgl 	INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 	inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL	inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno	inner join POMAIN on poitems.PONUM = pomain.ponum	inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST('' as char(10)) end as receiverno
			/*conum*/,case when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(pomain.conum) as numeric(3,0)) 	FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 	inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL	inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno	inner join POMAIN on poitems.PONUM = pomain.ponum	inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST(null as numeric(3)) end as conum
			/*itemno*/,case when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(POITEMS.itemno) as char(3)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 	inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL	inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno	inner join POMAIN on poitems.PONUM = pomain.ponum	inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST('' as char(3)) end as itemno
			/*saveinit*/,case WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST(apchkmst.saveinit as char(8))	else cast(apchkmst.saveinit as char(8)) end	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill THEN (SELECT CAST(apchkmst.saveinit as char(8))	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			when gltransheader.TransactionType = 'CM'  then (select cast(cmmain.saveinit as char(8)) from cmmain inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)
			WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(dmemos.saveinit as char(8)) when dmemos.dmtype = 2 then cast (dmemos.saveinit as char(8)) end FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  	WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(gljehdr.saveinit as char(8)) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
			WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST(plmain.SAVEINIT as char(8))	FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO 	where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
			WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(sinvoice.SAVEINIT as char(8)) FROM pur_var inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ	inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(invt_rec.SAVEINIT as char(8))	FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (invt_isu.SAVEINIT as char(8))	FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (INVTTRNS.SAVEINIT as char(8)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(porecrelgl.TRANSINIT as char(8)) FROM porecrelgl 	INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 	inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL	inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno	inner join POMAIN on poitems.PONUM = pomain.ponum	inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.INIT as char(8)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(scraprel.INITIALS as char(8)) FROM SCRAPREL,INVENTOR	where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL) and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(mfgrvar.INITIALS as char(8))	FROm MFGRVAR,INVENTOR	where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL) and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'APPREPAY' THEn(SELECT CAST(apmaster.INIT as char(8)) FROM apmaster where apmaster.UNIQAPHEAD = RTRIM(GlTransDetails.cSubDrill))
			WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(apmaster.init as char(8)) FROM Apmaster 	inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 	where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL)) 
			WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST(MFGRVAR.INITIALS as char(8)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
			ELSE CAST('' as char(8)) end as OrigTablesaveinit

---04/17/18 DRP:  end of individual column add

-- 06/21/19 VL changed to use 3 new temp tables
	FROM	#GetGlTransheader GLTRANSHEADER  
			inner join #GetGlTrans gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join #GetGlTransDetails GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
	--	09/26/2012 DRP:  removed the below code that was slowing the results when calculating the Beginning Balance
			left outer JOIN (select	G.GL_NBR,SUM(g.debit-g.Credit) as BegBal
	--09/21/2012 DRP:  had to change the above join to left outer join in order to get the correct BegBal of 0.00 even if the GL Nbr had never been used before.
			-- 12/06/19 VL changed back to use table to calculate BegBal, not the temp table which only contains the data for selected date range, need to find data before current date range
			FROM	GLTRANSHEADER GH2
					inner join Gltrans G on GH2.GLTRANSUNIQUE =G.Fk_GLTRansUnique 
			where GH2.TRANS_DT < @lcDateStart
					group by g.GL_NBR) B ON b.gl_nbr=gltrans.gl_nbr

---- 06/21/19 VL comment out the criteria, already use when creating 3 temp tables
	--where	1 = case when gltrans.GL_NBR in (select gl_nbr from @GLNumber ) then 1 else 0 end	
	--		and GLTRANSHEADER.trans_dt>=@lcDateStart AND GLTRANSHEADER.TRANS_DT<@lcDateEnd+1
	--07/27/17 YS no need to order here, this is not your end result		
	--order by trans_no

	-- 09/26/2012 DRP:  UPdate the table with the license information
		--update @glxtab SET LIC_NAME=Micssys.LIC_NAME FROM MICSSYS
	-- 09/26/2012 DRP:  update the reference information for PURCH types
		update @glxtab SET Reference = CASE WHEN TransactionType='PURCH' THEN isnull(dbo.FnGlXtabRef(cDrill),'') else '' end 


	select	post_date,Trans_no,Trans_dt,period,Fy,gl_nbr,TransactionType,isnull(TransDescr,'Cannot link back to Source') as TransDescr,debit,credit,saveinit,GL_Descr,BegBal,Reference	--11/23/16 DRP:  changed the TransDescr to be isnull(TransDescr,'Cannot link back to Source')
			,RunningTotal =  BegBal + sum(debit-credit) 
			---over (partition by gl_nbr order by trans_dt range unbounded preceding)	--12/04/15 DRP:  added
			over(partition by gl_nbr order by  nsequence  range unbounded preceding)     ---07/27/17 YS Need a sequence number for proper calculation of the running total
			,SourceTable,Cidentifier,cDrill,SourceSubTable,cSubIdentifier,cSubDrill 
		,supname,custname,invno,ponum,conum,itemno,je_no,reason,checkno,bk_acct_no,cmemono,wono,part_no,revision,descript,qty,OLDMATLCST,newmatlcst,dmemono,whse,cost,rec_advice,receiverno,OrigTablesaveinit	---04/17/18 DRP:  added individual columns
		-- 04/25/18 VL added nsequence column, so in Stimulsoft report, it will sort gl_nbr, trans_dt, trans_no plus nsequence, to show correct running total at the end
		,nSequence
	from	@glxtab 
	order by gl_nbr,Trans_Dt,trans_no
	END
ELSE
	BEGIN
	/*SELECT STATEMENT SECTION*/
	-- 01/05/2017 VL: added functional currency fields
	declare @glxtabFC as table	(FY char (4),Period numeric (2),Trans_no int,TransactionType varchar(50),Post_Date smalldatetime,Trans_Dt smalldatetime
								,gl_nbr char(13),GL_Descr char (30),Debit numeric(14,2),Credit numeric (14,2),SourceTable varchar(25),Cidentifier char(30),cDrill varchar(50)
								,SourceSubTable varchar(25),cSubIdentifier char(30),cSubDrill varchar (50), TransDescr varchar(200),BegBal numeric(14,2),Reference varchar(max),saveinit char(8)
								-- 01/05/2017 VL: added functional currency fields
								,DebitPR numeric(14,2),CreditPR numeric (14,2), BegBalPR numeric(14,2), FSymbol char(3), PSymbol char(3),
								nSequence int
								--- 04/17/18 DRP:  added individual columns at the end that breaks out the TransDescr detail
								-- 07/11/18 VL Changed Supname from char(30) to char(35)
								-- 10/11/19 VL changed part_no from char(25) to char(35)
								,ponum varchar(15),supname varchar(35),invno varchar(100),custname char(35),je_no varchar (6),reason varchar (100),checkno char(10),bk_acct_no char(15)
								,cmemono char(10),wono char(10),part_no char(35),revision char(8),descript char(45),qty numeric(12,2),OLDMATLCST numeric(12,2),newmatlcst numeric(12,2)
								,dmemono char(10),whse char(6),cost numeric(12,5),rec_advice char(10),receiverno char(10),conum numeric(3),itemno char(3),OrigTablesaveinit char(8)
								--05/14/18 VL added PR values after adding DRP's 04/17/18 new codes
								,OLDMATLCSTPR numeric(12,2),newmatlcstPR numeric(12,2),costPR numeric(12,5))

							
	Insert @glxtabFC
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case 
				WHEN gltransheader.TransactionType = 'APPREPAY' THEn(SELECT CAST('AP Offset against Prepay: '+RTRIM(apmaster.ponum)  as varchar(100)) 
					FROM apmaster
					where apmaster.UNIQAPHEAD = RTRIM(GlTransDetails.cSubDrill))
				WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'UniqueAr' THEN 
					(SELECT distinct CAST(CASE WHEN Acctsrec.lPrepay=1 THEN  'AR Offset using Prepay: '+ RTRIM(ACCTSREC.invno) 
					ELSE 'AR Offset against Prepay: '+ RTRIM(ACCTSREC.invno) END  as varchar(100))
					from AROFFSET,ACCTSREC 
					where aroffset.CTRANSACTION = RTRIM(gltransdetails.cdrill) and acctsrec.uniquear = rtrim(gltransdetails.csubdrill))
				WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'CTRANSACTION' THEN (SELECT CAST(rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim(cDrill) as varchar(100)))

				when gltransheader.TransactionType = 'ARWO'  then (select CAST('Cust: '+rtrim(customer.custname)+'  Inv#: '+acctsrec.INVNO as varchar(100)) 
					from AR_WO
					INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR
					INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					where AR_WO.ARWOUNIQUE =RTRIM(gltransdetails.CDRILL)) 
				WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill 
					THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST('Check#: '+RTRIM(apchkmst.checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  *No Supplier Assigned' as varchar(200))
							else CAST('Supplier: '+rtrim(supinfo.supname)+'  '+'Check Number: '+apchkmst.checkno +'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)  as varchar(200)) end	
						FROM APCHKMST
						left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
						INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
						WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
				WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  
					THEN (SELECT CAST('Check#: '+RTRIM(apchkmst.checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+ isnull(rtrim(supinfo.supname),'')+ ' Invoice # '+ISNULL(Apmaster.Invno,Item_desc) as varchar(200))	--09/15/16 DRP:  added the Invoice # as extra detail
						FROM APCHKMST
						left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
						INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
						inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	--09/15/16 DRP:  added the apchkdet and apmaster tables in order to get the invoice # as reference
						left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead
						 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL)
						 and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
				--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Check#: '+RTRIM(apchkmst.checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  Supp: '+rtrim(supinfo.supname)+' Invoice #'+ISNULL(Apmaster.Invno,space(20)) as varchar(200))	--09/30/16 DRP:  	
				--	FROM APCHKMST
				--	INNER JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
				--	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
				--	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	--09/15/16 DRP:  added the apchkdet and apmaster tables in order to get the invoice # as reference
				--	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead
				--	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL)
				--	 and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
				when gltransheader.TransactionType = 'CM'  then (select cast('Customer: ' +RTRIM(CustName)+', Credit Memo: '+ rtrim(cmemono) as CHAR (80))
					from cmmain 
					inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)
				WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST('WO#: '+Confgvar.wono+'  Date: '+ cast(cast(confgvar.datetime as DATE)as varchar(10))+' Part/Rev: '+rtrim(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty Trns: '+ cast(CAST(qtytransf as numeric(12,0))as varchar(12)) as varchar(100)) 
					FROm CONFGVAR 
					inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY
					where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
				when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST('PN/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+ '  QtyOH: '+ rtrim(updtstd.QTY_OH)+'  Old: '+rtrim(updtstd.OLDMATLCST)+'  New: '+RTRIM(updtstd.newmatlcst) as varchar(80))
					FROM UPDTSTD
					inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY
					where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
				WHEN gltransheader.TransactionType = 'DEP' then (select cast('Deposit Number: ' + rtrim(cDrill)+'  Bank Acct# '+RTRIM(deposits.bk_acct_no)  as varchar (100))	
					from DEPOSITS
					where deposits.DEP_NO = RTRIM(gltransdetails.cdrill))
				WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(Dmemono)+'  Supp: '+rtrim(supname)+', '+CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END+ '  Against Inv' as varchar(100)) 
					when dmemos.dmtype = 2 then cast (RTRIM(dmemono)+'  Supp: '+ rtrim(supname)+','+  CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END + '  Against Acct' as varchar(100)) end 
					FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  
					WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
				WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'PO#: '+confgvar.ponum+'  Qty: '+cast(CAST(confgvar.QTYTRANSF as numeric(12,0))as varchar(12)) as varchar(100)) 
					else cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'WO#: '+confgvar.wono+'  Qty: '+ cast(CAST(confgvar.QTYTRANSF as numeric(12,0))as varchar(12)) as varchar (100))end 
					FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
	--12/19/2013 DRP: when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST ('PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) as varchar (100))
				when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (case when wono = '' then '' else 'WO:'+ WONO end +' PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) as varchar (100))
					FROm Invt_ISU
					inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY
					inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY
					inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
					where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
				WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST('PN/Rev: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(invt_rec.qtyrec)+'  Cost: '+RTRIM(invt_rec.stdcost) as varchar (100)) 
					FROm Invt_rec
					inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY
					inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY
					inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
					where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
	--			04/15/2013 DRP: needed to look for INVTTRNS in SQL
				--when gltransheader.TransactionType = 'INVTTRANS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) as varchar (100))
				when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) as varchar (100))
					FROM INVTTRNS
					INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY
					WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
				WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(rtrim(gljehdr.JETYPE)+' JE# '+cast(rtrim(gljehdr.JE_NO) as char (6))+'  Reason: '+RTRIM(GLJEHDR.REASON) as varCHAR (100)) 
					FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST('WO#: '+RTRIM(MFGRVAR.WONO)+'  Date:'+cast(cast(mfgrvar.datetime as DATE)as varchar(10))+'  Part/Rev: '+rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+' Desc: '+RTRIM(inventor.descript) as varchar(100)) 
					FROm MFGRVAR,INVENTOR
					where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)
					and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
				when gltransheader.TransactionType = 'NSF' then (select 'NSF: '+cast(RTRIM(cdrill) + ' for Dep#: ' + rtrim(ARRETCK.DEP_NO)+'  Receipt Advice: '+RTRIM(arretck.rec_advice)+'  Cust: '+RTRIM(custname)  as varchar(100)) 
					from ARRETCK
					inner join CUSTOMER on arretck.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = arretck.UNIQRETNO) 
				WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(' Inv#: '+rtrim(apmaster.invno)+'  PO#: '+rtrim(apmaster.ponum)+ '  Supp: '+RTRIM(Supname)  as varchar(100)) 
					FROM Apmaster 
					inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 
					where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
				WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST('Recv#: '+rtrim(Sinvoice.receiverno)+'  '+'Inv#: '+rtrim(sinvoice.INVNO)+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) as varchar(100)) 
					FROM pur_var
					inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ
					inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ
					inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO
					inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
					where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
				WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))

				WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(100)) 
					FROM Plmain 
					inner join Customer on Plmain.custno = customer.CUSTNO 
					where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('WO#: '+SCRAPREL.wono+'  Date: '+ cast(cast(SCRAPREL.datetime as DATE)as varchar(10))+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+cast(CAST(scraprel.QTYTRANSF as numeric(12,0))as varchar(12))+'  Cost: '+cast(scraprel.stdcost as varchar(17)) as varchar(100)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST('Recv# '+Porecloc.RECEIVERNO+'  '+'PO# '+RTRIM(poitems.ponum)+'  CO# '+RTRIM(pomain.conum)+'  Item# '+RTRIM(poitems.ITEMNO)+'  Supp:'+RTRIM(supinfo.supname)  as varchar(100)) 
					FROM porecrelgl 
					INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 
					inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL
					inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno
					inner join POMAIN on poitems.PONUM = pomain.ponum
					inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
					where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
				ELSE CAST('Cannot Link back to source' as varchar(100))
				end as GenrRef
				,ISNULL(b.begbal,0.00) as BegBal,' ',SAVEINIT,
				-- 01/05/17 VL added functional currency fields
				-- 09/27/17 VL fixed BegBalPR which took begbal incorrectly, should be begbalPR
				GlTransDetails.DEBITPR, GlTransDetails.CREDITPR, ISNULL(b.begbalPR,0.00) as BegBalPR, FF.Symbol AS FSymbol, PF.Symbol AS PSymbol,
				---	07/27/17 YS Need a sequence number for proper calculation of the running total
			row_number() OVER (partition by gltrans.gl_nbr order by trans_dt,trans_no) as nSequence 
	-- 09/21/2012 DRP:  Made changes to the BegBal to cast it as numeric and added the insull  

--- 04/17/18 DRP:  added individual columns at the end that breaks out the TransDescr detail

			/*ponum*/,case WHEN gltransheader.TransactionType = 'APPREPAY' THEn(SELECT CAST(RTRIM(apmaster.ponum)  as varchar(15)) FROM apmaster where apmaster.UNIQAPHEAD = RTRIM(GlTransDetails.cSubDrill))
			WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE RTRIM(DMEMOS.PONUM)END as varchar(15)) 
			when dmemos.dmtype = 2 then cast (CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END as varchar(15)) end FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (confgvar.ponum as varchar(15)) else cast ('' as varchar(15)) end FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(rtrim(apmaster.ponum)as varchar(15)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
			when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(poitems.ponum)as varchar(15)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno inner join POMAIN on poitems.PONUM = pomain.ponum inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST('' as varchar(15)) end as ponum
			-- 07/11/18 VL Changed Supname from char(30) to char(35)
			/*supplier*/,case WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST('*No Supplier Assigned' as varchar(30)) else CAST(rtrim(supinfo.supname)  as varchar(35)) end FROM APCHKMST left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  THEN (SELECT CAST(isnull(rtrim(supinfo.supname),'') as varchar(35)) FROM APCHKMST left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(supname) as varchar(35)) when dmemos.dmtype = 2 then cast (rtrim(supname) as varchar(35)) end FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(RTRIM(Supname)  as varchar(35)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
			when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(supinfo.supname)  as varchar(35)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno inner join POMAIN on poitems.PONUM = pomain.ponum inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			-- 05/14/18 VL added supname for PURVAR, request by CM solutions #1980
			when gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(RTRIM(supinfo.supname)  as varchar(35)) FROM pur_var inner join Apmaster on Pur_Var.fk_UniqApHead = Apmaster.UniqAphead inner join supinfo on Apmaster.UNIQSUPNO = Supinfo.UNIQSUPNO where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			ELSE CAST('' as varchar(35)) end as supname
			/*invno*/,case WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'UniqueAr' THEN (SELECT distinct CAST(CASE WHEN Acctsrec.lPrepay=1 THEN  RTRIM(ACCTSREC.invno) ELSE RTRIM(ACCTSREC.invno) END  as varchar(100))	from AROFFSET,ACCTSREC 	where aroffset.CTRANSACTION = RTRIM(gltransdetails.cdrill) and acctsrec.uniquear = rtrim(gltransdetails.csubdrill))
			when gltransheader.TransactionType = 'ARWO'  then (select CAST(acctsrec.INVNO as varchar(100))from AR_WO	INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR	INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO where AR_WO.ARWOUNIQUE =RTRIM(gltransdetails.CDRILL)) 
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  THEN (SELECT CAST(ISNULL(Apmaster.Invno,Item_desc) as varchar(100))	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(rtrim(apmaster.invno)  as varchar(100)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
			WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(rtrim(sinvoice.INVNO) as varchar(100)) FROM pur_var	inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ	inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST(InvoiceNo as varchar(100)) FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
			ELSE CAST('' as varchar(100)) end as invno
			/*custname*/,case when gltransheader.TransactionType = 'ARWO'  then (select CAST(rtrim(customer.custname) as varchar(35))	from AR_WO	INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR	INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO	where AR_WO.ARWOUNIQUE =RTRIM(gltransdetails.CDRILL)) 
			when gltransheader.TransactionType = 'CM'  then (select cast(RTRIM(CustName)as CHAR (35)) from cmmain 	inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique) 			
			when gltransheader.TransactionType = 'NSF' then (select cast(RTRIM(custname)  as varchar(35)) from ARRETCK	inner join CUSTOMER on arretck.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = arretck.UNIQRETNO) 	
			WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST(RTRIM(CustName) as varchar(35))	FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO 	where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
			ELSE CAST('' as varchar(35))end as custname
			/*je_no*/,case WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(cast(rtrim(gljehdr.JE_NO) as char (6)) as varCHAR (6))  FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
			ELSE CAST('' as varchar(6)) end as je_no
			/*reason*/,case	when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON) as varchar (100))	FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(RTRIM(GLJEHDR.REASON) as varCHAR (100))	FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)		
			ELSE CAST('' as varchar(100)) end as reason
			/*checkno*/,case WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST(RTRIM(apchkmst.checkno) as varchar(10))	else CAST(apchkmst.checkno as varchar(10)) end	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  THEN (SELECT CAST(RTRIM(apchkmst.checkno) as varchar(10))	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			ELSE CAST('' as varchar(10)) end as checkno
			/*bank_acct_no*/,case WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST(RTRIM(BANKS.BK_ACCT_NO) as char(15)) else CAST(RTRIM(BANKS.BK_ACCT_NO)  as char(15)) end	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill THEN (SELECT CAST(RTRIM(BANKS.BK_ACCT_NO) as char(15))FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			WHEN gltransheader.TransactionType = 'DEP' then (select cast(RTRIM(deposits.bk_acct_no)  as char (15)) from DEPOSITS	where deposits.DEP_NO = RTRIM(gltransdetails.cdrill))
			ELSE CAST('' as varchar(15)) end as bk_acct_no

			/*dep_no*/  --did not break out the dep_no records because those are the unique keys that are already available in the drills
			/*cmemono*/,case when gltransheader.TransactionType = 'CM'  then (select cast(rtrim(cmemono) as CHAR (10)) from cmmain 	inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)	
			ELSE CAST('' as varchar(10)) end as cmemono
			/*wono*/,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST(Confgvar.wono as char(10)) FROm CONFGVAR 	inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast ('' as char(10)) else cast (confgvar.wono as char (10))end FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (case when wono = '' then '' else  WONO end  as char (10)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(RTRIM(MFGRVAR.WONO) as char(10)) FROm MFGRVAR,INVENTOR	where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL) and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST(mfgrvar.WONO  as varchar(10)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(SCRAPREL.wono as char(10))  FROM SCRAPREL,INVENTOR where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)	and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST('' as varchar(10)) end as wono
			-- 10/11/19 VL changed part_no from char(25) to char(35)
			/*part_no*/,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST(rtrim(inventor.part_no) as char(35)) FROm CONFGVAR inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))			
			when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(RTRIM(inventor.part_no) as char(35)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no) as varchar(35)) else cast (rtrim(inventor.part_no) as char (35))end FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (case when wono = '' then '' else RTRIM(inventor.part_no) end as varchar (35)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(RTRIM(inventor.part_no) as varchar (35)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST ( rTRIM(inventor.part_no) as varchar (35)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(rtrim(inventor.part_no) as varchar(35)) FROm MFGRVAR,INVENTOR	where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)	and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(RTRIM(inventor.part_no) as varchar(35)) FROM pur_var inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ	inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(RTRIM(inventor.part_no)as varchar(35)) FROM SCRAPREL,INVENTOR where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL) and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST('' as varchar(35)) end as part_no
			/*revision*/,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST(RTRIM(inventor.revision) as varchar(8))	FROm CONFGVAR inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY	where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
			when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(RTRIM(inventor.revision) as varchar(8)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.revision)as varchar(8)) else cast (rtrim(inventor.revision)as varchar (8))end FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (case when wono = '' then '' else RTRIM(inventor.revision) end as varchar (8)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(RTRIM(inventor.revision) as varchar (8)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (RTRIM(inventor.revision) as varchar (8)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill)) 
			WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(rtrim(inventor.revision) as varchar(8)) FROm MFGRVAR,INVENTOR where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL) and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(RTRIM(inventor.revision) as varchar(8)) FROM pur_var	inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ	inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(RTRIM(inventor.revision) as varchar(8)) FROM SCRAPREL,INVENTOR	where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)	and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST('' as char(8)) end as revision
			/*descr*/,case WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(RTRIM(inventor.descript) as char(45)) FROm MFGRVAR,INVENTOR where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)	and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			ELSE CAST('' as char(45)) end as descript
			/*qty*/,case WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST(qtytransf as numeric(12,2)) FROm CONFGVAR 	inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY	where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
			when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.QTY_OH as numeric(12,2))	FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (confgvar.QTYTRANSF as numeric(12,2)) 	else cast (confgvar.QTYTRANSF as numeric(12,2))end 	FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = RTRIM(glTRANSDETAILS.cDrill)) 
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (INVT_ISU.QTYISU as numeric(12,2))	FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(invt_rec.qtyrec as numeric(12,2))	FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (invtTRNS.QTYXFER as numeric(12,2))	FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(scraprel.QTYTRANSF as numeric(12,2))	FROM SCRAPREL,INVENTOR	where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)	and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE null end as qty
			/*OLDMATLCST*/,case when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.OLDMATLCST as numeric (12,2)) FROM UPDTSTD inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill)) 
			ELSE null end as oldmatlcst
			/*newmatlcst*/,case when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.newmatlcst as numeric(12,2)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			ELSE null end as newmatlcst
			/*dmemono*/,case WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(Dmemono) as char(10)) when dmemos.dmtype = 2 then cast (RTRIM(dmemono)as char(10)) end 	FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))	
			ELSE CAST('' as char(10)) end as dmemono
			/*whse*/,case when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (RTRIM(warehous.WAREHOUSE) as char (6)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(RTRIM(warehous.WAREHOUSE) as char (6)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			ELSE CAST('' as char(6)) end as whse
			/*cost*/,case when gltransheader.TransactionType = 'INVTISU' THEN (SELECT cast(invt_ISU.stdcost as numeric(12,5)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT cast(invt_rec.stdcost as numeric(12,5)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST(INVTTRNS.stdcost as numeric (12,5)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(scraprel.stdcost as numeric(12,5)) FROM SCRAPREL,INVENTOR where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL) and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST(null as numeric(12,5)) end as cost
			/*rec_advice*/,case when gltransheader.TransactionType = 'NSF' then (select cast(RTRIM(arretck.rec_advice)as char(10)) from ARRETCK	inner join CUSTOMER on arretck.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = arretck.UNIQRETNO) 
			ELSE CAST('' as char(10)) end as rec_advice
			/*receiverno*/,case	WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(rtrim(Sinvoice.receiverno)as char(10)) FROM pur_var	inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(rtrim(Porecloc.RECEIVERNO) as char(10)) FROM porecrelgl 	INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 	inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL	inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno	inner join POMAIN on poitems.PONUM = pomain.ponum	inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST('' as char(10)) end as receiverno
			/*conum*/,case when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(pomain.conum) as numeric(3,0)) 	FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 	inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL	inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno	inner join POMAIN on poitems.PONUM = pomain.ponum	inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST(null as numeric(3)) end as conum
			/*itemno*/,case when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(POITEMS.itemno) as char(3)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 	inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL	inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno	inner join POMAIN on poitems.PONUM = pomain.ponum	inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			ELSE CAST('' as char(3)) end as itemno
			/*saveinit*/,case WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT case when apchkmst.UNIQSUPNO = '' then CAST(apchkmst.saveinit as char(8))	else cast(apchkmst.saveinit as char(8)) end	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill THEN (SELECT CAST(apchkmst.saveinit as char(8))	FROM APCHKMST	left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ	inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
			when gltransheader.TransactionType = 'CM'  then (select cast(cmmain.saveinit as char(8)) from cmmain inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)
			WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(dmemos.saveinit as char(8)) when dmemos.dmtype = 2 then cast (dmemos.saveinit as char(8)) end FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  	WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
			WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(gljehdr.saveinit as char(8)) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
			WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST(plmain.SAVEINIT as char(8))	FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO 	where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
			WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST(sinvoice.SAVEINIT as char(8)) FROM pur_var inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ	inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ	inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO	inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY	where pur_var.VAR_KEY =RTRIM(gltransdetails.cDrill)) 
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST(invt_rec.SAVEINIT as char(8))	FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST (invt_isu.SAVEINIT as char(8))	FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST (INVTTRNS.SAVEINIT as char(8)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY	WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(porecrelgl.TRANSINIT as char(8)) FROM porecrelgl 	INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 	inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL	inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno	inner join POMAIN on poitems.PONUM = pomain.ponum	inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO	where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
			when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.INIT as char(8)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(scraprel.INITIALS as char(8)) FROM SCRAPREL,INVENTOR	where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL) and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(mfgrvar.INITIALS as char(8))	FROm MFGRVAR,INVENTOR	where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL) and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
			WHEN gltransheader.TransactionType = 'APPREPAY' THEn(SELECT CAST(apmaster.INIT as char(8)) FROM apmaster where apmaster.UNIQAPHEAD = RTRIM(GlTransDetails.cSubDrill))
			WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(apmaster.init as char(8)) FROM Apmaster 	inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 	where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL)) 
			WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST(MFGRVAR.INITIALS as char(8)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
			ELSE CAST('' as char(8)) end as OrigTablesaveinit

---04/17/18 DRP:  end of individual column add
			-- 05/14/18 VL added PR fields after Debbie added new detail fields
			/*OLDMATLCSTPR*/,case when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.OLDMATLCSTPR as numeric (12,2)) FROM UPDTSTD inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill)) 
			ELSE null end as oldmatlcstPR
			/*newmatlcstPR*/,case when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST(updtstd.newmatlcstPR as numeric(12,2)) FROM UPDTSTD	inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY	where updtstd.UNIQ_UPDT = RTRIM(gltransdetails.cdrill))
			ELSE null end as newmatlcstPR
			/*costPR*/,case when gltransheader.TransactionType = 'INVTISU' THEN (SELECT cast(invt_ISU.stdcostPR as numeric(12,5)) FROm Invt_ISU	inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where invt_isu.INVTISU_NO = RTRIM(gltransdetails.cdrill))
			WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT cast(invt_rec.stdcost as numeric(12,5)) FROm Invt_rec	inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY	inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY	inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH	where INVT_REC.INVTREC_NO = RTRIM(gltransdetails.cdrill))
			when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST(INVTTRNS.stdcost as numeric (12,5)) FROM INVTTRNS	INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY WHERE INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.cDrill))
			WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST(scraprel.stdcost as numeric(12,5)) FROM SCRAPREL,INVENTOR where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL) and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
			ELSE CAST(null as numeric(12,5)) end as costPR

-- 06/21/19 VL changed to use 3 new temp tables
	FROM	#GetGlTransheader GLTRANSHEADER 
				-- 01/05/17 VL added to show currency symbol
				INNER JOIN Fcused PF ON GLTRANSHEADER.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON GLTRANSHEADER.FuncFcused_uniq = FF.Fcused_uniq
			inner join #GetGlTrans gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join #GetGlTransDetails GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
	--	09/26/2012 DRP:  removed the below code that was slowing the results when calculating the Beginning Balance
	-- 09/27/17 VL added BegBalPR
			left outer JOIN (select	G.GL_NBR,SUM(g.debit-g.Credit) as BegBal, SUM(g.debitPR-g.CreditPR) as BegBalPR
	--09/21/2012 DRP:  had to change the above join to left outer join in order to get the correct BegBal of 0.00 even if the GL Nbr had never been used before.
			-- 12/06/19 VL changed back to use table to calculate BegBal, not the temp table which only contains the data for selected date range, need to find data before current date range
			FROM	GLTRANSHEADER GH2
					inner join Gltrans G on GH2.GLTRANSUNIQUE =G.Fk_GLTRansUnique 
			where GH2.TRANS_DT < @lcDateStart
					group by g.GL_NBR) B ON b.gl_nbr=gltrans.gl_nbr

------ 06/21/19 VL comment out the criteria, already use when creating 3 temp tables
--	where	1 = case when gltrans.GL_NBR in (select gl_nbr from @GLNumber ) then 1 else 0 end	
--			and GLTRANSHEADER.trans_dt>=@lcDateStart AND GLTRANSHEADER.TRANS_DT<@lcDateEnd+1
	---07/27/17	
	--order by trans_no

	-- 09/26/2012 DRP:  UPdate the table with the license information
		--update @glxtab SET LIC_NAME=Micssys.LIC_NAME FROM MICSSYS
	-- 09/26/2012 DRP:  update the reference information for PURCH types
		update @glxtabFC SET Reference = CASE WHEN TransactionType='PURCH' THEN isnull(dbo.FnGlXtabRef(cDrill),'') else '' end 

---					07/27/17 YS use nsequence number for proper calculation of the running total
	select	post_date,Trans_no,Trans_dt,period,Fy,gl_nbr,TransactionType,isnull(TransDescr,'Cannot link back to Source') as TransDescr,debit,credit,saveinit,GL_Descr,BegBal,Reference	--11/23/16 DRP:  changed the TransDescr to be isnull(TransDescr,'Cannot link back to Source')
			,RunningTotal =  BegBal + sum(debit-credit) over (partition by gl_nbr order by trans_dt range unbounded preceding)	--12/04/15 DRP:  added
			,SourceTable,Cidentifier,cDrill,SourceSubTable,cSubIdentifier,cSubDrill
			-- 01/05/17 VL added functional currency fields 
			,debitPR,creditPR, BegBalPR
			,RunningTotalPR =  BegBalPR + sum(debitPR-creditPR) 
			--over (partition by gl_nbr order by trans_dt range unbounded preceding)
			over(partition by gl_nbr order by  nsequence  range unbounded preceding)     ---07/27/17 YS Need a sequence number for proper calculation of the running total
			,FSymbol, PSymbol
			,supname,custname,invno,ponum,conum,itemno,je_no,reason,checkno,bk_acct_no,cmemono,wono,part_no,revision,descript,qty,OLDMATLCST,newmatlcst,dmemono,whse,cost,rec_advice,receiverno,OrigTablesaveinit	---04/17/18 DRP:  added individual columns
			-- 05/14/18 VL added PR values after DRP's 04/17/18 adding new fields
			,OLDMATLCSTPR,newmatlcstPR,costPR
			-- 04/25/18 VL added nsequence column, so in Stimulsoft report, it will sort gl_nbr, trans_dt, trans_no plus nsequence, to show correct running total at the end
			,nSequence
	from	@glxtabFC 
	order by gl_nbr,Trans_Dt,trans_no
	END

END


-- 03/21/19 VL drop temp tables
IF OBJECT_ID('tempdb..#GetGlTransHeader') IS NOT NULL
	DROP TABLE #GetGlTransHeader	
IF OBJECT_ID('tempdb..#GetGlTrans') IS NOT NULL
	DROP TABLE #GetGlTrans
IF OBJECT_ID('tempdb..#GetGlTransDetails') IS NOT NULL
	DROP TABLE #GetGlTransDetails	

end		
	