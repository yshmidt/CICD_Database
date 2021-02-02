
-- =============================================
-- Author:		Debbie
-- Create date: 06/27/2012
-- Description:	Created for the Individual Transaction Inquiry
-- Reports Using Stored Procedure:  glinq.rpt
-- Modifications:	DRP 06/27/2012:  added comments as to why we could not break down detailed information farther than we did for the AR and AP Offset. 
--					DRP 07/05/2012:  We dropped the gltrans_no field from the scraprel table during the vfp to sql conversion.  any SCRAP transaction that was generated before converting to SQL
--					will be associated to that gltrans_no field that has now been removed.  These records will not be able to be back linked for reference on the GL Transaction reports. 
--					DRP 08/28/2012:  Jeanette brought to my attention that I need to add the Reason for when the Transaction originated from a Journal Entry.
--					01/15/2014 DRP:  added the @userid parameter for WebManex 
--					10/10/14 YS replace invtmfhd with 2 tables
--					09/29/16 DRP:	 it was found that if the check records were generated for example from auto bank deductions where no supplier was associated with the apchkmst record that the GenrRef would then just return NULL as soon as it could not find a matching supplier     
--					01/05/2017 VL:   added functional currency fields
-- =============================================
CREATE PROCEDURE [dbo].[rptGlTransInq]

	 @lcTransNo int = ''
	 ,@userId uniqueidentifier=null
AS
BEGIN
-- 01/05/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
	--					10/10/14 YS replace invtmfhd with 2 tables
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case WHEN gltransheader.TransactionType = 'APPREPAY' THEN (SELECT CAST('AP Offset: ' +Apoffset.uniq_save as varchar(80)) FROM apoffset where Apoffset.uniq_save = RTRIM(GlTransDetails.CDRILL) GROUP by UNIQ_SAVE)
				WHEN gltransheader.TransactionType = 'ARPREPAY' THEN (SELECT CAST('AR Offset: '+ rtrim(cdrill) as varchar(80)))
				WHEN gltransheader.TransactionType = 'ARWO' THEN (SELECT CAST('AR Write-Off: '+ rtrim(GLTRANSHEADER.sourcetable)+'.'+RTRIM(gltransheader.cidentifier)+': '+RTRIM(cdrill) as varchar(80))) 
				when gltransheader.TransactionType = 'CM' then (select cast('Customer: ' +RTRIM(CustName)+', Credit Memo: '+ rtrim(cmemono) as CHAR (80))from cmmain inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)
				WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CASE WHEN apchkmst.UNIQSUPNO = '' THEN CAST('Check Number: '+apchkmst.checkno + '  *No Supplier Assigned'  as varchar(80)) ELSE CAST('Supplier: '+rtrim(supinfo.supname)+'  '+'Check Number: '+apchkmst.checkno as varchar(80)) END  FROM APCHKMST left outer join SUPINFO on apchkmst.uniqsupno = supinfo.uniqsupno WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
				--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Supplier: '+rtrim(supinfo.supname)+'  '+'Check Number: '+checkno as varchar(80)) FROM APCHKMST,SUPINFO WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and SUPINFO.UNIQSUPNO = apchkmst.UNIQSUPNO)	--09/29/16 DRP:  replaced with the above to adress null values display in gthe GenrRef field if Uniqsupno was blank
				WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST('Work Order: '+Confgvar.wono+'  Qty Trns: '+cast(confgvar.qtytransf as varchar(17)) as varchar(80)) FROm CONFGVAR where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
				when gltransheader.TransactionType = 'COSTADJ' AND GLTRANS.SourceSubTable = 'UPDTSTD' THEN (SELECT CAST('Cost Adjustment: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(cdrill)  as varchar(80))) 
				when gltransheader.TransactionType = 'COSTADJ' AND GLTRANS.SourceSubTable = 'INVENTOR' THEN (SELECT  CAST('Cost Adjustment: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(cdrill)  as varchar(80)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
				WHEN gltransheader.TransactionType = 'DEP' then cast('Deposit Number: ' + rtrim(cDrill) as varchar (80)) 
				WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast('Supplier: '+rtrim(supname)+', #'+rtrim(Dmemono)+'  Against Inv' as varchar(80)) 
					when dmemos.dmtype = 2 then cast ('Supplier: '+ rtrim(supname)+', #'+RTRIM(dmemono)+ '  Against Acct' as varchar(80)) end FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
				--WHEN gltransheader.TransactionType = 'DM' THEN (SELECT cast('Supplier: '+rtrim(supname)+', '+rtrim(Dmemono) as varchar(80)) FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
				WHEN gltransheader.TransactionType = 'INVTISU' and gltrans.SourceSubTable = 'INVENTOR' THEN (SELECT  CAST('Inventory Issue: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill) as varchar (80)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
				WHEN gltransheader.TransactionType = 'INVTISU' AND gltrans.SourceSubTable ='INVT_ISU' THEN CAST('Inventory Issue: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(CDRILL) as varchar (80)) 
				WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVENTOR' THEN (SELECT  CAST('Inventory Receipt: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill) as varchar (80)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
				WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVT_REC' THEN CAST('Inventory Receipt: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(CDRILL) as varchar (80)) 
				when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST('Inventory Transfer: ' + rtrim(inventor.part_no)+'/'+ RTRIM(inventor.revision)+'  '+ RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+RTRIM(GLTRANS.CSUBIDENTIFIER)+': '+ rtrim(cDrill)as Varchar(80))
				FROM INVENTOR,INVTTRNS,INVTMFGR,InvtMPNLink L 
					WHERE INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) 
					AND INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.CDRILL) 
					AND INVTTRNS.FROMWKEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)	
				WHEN gltransheader.TransactionType = 'JE' THEN (SELECT 'JE# '+cast(cast(rtrim(gljehdr.JE_NO) as char (6))+rtrim(gljehdr.JETYPE)+'  Reason: '+ rtrim(gljehdr.reason) as varCHAR (80)) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
				when gltransheader.TransactionType = 'NSF' then (select 'NSF: '+cast(RTRIM(cdrill) + ' for Deposit Number: ' + rtrim(ARRETCK.DEP_NO)  as varchar(80)) from ARRETCK where gltransdetails.cdrill = arretck.UNIQRETNO) 
				WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT  CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(80)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
				WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST('Receiver No: '+Sinvoice.receiverno+'  '+'Inv: '+sinvoice.INVNO as varchar(80)) 
					FROM SINVOICE 
					where Sinvoice.SINV_UNIQ =RTRIM(gltransdetails.cSubDrill)) 
				WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(80)) FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
				WHEN gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST('UnReconciled Receipt: '+'Recv # '+Porecloc.RECEIVERNO  as varchar(80)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'inventor.uniq_key: '+RTRIM(mfgrvar.uniq_key) as varchar(80)) 
				FROm MFGRVAR,INVENTOR
				 where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)
				 and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
	--					DRP 07/05/2012:  We dropped the gltrans_no field from the scraprel table during the vfp to sql conversion.  any SCRAP transaction that was generated before converting to SQL
	--					will be associated to that gltrans_no field that has now been removed.  These records will not be able to be back linked for reference on the GL Transaction reports. 			
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('Work Order: '+SCRAPREL.wono+'  '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) as varchar(80)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'PO: '+confgvar.ponum+' Qty: '+CAST(rtrim(confgvar.qtytransf) as CHAR(10)) as varchar(80)) 
					else cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'WO: '+confgvar.wono+' Qty: '+CAST(rtrim(confgvar.qtytransf) as CHAR(10)) as varchar (80))end 
					FROm Inventor,confgvar where ConfgVar.UNIQCONF =RTRIM(glTRANSDETAILS.cDrill) and Inventor.UNIQ_KEY =RTRIM(confgvar.uniq_key))
				WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
				ELSE CAST('Cannot Link back to source' as varchar(60))
			end as GenrRef  
			,case when gltransheader.TransactionType = 'ARWO' and gltrans.SourceSubTable = 'ACCTSREC' then (select CAST('Inv#: '+acctsrec.INVNO+'  '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill) as varchar(80)) 
						from ACCTSREC where acctsrec.uniquear=RTRIM(gltransdetails.CSubDRILL)) 
				 WHEN gltransheader.TransactionType = 'ARWO' and gltrans.SourceSubTable = 'AR_WO' then CAST('Cannot Link back to source' as varchar(80)) 
				when gltransheader.TransactionType = 'COSTADJ' AND GLTRANS.SourceSubTable = 'INVENTOR' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) +'   '+rtrim(gltrans.SourceSubTable)+'.'+RTRIM(gltrans.csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
				when gltransheader.TransactionType = 'COSTADJ' AND GLTRANS.SourceSubTable = 'UPDTSTD' THEN CAST ('Cannot Link back to source' AS VARCHAR(80))
				when gltransheader.TransactionType = 'DEP' and SourceSubTable = 'ArCredit' then (select CAST('Inv#: '+rtrim(arcredit.INVNO) +'   '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(gltrans.cSubIdentifier)+': '+rtrim(cSubDrill) as varchar(100)) from ARCREDIT where arcredit.UNIQDETNO = gltransdetails.cSubDrill)
				when gltransheader.TransactionType = 'DEP' and SourceSubTable = 'Deposits' then (select CAST(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill) as varchar(100)) from deposits where deposits.dep_no = gltransdetails.cSubDrill)
				WHEN gltransheader.TransactionType = 'DM' and gltrans.SourceSubTable = 'APDMDETL' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast('Inv# '+RTRIM(dmemos.INVNO)+'  '+'Item #: '+rtrim(apdmdetl.ITEM_NO)+'  '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(80)) 
					WHEN DMEMOS.DMTYPE = 2 THEN cast('Item #'+rtrim(apdmdetl.ITEM_NO)+'  '+rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100)) END FROM apdmdetl inner join DMEMOS on apdmdetl.UNIQDMHEAD = dmemos.UNIQDMHEAD  WHERE apdmdetl.UNIQDMDETL  =RTRIM(gltransdetails.cSubDrill))
				when gltransheader.TransactionType = 'INVTISU' and gltrans.SourceSubTable = 'INVENTOR' then (SELECT CAST('MFGR: '+ RTRIM(M.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ 'invtmfgr.w_key: '+ rtrim(invtmfgr.w_key)AS VARCHAR(100)) 
					FROM INVENTOR,INVT_ISU,INVTMFGR,InvtMPNLink L, MfgrMaster M 
					WHERE L.mfgrMasterId=M.MfgrMasterId
					AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) AND INVT_ISU.INVTISU_NO = RTRIM(GLTRANSDETAILS.CDRILL) AND INVT_ISU.W_KEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)
				WHEN gltransheader.TransactionType = 'INVTISU' AND gltrans.SourceSubTable ='INVT_ISU' THEN CAST('Cannot Link back to source' as varchar (80)) 
				when gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVENTOR'  THEN (SELECT CAST('MFGR: '+ RTRIM(M.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ 'invtmfgr.w_key: '+ rtrim(invtmfgr.w_key)AS VARCHAR(100)) 
					FROM INVENTOR,INVT_REC,INVTMFGR,InvtMPNLink L, MfgrMaster M  
					WHERE L.mfgrMasterId=M.MfgrMasterId
					AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) AND INVT_REC.INVTREC_NO = RTRIM(GLTRANSDETAILS.CDRILL) AND INVT_REC.W_KEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)
				WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVT_REC' THEN CAST('Cannot Link back to source' as varchar (80)) 
				when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST('MFGR: '+ RTRIM(M.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill)AS VARCHAR(100)) 
					FROM INVENTOR,INVTTRNS,INVTMFGR,InvtMPNLink L, MfgrMaster M  
					WHERE L.mfgrMasterId=M.MfgrMasterId
					AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) 
					AND INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.CDRILL) 
					AND INVTTRNS.FROMWKEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)	
				when GLTRANSHEADER.TransactionType = 'PURVAR' THEN (SELECT CAST(rtrim(inventor.PART_NO)+'/'+rtrim(inventor.REVISION)+'  '+RTRIM(sourcesubtable)+'.'+RTRIM(csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) 
					from pur_var
					inner join SINVDETL on pur_var.SDET_UNIQ = sinvdetl.SDET_UNIQ 
					LEFT outer join POITEMS on sinvdetl.UNIQLNNO = poitems.UNIQLNNO
					inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
					where pur_Var.var_key = rtrim(gltransdetails.cdrill)) 	 
				WHEN gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) +'  '+'Qty: '+rtrim(cast(PORecRelGl.TRANSQTY as CHAR(17))) + '  '+rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill)as varchar(100)) 
					FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ
					INNER JOIN PORECDTL ON PORECLOC.FK_UNIQRECDTL = PORECDTL.UNIQRECDTL
					INNER JOIN POITEMS ON PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO
					INNER JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY
					where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))			
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST('Work Order: '+MfgrVar.wono+'  '+RTRIM(sourcesubtable)+'.'+RTRIM(csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL))
	--					DRP 07/05/2012:  We dropped the gltrans_no field from the scraprel table during the vfp to sql conversion.  any SCRAP transaction that was generated before converting to SQL
	--					will be associated to that gltrans_no field that has now been removed.  These records will not be able to be back linked for reference on the GL Transaction reports. 			
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('Qty Trnsf: '+ CAST (scraprel.qtytransf as CHAR(10))+'   '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill)as varchar(100)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (SELECT CAST(rtrim(confgvar.vartype)+' Cost: ' +rtrim(gltrans.sourcetable)+'.'+RTRIM(gltrans.cidentifier)+': '+rtrim(cdrill)as varchar(100)) 
					FROm Inventor,confgvar where ConfgVar.UNIQCONF =RTRIM(glTRANSDETAILS.cDrill) and Inventor.UNIQ_KEY =RTRIM(confgvar.uniq_key))	
				WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKMST' THEN (SELECT CAST(RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) 
					FROm APCHKMST  where APCHKMST.APCHK_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))
				WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKDET'  THEN (SELECT case when apchkdet.invno <> '' then  CAST('Inv No: '+ RTRIM(APCHKDET.INVNO)+'   '+RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100))
						when apchkdet.INVNO = '' then CAST (rtrim(apchkdet.item_Desc) +'   '+RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) end
					FROm APCHKDET  where APCHKDET.APCKD_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))			
				--WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKMST' THEN (SELECT CAST(RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) 
				--	FROm APCHKMST  where APCHKMST.APCHK_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))
				--WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKDET' THEN (SELECT CAST('Inv No: '+ RTRIM(APCHKDET.INVNO)+'   '+RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) 
				--	FROm APCHKDET  where APCHKDET.APCKD_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))
				else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100)) 
			end as DetailRef
			--DRP 06/27/2012:	I had requested that we change the cSubIdentifier and cSubDrill to be the uniquear from the AROFFSET and APOFFSET tables.  
								--In order to attempt to display the Invoice and/or Prepay that each line matches to. 
								--But upon review Yelena found that we will be unable to do that because in the situation where there are multiple DM,Prepays,CM, etc. . . within the same Offset, there is no way of knowing which of these were applied to which Invoices.   

	FROM	GLTRANSHEADER  
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 


	WHERE	gltransheader.trans_no = @lcTransno
ELSE
	--					10/10/14 YS replace invtmfhd with 2 tables
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill,
			-- 01/05/17 VL added functional currency fields
			GlTransDetails.DEBITPR, GlTransDetails.CREDITPR, FF.Symbol AS FSymbol, PF.Symbol AS PSymbol
			,case WHEN gltransheader.TransactionType = 'APPREPAY' THEN (SELECT CAST('AP Offset: ' +Apoffset.uniq_save as varchar(80)) FROM apoffset where Apoffset.uniq_save = RTRIM(GlTransDetails.CDRILL) GROUP by UNIQ_SAVE)
				WHEN gltransheader.TransactionType = 'ARPREPAY' THEN (SELECT CAST('AR Offset: '+ rtrim(cdrill) as varchar(80)))
				WHEN gltransheader.TransactionType = 'ARWO' THEN (SELECT CAST('AR Write-Off: '+ rtrim(GLTRANSHEADER.sourcetable)+'.'+RTRIM(gltransheader.cidentifier)+': '+RTRIM(cdrill) as varchar(80))) 
				when gltransheader.TransactionType = 'CM' then (select cast('Customer: ' +RTRIM(CustName)+', Credit Memo: '+ rtrim(cmemono) as CHAR (80))from cmmain inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)
				WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CASE WHEN apchkmst.UNIQSUPNO = '' THEN CAST('Check Number: '+apchkmst.checkno + '  *No Supplier Assigned'  as varchar(80)) ELSE CAST('Supplier: '+rtrim(supinfo.supname)+'  '+'Check Number: '+apchkmst.checkno as varchar(80)) END  FROM APCHKMST left outer join SUPINFO on apchkmst.uniqsupno = supinfo.uniqsupno WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL))
				--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Supplier: '+rtrim(supinfo.supname)+'  '+'Check Number: '+checkno as varchar(80)) FROM APCHKMST,SUPINFO WHERE apchkmst.APCHK_UNIQ =RTRIM(gltransdetails.CDRILL) and SUPINFO.UNIQSUPNO = apchkmst.UNIQSUPNO)	--09/29/16 DRP:  replaced with the above to adress null values display in gthe GenrRef field if Uniqsupno was blank
				WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST('Work Order: '+Confgvar.wono+'  Qty Trns: '+cast(confgvar.qtytransf as varchar(17)) as varchar(80)) FROm CONFGVAR where Confgvar.UNIQCONF=RTRIM(GlTransDetails.CDRILL))
				when gltransheader.TransactionType = 'COSTADJ' AND GLTRANS.SourceSubTable = 'UPDTSTD' THEN (SELECT CAST('Cost Adjustment: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(cdrill)  as varchar(80))) 
				when gltransheader.TransactionType = 'COSTADJ' AND GLTRANS.SourceSubTable = 'INVENTOR' THEN (SELECT  CAST('Cost Adjustment: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(cdrill)  as varchar(80)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
				WHEN gltransheader.TransactionType = 'DEP' then cast('Deposit Number: ' + rtrim(cDrill) as varchar (80)) 
				WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast('Supplier: '+rtrim(supname)+', #'+rtrim(Dmemono)+'  Against Inv' as varchar(80)) 
					when dmemos.dmtype = 2 then cast ('Supplier: '+ rtrim(supname)+', #'+RTRIM(dmemono)+ '  Against Acct' as varchar(80)) end FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
				--WHEN gltransheader.TransactionType = 'DM' THEN (SELECT cast('Supplier: '+rtrim(supname)+', '+rtrim(Dmemono) as varchar(80)) FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  WHERE DMEMOS.UNIQDMHEAD  =RTRIM(gltransdetails.CDRILL))
				WHEN gltransheader.TransactionType = 'INVTISU' and gltrans.SourceSubTable = 'INVENTOR' THEN (SELECT  CAST('Inventory Issue: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill) as varchar (80)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
				WHEN gltransheader.TransactionType = 'INVTISU' AND gltrans.SourceSubTable ='INVT_ISU' THEN CAST('Inventory Issue: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(CDRILL) as varchar (80)) 
				WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVENTOR' THEN (SELECT  CAST('Inventory Receipt: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill) as varchar (80)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
				WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVT_REC' THEN CAST('Inventory Receipt: '+ RTRIM(GLTRANS.SOURCETABLE)+'.'+RTRIM(GLTRANS.CIDENTIFIER)+': '+RTRIM(CDRILL) as varchar (80)) 
				when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST('Inventory Transfer: ' + rtrim(inventor.part_no)+'/'+ RTRIM(inventor.revision)+'  '+ RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+RTRIM(GLTRANS.CSUBIDENTIFIER)+': '+ rtrim(cDrill)as Varchar(80))
				FROM INVENTOR,INVTTRNS,INVTMFGR,InvtMPNLink L 
					WHERE INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) 
					AND INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.CDRILL) 
					AND INVTTRNS.FROMWKEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)	
				WHEN gltransheader.TransactionType = 'JE' THEN (SELECT 'JE# '+cast(cast(rtrim(gljehdr.JE_NO) as char (6))+rtrim(gljehdr.JETYPE)+'  Reason: '+ rtrim(gljehdr.reason) as varCHAR (80)) FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
				when gltransheader.TransactionType = 'NSF' then (select 'NSF: '+cast(RTRIM(cdrill) + ' for Deposit Number: ' + rtrim(ARRETCK.DEP_NO)  as varchar(80)) from ARRETCK where gltransdetails.cdrill = arretck.UNIQRETNO) 
				WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT  CAST('Supplier: '+RTRIM(Supname)+', '+'Invoice Number: ' +INVNO as varchar(80)) FROM Apmaster inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO where apmaster.UNIQAPHEAD =RTRIM(GlTransDetails.CDRILL))  
				WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST('Receiver No: '+Sinvoice.receiverno+'  '+'Inv: '+sinvoice.INVNO as varchar(80)) 
					FROM SINVOICE 
					where Sinvoice.SINV_UNIQ =RTRIM(gltransdetails.cSubDrill)) 
				WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(80)) FROM Plmain inner join Customer on Plmain.custno = customer.CUSTNO where plmain.PACKLISTNO =RTRIM(GlTransDetails.CDRILL))
				WHEN gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST('UnReconciled Receipt: '+'Recv # '+Porecloc.RECEIVERNO  as varchar(80)) FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST(rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'inventor.uniq_key: '+RTRIM(mfgrvar.uniq_key) as varchar(80)) 
				FROm MFGRVAR,INVENTOR
				 where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL)
				 and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
	--					DRP 07/05/2012:  We dropped the gltrans_no field from the scraprel table during the vfp to sql conversion.  any SCRAP transaction that was generated before converting to SQL
	--					will be associated to that gltrans_no field that has now been removed.  These records will not be able to be back linked for reference on the GL Transaction reports. 			
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('Work Order: '+SCRAPREL.wono+'  '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) as varchar(80)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'PO: '+confgvar.ponum+' Qty: '+CAST(rtrim(confgvar.qtytransf) as CHAR(10)) as varchar(80)) 
					else cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'WO: '+confgvar.wono+' Qty: '+CAST(rtrim(confgvar.qtytransf) as CHAR(10)) as varchar (80))end 
					FROm Inventor,confgvar where ConfgVar.UNIQCONF =RTRIM(glTRANSDETAILS.cDrill) and Inventor.UNIQ_KEY =RTRIM(confgvar.uniq_key))
				WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(gltransdetails.CDRILL))
				ELSE CAST('Cannot Link back to source' as varchar(60))
			end as GenrRef  
			,case when gltransheader.TransactionType = 'ARWO' and gltrans.SourceSubTable = 'ACCTSREC' then (select CAST('Inv#: '+acctsrec.INVNO+'  '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill) as varchar(80)) 
						from ACCTSREC where acctsrec.uniquear=RTRIM(gltransdetails.CSubDRILL)) 
				 WHEN gltransheader.TransactionType = 'ARWO' and gltrans.SourceSubTable = 'AR_WO' then CAST('Cannot Link back to source' as varchar(80)) 
				when gltransheader.TransactionType = 'COSTADJ' AND GLTRANS.SourceSubTable = 'INVENTOR' THEN (SELECT  CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) +'   '+rtrim(gltrans.SourceSubTable)+'.'+RTRIM(gltrans.csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) FROm Inventor where Inventor.UNIQ_KEY =RTRIM(gltransdetails.CSubDRILL))
				when gltransheader.TransactionType = 'COSTADJ' AND GLTRANS.SourceSubTable = 'UPDTSTD' THEN CAST ('Cannot Link back to source' AS VARCHAR(80))
				when gltransheader.TransactionType = 'DEP' and SourceSubTable = 'ArCredit' then (select CAST('Inv#: '+rtrim(arcredit.INVNO) +'   '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(gltrans.cSubIdentifier)+': '+rtrim(cSubDrill) as varchar(100)) from ARCREDIT where arcredit.UNIQDETNO = gltransdetails.cSubDrill)
				when gltransheader.TransactionType = 'DEP' and SourceSubTable = 'Deposits' then (select CAST(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill) as varchar(100)) from deposits where deposits.dep_no = gltransdetails.cSubDrill)
				WHEN gltransheader.TransactionType = 'DM' and gltrans.SourceSubTable = 'APDMDETL' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast('Inv# '+RTRIM(dmemos.INVNO)+'  '+'Item #: '+rtrim(apdmdetl.ITEM_NO)+'  '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(80)) 
					WHEN DMEMOS.DMTYPE = 2 THEN cast('Item #'+rtrim(apdmdetl.ITEM_NO)+'  '+rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100)) END FROM apdmdetl inner join DMEMOS on apdmdetl.UNIQDMHEAD = dmemos.UNIQDMHEAD  WHERE apdmdetl.UNIQDMDETL  =RTRIM(gltransdetails.cSubDrill))
				when gltransheader.TransactionType = 'INVTISU' and gltrans.SourceSubTable = 'INVENTOR' then (SELECT CAST('MFGR: '+ RTRIM(M.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ 'invtmfgr.w_key: '+ rtrim(invtmfgr.w_key)AS VARCHAR(100)) 
					FROM INVENTOR,INVT_ISU,INVTMFGR,InvtMPNLink L, MfgrMaster M 
					WHERE L.mfgrMasterId=M.MfgrMasterId
					AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) AND INVT_ISU.INVTISU_NO = RTRIM(GLTRANSDETAILS.CDRILL) AND INVT_ISU.W_KEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)
				WHEN gltransheader.TransactionType = 'INVTISU' AND gltrans.SourceSubTable ='INVT_ISU' THEN CAST('Cannot Link back to source' as varchar (80)) 
				when gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVENTOR'  THEN (SELECT CAST('MFGR: '+ RTRIM(M.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ 'invtmfgr.w_key: '+ rtrim(invtmfgr.w_key)AS VARCHAR(100)) 
					FROM INVENTOR,INVT_REC,INVTMFGR,InvtMPNLink L, MfgrMaster M  
					WHERE L.mfgrMasterId=M.MfgrMasterId
					AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) AND INVT_REC.INVTREC_NO = RTRIM(GLTRANSDETAILS.CDRILL) AND INVT_REC.W_KEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)
				WHEN gltransheader.TransactionType = 'INVTREC' AND gltrans.SourceSubTable ='INVT_REC' THEN CAST('Cannot Link back to source' as varchar (80)) 
				when gltransheader.TransactionType = 'INVTTRNS' THEN (SELECT CAST('MFGR: '+ RTRIM(M.PARTMFGR)+'   MPN: '+RTRIM(MFGR_PT_NO)+'  '+ rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim (cdrill)AS VARCHAR(100)) 
					FROM INVENTOR,INVTTRNS,INVTMFGR,InvtMPNLink L, MfgrMaster M  
					WHERE L.mfgrMasterId=M.MfgrMasterId
					AND INVENTOR.UNIQ_KEY = RTRIM(GLTRANSDETAILS.CSUBDRILL) 
					AND INVTTRNS.INVTXFER_N = RTRIM(GLTRANSDETAILS.CDRILL) 
					AND INVTTRNS.FROMWKEY = INVTMFGR.W_KEY AND INVTMFGR.UNIQMFGRHD = L.UNIQMFGRHD)	
				when GLTRANSHEADER.TransactionType = 'PURVAR' THEN (SELECT CAST(rtrim(inventor.PART_NO)+'/'+rtrim(inventor.REVISION)+'  '+RTRIM(sourcesubtable)+'.'+RTRIM(csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) 
					from pur_var
					inner join SINVDETL on pur_var.SDET_UNIQ = sinvdetl.SDET_UNIQ 
					LEFT outer join POITEMS on sinvdetl.UNIQLNNO = poitems.UNIQLNNO
					inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
					where pur_Var.var_key = rtrim(gltransdetails.cdrill)) 	 
				WHEN gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST(RTRIM(Inventor.Part_no)+'/'+RTRIM(Inventor.Revision) +'  '+'Qty: '+rtrim(cast(PORecRelGl.TRANSQTY as CHAR(17))) + '  '+rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+': '+rtrim(cSubDrill)as varchar(100)) 
					FROM porecrelgl INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ
					INNER JOIN PORECDTL ON PORECLOC.FK_UNIQRECDTL = PORECDTL.UNIQRECDTL
					INNER JOIN POITEMS ON PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO
					INNER JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY
					where PorecRelGl.UNIQRECREL =RTRIM(gltransdetails.CDRILL))			
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST('Work Order: '+MfgrVar.wono+'  '+RTRIM(sourcesubtable)+'.'+RTRIM(csubidentifier)+': '+RTRIM(csubdrill) as varchar(100)) FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=RTRIM(GlTransDetails.CDRILL))
	--					DRP 07/05/2012:  We dropped the gltrans_no field from the scraprel table during the vfp to sql conversion.  any SCRAP transaction that was generated before converting to SQL
	--					will be associated to that gltrans_no field that has now been removed.  These records will not be able to be back linked for reference on the GL Transaction reports. 			
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('Qty Trnsf: '+ CAST (scraprel.qtytransf as CHAR(10))+'   '+ rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill)as varchar(100)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=RTRIM(gltransdetails.CDRILL)
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (SELECT CAST(rtrim(confgvar.vartype)+' Cost: ' +rtrim(gltrans.sourcetable)+'.'+RTRIM(gltrans.cidentifier)+': '+rtrim(cdrill)as varchar(100)) 
					FROm Inventor,confgvar where ConfgVar.UNIQCONF =RTRIM(glTRANSDETAILS.cDrill) and Inventor.UNIQ_KEY =RTRIM(confgvar.uniq_key))	
				WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKMST' THEN (SELECT CAST(RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) 
					FROm APCHKMST  where APCHKMST.APCHK_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))
				WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKDET'  THEN (SELECT case when apchkdet.invno <> '' then  CAST('Inv No: '+ RTRIM(APCHKDET.INVNO)+'   '+RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100))
						when apchkdet.INVNO = '' then CAST (rtrim(apchkdet.item_Desc) +'   '+RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) end
					FROm APCHKDET  where APCHKDET.APCKD_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))			
				--WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKMST' THEN (SELECT CAST(RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) 
				--	FROm APCHKMST  where APCHKMST.APCHK_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))
				--WHEN gltransheader.TransactionType = 'CHECKS' AND GLTRANS.SourceSubTable = 'APCHKDET' THEN (SELECT CAST('Inv No: '+ RTRIM(APCHKDET.INVNO)+'   '+RTRIM(GLTRANS.SOURCESUBTABLE)+'.'+ RTRIM(GLTRANS.CSUBIDENTIFIER)+RTRIM(CSUBDRILL) as varchar(100)) 
				--	FROm APCHKDET  where APCHKDET.APCKD_UNIQ = RTRIM(GLTRANSDETAILS.cSubDrill))
				else cast(rtrim(gltrans.SourceSubTable)+'.'+rtrim(csubidentifier)+':  '+rtrim(cSubDrill) as varchar(100)) 
			end as DetailRef
			--DRP 06/27/2012:	I had requested that we change the cSubIdentifier and cSubDrill to be the uniquear from the AROFFSET and APOFFSET tables.  
								--In order to attempt to display the Invoice and/or Prepay that each line matches to. 
								--But upon review Yelena found that we will be unable to do that because in the situation where there are multiple DM,Prepays,CM, etc. . . within the same Offset, there is no way of knowing which of these were applied to which Invoices.   

	FROM	GLTRANSHEADER  
				-- 01/05/17 VL added to show currency symbol
				INNER JOIN Fcused PF ON GLTRANSHEADER.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON GLTRANSHEADER.FuncFcused_uniq = FF.Fcused_uniq
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 


	WHERE	gltransheader.trans_no = @lcTransno
END