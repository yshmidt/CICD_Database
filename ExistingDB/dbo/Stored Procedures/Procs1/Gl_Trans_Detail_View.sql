-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/26/2012
-- Description:	This SP used in the GLVIEW form for the detail tab.
-- it is almost the same as rptglXtab without lisence name and beg balance calculatioon
-- Modifications: 04/15/2013 DRP:  VFP records used to be INVTTRANS, but we need to change to look for "INVTTRNS" in SQL.  Below has been changed to look for only "INVTTRNS". 
--					09/29/16 DRP:	 it was found that if the check records were generated for example from auto bank deductions where no supplier was associated with the apchkmst record that the GenrRef would then just return NULL as soon as it could not find a matching supplier     
--				  01/05/2017 VL:   added functional currency code and separate FC and non FC
--					03/22/17 DRP:	found that the changes that I implemented on 09/29/16 caused normal Checks to not return any results,  upon review found that I need to have two sections for regular checks and one for Auto Bank Deductions. 

-- =============================================
CREATE PROCEDURE [dbo].[Gl_Trans_Detail_View]
	-- Add the parameters for the stored procedure here
	 @lcGlNbr as varchar(13) = ' '
	,@lcDateStart as smalldatetime= null
	,@lcDateEnd as smalldatetime = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 01/05/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
		-- Insert statements for procedure here
		SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
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
				--03/22/17 DRP:  This Checks section will cover checks cut from Auto Bank Deductions.   
				WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  
					THEN (SELECT CAST('Check#: '+RTRIM(apchkmst.checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+ isnull(rtrim(supinfo.supname),'')+ ' Invoice # '+ISNULL(Apmaster.Invno,Item_desc) as varchar(200))	--09/15/16 DRP:  added the Invoice # as extra detail
						FROM APCHKMST
						left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
						INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
						inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	--09/15/16 DRP:  added the apchkdet and apmaster tables in order to get the invoice # as reference
						left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead
						 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL)
						 and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
				--03/22/17 DRP:  added this Checks section back in with some minor changes to handle normal Checks
				WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT CAST('Check#: '+RTRIM(checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+ case when APCHKMST.UNIQSUPNO = '' then '' else '  Supp: '+rtrim(supinfo.supname) end as varchar(100)) 
					FROM APCHKMST
					left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
					left outer JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
					 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
				--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Check#: '+RTRIM(checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  Supp: '+rtrim(supinfo.supname) as varchar(100)) --09/29/16 DRP:  replaced with the above
				--	FROM APCHKMST
				--	INNER JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
				--	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
				--	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
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
				when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST ('PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) as varchar (100))
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
				end as TransDescr
	FROM	GLTRANSHEADER  
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
		

	where	gltrans.GL_NBr = @lcGlNbr 
			and DATEDIFF(Day,GLTRANSHEADER.trans_dt,@lcDateStart)<=0 
			AND DATEDIFF(Day,GLTRANSHEADER.TRANS_DT,@lcDateEnd)>=0
ELSE
	   -- Insert statements for procedure here
		SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			-- 01/05/17 VL added presentation currency fields and currency symbol
			,GlTransDetails.DEBITPR, GlTransDetails.CREDITPR, FF.Symbol AS Functional_Currency, PF.Symbol AS Presentation_Currency
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
				--03/22/17 DRP:  This Checks section will cover checks cut from Auto Bank Deductions.   
				WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill <> GlTransDetails.csubdrill  
					THEN (SELECT CAST('Check#: '+RTRIM(apchkmst.checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+ isnull(rtrim(supinfo.supname),'')+ ' Invoice # '+ISNULL(Apmaster.Invno,Item_desc) as varchar(200))	--09/15/16 DRP:  added the Invoice # as extra detail
						FROM APCHKMST
						left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
						INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
						inner join Apchkdet on apchkmst.APCHK_UNIQ=apchkdet.Apchk_uniq	--09/15/16 DRP:  added the apchkdet and apmaster tables in order to get the invoice # as reference
						left outer join apmaster on apchkdet.uniqaphead=apmaster.uniqaphead
						 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL)
						 and apchkdet.apckd_uniq=RTRIM(gltransdetails.cSubdrill))
				--03/22/17 DRP:  added this Checks section back in with some minor changes to handle normal Checks
				WHEN gltransheader.TransactionType = 'CHECKS' and gltransdetails.cdrill = GlTransDetails.csubdrill THEN (SELECT CAST('Check#: '+RTRIM(checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+ case when APCHKMST.UNIQSUPNO = '' then '' else '  Supp: '+rtrim(supinfo.supname) end as varchar(100)) 
					FROM APCHKMST
					left outer JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
					left outer JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
					 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
				--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Check#: '+RTRIM(checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  Supp: '+rtrim(supinfo.supname) as varchar(100)) --09/29/16 DRP:  replaced with the above
				--	FROM APCHKMST
				--	INNER JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
				--	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
				--	 WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
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
				when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST ('PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) as varchar (100))
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
				end as TransDescr
	FROM	GLTRANSHEADER  
			-- 01/05/17 VL added to show currency symbol
			INNER JOIN Fcused PF ON GLTRANSHEADER.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON GLTRANSHEADER.FuncFcused_uniq = FF.Fcused_uniq
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
	where	gltrans.GL_NBr = @lcGlNbr 
			and DATEDIFF(Day,GLTRANSHEADER.trans_dt,@lcDateStart)<=0 
			AND DATEDIFF(Day,GLTRANSHEADER.TRANS_DT,@lcDateEnd)>=0
END