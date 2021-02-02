
-- =============================================
-- Author:		Debbie
-- Create date: 08/08/2012
-- Description:	Created for the Detailed Cross-tabbed Report for Fiscal Period
-- Reports Using Stored Procedure:  glxtab6.rpt
-- Modifications:	09/21/2012 DRP:  During testing it was reported that the Beginning Balances were not correct.  This was due to the fact that I was not finding the Prior Period End Date. 
--					09/26/2012 YS:	Yelena found that there were some changes that could be made to my original code to make it faster (particularly for larger data sets.) 
--									We replaced code where I was using Group By with the Select Distinct, plus some other changes.	
--					04/15/2013 DRP:  it was reported that for new inventory transfer transactions created in SQL that the X-tab reports were displaying the source as no back link found.  
--									upon review of the code and data files it was found that VFP was recording the TransactionType as "INVTTRANS" and new records in SQL were recording "INVTTRNS"
--									the original code was only looking for transactiontype of INVTTRANS and that is why it could not find the back link for new SQL records.  Below has been changed to look for "INVTTRNS". 
--					11/07/2014 DRP: found that the TransDescr field was not large enough in some cases and increased it from <<TransDescr varchar(100)>> to <<TransDescr varchar(110)>>		
--					02/19/2015 DRP: copied this over for the Clound Version.  Added the /*GL NUMBER LIST*/ and filter criteria for it. Added the SaveInit.				
--06/23/15 Ys modified glfiscalyrs table and proceudres
--					12/04/2015 DRP: added <<,RunningTotal =  BegBal + sum(debit-credit) over (partition by gl_nbr order by trans_dt range unbounded preceding) >> to the select statement at the end. 
-- 07/07/16 YS added identity column to fix the correct preceding record to calculate the correct running total
-- 07/28/16 DRP on 7/7 yelena helped by adding the identiry column, but we did not add it to the final selection in the procedure.  
--				I need to add this to the results so I could then use that within the form to make sure the results were in the correct order and displaying the correct ending (running total) on the form 
--					09/30/16 DRP:	 it was found that if the check records were generated for example from auto bank deductions where no supplier was associated with the apchkmst record that the GenrRef would then just return NULL as soon as it could not find a matching supplier      
--					11/16/16 DRP:	The BegBal was not calculating the same as the other GL reports. (example rptgltrialbalance or rptGlXtabWM)  
--									I believe it was due to the @lcPriorDate would select the Prior Period End date, but it would not include any records time stamped for the same date but a later time
--									Changed the @lcPriorDate to be the PriorEnd date + 1, then changed the Where statement  accordingly.   
--				    01/05/2017 VL:  added functional currency fields	
--					03/06/17 DRP:  added the sort order back so the XLS results match the Report form Results
--- 04/04/17 YS order by rownum the end result, to match the order in which running total was calculated
-- 09/27/17 VL fixed BegBalPR which took begbal incorrectly, should be begbalPR
-- 12/06/19 VL changed back to use table to calculate BegBal, not the temp table which only contains the data for selected date range, need to find data before current date range
-- =============================================
CREATE PROCEDURE [dbo].[rptGlXtabFyPeriodWM]
--declare		 
		 @lcGlNbr as varchar(max) = 'All'
		,@lcFy as char (4)= ''
		,@lnPeriod as int = ''
		,@userId uniqueidentifier= null
		
		
as
begin
SET NOCOUNT ON
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


--<<09/21/2012 DRP:  the below will find the priord Period EndDate so I can later use that to calculate the BegBal per GL account number
	--06/24/15 do not use fyrs use varibale below
	--declare @fyrs as table	(fk_fy_uniq char(10),FiscalYear char(4),Period numeric(2),EndDate date,fydtluniq uniqueidentifier,Pfk_fy_uniq char(10),PriorFy char(4)
	--						,PriorPeriod numeric (2),PriorEndDate date,Pfydtluniq uniqueidentifier)
	--Below will insert into the above @fyrs table the FY and Period the user selected and the Prior Period and/or Fiscal Year.  
	--We had to do this in case they have 13 periods or if the entry is for the first Period of the FY
	DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView 
	--06/23/15 get prior date
	declare @lcPriorDate as date
		--select @lcPriorDate = F1.EndDate from @T as F1 where exists (select 1 from @t f2 where f2.FiscalYr=@lcFy
		--						and f2.period=@lnPeriod and f2.rn-1=f1.rn)		--11/16/16 DRP:  replaced with the below +1
		 select @lcPriorDate = F1.EndDate + 1 from @T as F1 where exists (select 1 from @t f2 where f2.FiscalYr=@lcFy
									and f2.period=@lnPeriod and f2.rn-1=f1.rn)
	 
	--;
	--WITH tSeq 
	--	AS
	--	(
	--	select *,ROW_NUMBER() OVER (ORDER BY FiscalYr,Period) as nSeq from @T
	--	)
	--	,
	--	zFys as(
	--	SELECT	t3.fk_fy_uniq,t3.FiscalYr,t3.Period,t3.ENDDATE,t3.fyDtlUniq
	--			,t2.fk_fy_uniq as Pfk_fy_uniq,t2.FiscalYr as PriorFY,t2.Period as PriorPeriod,t2.enddate as PriorEndDate,t2.fyDtlUniq as Pfydtluniq 
	--			FROM tSeq t2,tSeq t3
	--	WHERE t2.nSeq = (SELECT nSeq-1 FROM tSeq t1 where t1.FiscalYr=@lcFy and t1.Period=@lnPeriod)
	--	and t3.nSeq = (select nSeq from tSeq t1 where t1.FiscalYr=@lcFy and t1.Period = @lnPeriod)

	--	)
	--insert @fyrs select * from zFys	
	--Declare the below so I can populate it with the Prior Period End Date that will be used later to calculate the Beg Bal.
	--declare @lcPriorDate as date
	--select @lcPriorDate = F1.PriorEndDate from @fyrs as F1
	
-- 01/05/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0	
	BEGIN
	--The main table that will contail the final results	
	-- 07/07/16 YS added identity column to fix the correct preceding record to calculate the correct running total
	declare @glxtab as table	(FY char (4),Period numeric (2),Trans_no int,TransactionType varchar(50),Post_Date smalldatetime,Trans_Dt smalldatetime
								,gl_nbr char(13),GL_Descr char (30),Debit numeric(14,2),Credit numeric (14,2),SourceTable varchar(25),Cidentifier char(30),cDrill varchar(50)
								,SourceSubTable varchar(25),cSubIdentifier char(30),cSubDrill varchar (50), TransDescr varchar(110),BegBal numeric(14,2),saveinit char(8),rownum int IDENTITY)
	--- 07/07/16 YS remove RTRIM from cdrill and cSubdrill, no need becuase of the varchar(). Will see if it makes the code run faster
	-- added index to gltransdetails table on cdrill							
	Insert @glxtab
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case 
				WHEN gltransheader.TransactionType = 'APPREPAY' THEn(SELECT CAST('AP Offset against Prepay: '+RTRIM(apmaster.ponum)  as varchar(100)) 
					FROM apmaster
					where apmaster.UNIQAPHEAD = GlTransDetails.cSubDrill)	
				WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'UniqueAr' THEN 
					(SELECT distinct CAST(CASE WHEN Acctsrec.lPrepay=1 THEN  'AR Offset using Prepay: '+ RTRIM(ACCTSREC.invno) 
					ELSE 'AR Offset against Prepay: '+ RTRIM(ACCTSREC.invno) END  as varchar(100))
					from AROFFSET , ACCTSREC 
					where aroffset.CTRANSACTION = gltransdetails.cDrill and acctsrec.uniquear = gltransdetails.csubdrill)
				WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'CTRANSACTION' 
					THEN (SELECT CAST(rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim(cDrill) as varchar(100)))
				when gltransheader.TransactionType = 'ARWO'  then (select CAST('Cust: '+rtrim(customer.custname)+'  Inv#: '+acctsrec.INVNO as varchar(100)) 
					from AR_WO
					INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR
					INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					where AR_WO.ARWOUNIQUE =gltransdetails.cDrill) 
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
				--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Check#: '+RTRIM(checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  Supp: '+rtrim(supinfo.supname) as varchar(100)) --09/30/16 DRP: Replaced with the above two Check Selection areas
				--	FROM APCHKMST
				--	INNER JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
				--	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
				--	 WHERE apchkmst.APCHK_UNIQ =gltransdetails.cDrill)
				
				when gltransheader.TransactionType = 'CM'  then (select cast('Customer: ' +RTRIM(CustName)+', Credit Memo: '+ rtrim(cmemono) as CHAR (80))
					from cmmain 
					inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)
				WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST('WO#: '+Confgvar.wono+'  Date: '+ cast(cast(confgvar.datetime as DATE)as varchar(10))+' Part/Rev: '+rtrim(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty Trns: '+ cast(CAST(qtytransf as numeric(12,0))as varchar(12)) as varchar(100)) 
					FROm CONFGVAR 
					inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY
					where Confgvar.UNIQCONF=gltransdetails.cDrill)
				when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST('PN/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+ '  QtyOH: '+ rtrim(updtstd.QTY_OH)+'  Old: '+rtrim(updtstd.OLDMATLCST)+'  New: '+RTRIM(updtstd.newmatlcst) as varchar(80))
					FROM UPDTSTD
					inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY
					where updtstd.UNIQ_UPDT = gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'DEP' then (select cast('Deposit Number: ' + rtrim(cDrill)+'  Bank Acct# '+RTRIM(deposits.bk_acct_no)  as varchar (100))	
					from DEPOSITS
					where deposits.DEP_NO = gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(Dmemono)+'  Supp: '+rtrim(supname)+', '+CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END+ '  Against Inv' as varchar(100)) 
					when dmemos.dmtype = 2 then cast (RTRIM(dmemono)+'  Supp: '+ rtrim(supname)+','+  CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END + '  Against Acct' as varchar(100)) end 
					FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  
					WHERE DMEMOS.UNIQDMHEAD  =gltransdetails.cDrill)
				WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'PO#: '+confgvar.ponum+'  Qty: '+cast(CAST(confgvar.QTYTRANSF as numeric(12,0))as varchar(12)) as varchar(100)) 
					else cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'WO#: '+confgvar.wono+'  Qty: '+ cast(CAST(confgvar.QTYTRANSF as numeric(12,0))as varchar(12)) as varchar (100))end 
					FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = gltransdetails.cDrill) 
				when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST ('PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) as varchar (100))
					FROm Invt_ISU
					inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY
					inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY
					inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
					--- 07/07/16 YS remove RTRIM from cdrill, no need becuase of the varchar(). Will see if it makes the code run faster
					where invt_isu.INVTISU_NO = gltransdetails.cdrill)
				WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST('PN/Rev: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(invt_rec.qtyrec)+'  Cost: '+RTRIM(invt_rec.stdcost) as varchar (100)) 
					FROm Invt_rec
					inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY
					inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY
					inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
					--- 07/07/16 YS remove RTRIM from cdrill, no need becuase of the varchar(). Will see if it makes the code run faster
					where INVT_REC.INVTREC_NO = gltransdetails.cdrill)
	--			04/15/2013 DRP: needed to look for INVTTRNS in sql
				--when gltransheader.TransactionType = 'INVTTRANS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) as varchar (100))
				when gltransheader.TransactionType ='INVTTRNS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) as varchar (100))
					FROM INVTTRNS
					INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY
					WHERE INVTTRNS.INVTXFER_N = gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(rtrim(gljehdr.JETYPE)+' JE# '+cast(rtrim(gljehdr.JE_NO) as char (6))+'  Reason: '+RTRIM(GLJEHDR.REASON) as varCHAR (100)) 
					FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST('WO#: '+RTRIM(MFGRVAR.WONO)+'  Date:'+cast(cast(mfgrvar.datetime as DATE)as varchar(10))+'  Part/Rev: '+rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+' Desc: '+RTRIM(inventor.descript) as varchar(100)) 
					FROm MFGRVAR,INVENTOR
					--- 07/07/16 YS remove RTRIM from cdrill, no need becuase of the varchar(). Will see if it makes the code run faster
					where MFGRVAR.UNIQMFGVAR=GlTransDetails.CDRILL
					and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
				when gltransheader.TransactionType = 'NSF' then (select 'NSF: '+cast(RTRIM(cdrill) + ' for Dep#: ' + rtrim(ARRETCK.DEP_NO)+'  Receipt Advice: '+RTRIM(arretck.rec_advice)+'  Cust: '+RTRIM(custname)  as varchar(100)) 
					from ARRETCK
					inner join CUSTOMER on arretck.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = arretck.UNIQRETNO) 
				WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(' Inv#: '+rtrim(apmaster.invno)+'  PO#: '+rtrim(apmaster.ponum)+ '  Supp: '+RTRIM(Supname)  as varchar(100)) 
					FROM Apmaster 
					inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 
					where apmaster.UNIQAPHEAD =gltransdetails.cDrill)  
				WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST('Recv#: '+rtrim(Sinvoice.receiverno)+'  '+'Inv#: '+rtrim(sinvoice.INVNO)+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) as varchar(100)) 
					FROM pur_var
					inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ
					inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ
					inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO
					inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
					where pur_var.VAR_KEY =gltransdetails.cDrill) 
				WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) 
					FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(100)) 
					FROM Plmain 
					inner join Customer on Plmain.custno = customer.CUSTNO 
					where plmain.PACKLISTNO =gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('WO#: '+SCRAPREL.wono+'  Date: '+ cast(cast(SCRAPREL.datetime as DATE)as varchar(10))+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+cast(CAST(scraprel.QTYTRANSF as numeric(12,0))as varchar(12))+'  Cost: '+cast(scraprel.stdcost as varchar(17)) as varchar(100)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=gltransdetails.cDrill
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST('Recv# '+Porecloc.RECEIVERNO+'  '+'PO# '+RTRIM(poitems.ponum)+'  CO# '+RTRIM(pomain.conum)+'  Item# '+RTRIM(poitems.ITEMNO)+'  Supp:'+RTRIM(supinfo.supname)  as varchar(100)) 
					FROM porecrelgl 
					INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 
					inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL
					inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno
					inner join POMAIN on poitems.PONUM = pomain.ponum
					inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
					where PorecRelGl.UNIQRECREL =gltransdetails.cDrill)
				ELSE CAST('Cannot Link back to source' as varchar(100))
				end as GenrRef
				,ISNULL(b.begbal,0.00) as BegBal ,SAVEINIT	

	FROM	GLTRANSHEADER  
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
			left outer JOIN (select	G.GL_NBR,SUM(g.debit-g.Credit) as BegBal
						-- 12/06/19 VL changed back to use table to calculate BegBal, not the temp table which only contains the data for selected date range, need to find data before current date range
						FROM	GLTRANSHEADER GH2
								inner join Gltrans G on GH2.GLTRANSUNIQUE =G.Fk_GLTRansUnique 
	--<< 09/21/2012:  Added the gltransheader.trans_dt <= @lcPriorDate and removed the @lcFy and @lcPeriod from below								
						where	GH2.trans_dt < @lcPriorDate group by g.GL_NBR) B ON b.gl_nbr=gltrans.gl_nbr	--11/16/16 DRP:  change the .... gltransheader.trans_dt <= @lcPriorDate to be  gltransheader.trans_dt < @lcPriorDate 
									--gltransheader.fy = @lcFy
									--and gltransheader.PERIOD = @lcPeriod

	where
	--06/23/15 ys use exists	
	exists (select 1 from @GLNumber G1 where g1.gl_nbr=GLTRANS.GL_NBR)
	--1 = case when gltrans.GL_NBR in (select gl_nbr from @GLNumber ) then 1 else 0 end
			and GLTRANSHEADER.fy=@lcfy 
			AND GLTRANSHEADER.period = @lnPeriod
	--06/23/15 YS no need for this order by		
	-- 07/07/16 YS added identity column to fix the correct preceding record to calculate the correct running total. Added order by to have correct sequence
	order by gl_nbr,trans_no,trans_dt
	-- 09/26/2012 DRP:  UPdate the table with the license information
	
	-- 07/07/16 YS added identity column to fix the correct preceding record to calculate the correct running total

	select	fy,period,post_date,trans_no,Trans_Dt,TransactionType,gl_nbr,debit,credit,TransDescr,saveinit,GL_Descr,BegBal
			,RunningTotal =  BegBal + sum(debit-credit) over (partition by gl_nbr order by rownum range unbounded preceding)	--12/04/15 DRP:  added
			,SourceTable,Cidentifier,cDrill,SourceSubTable,cSubIdentifier,cSubDrill
			,rownum	--07/28/16 DRP:  added the rownum to the final results so we could fix the report form. 
	from	@glxtab
	--- 04/04/17 YS order by rownum the end result, to match the order in which running total was calculated
	order by rownum
	--order by gl_nbr,Trans_dt,Trans_no
	END
ELSE
	BEGIN
	--The main table that will contail the final results	
	-- 07/07/16 YS added identity column to fix the correct preceding record to calculate the correct running total
	-- 01/05/2017 VL: added functional currency fields
	declare @glxtabFC as table	(FY char (4),Period numeric (2),Trans_no int,TransactionType varchar(50),Post_Date smalldatetime,Trans_Dt smalldatetime
								,gl_nbr char(13),GL_Descr char (30),Debit numeric(14,2),Credit numeric (14,2),SourceTable varchar(25),Cidentifier char(30),cDrill varchar(50)
								,SourceSubTable varchar(25),cSubIdentifier char(30),cSubDrill varchar (50), TransDescr varchar(110),BegBal numeric(14,2),saveinit char(8),
								-- 01/05/2017 VL: added functional currency fields
								DebitPR numeric(14,2),CreditPR numeric (14,2), BegBalPR numeric(14,2), FSymbol char(3), PSymbol char(3),
								rownum int IDENTITY)
	--- 07/07/16 YS remove RTRIM from cdrill and cSubdrill, no need becuase of the varchar(). Will see if it makes the code run faster
	-- added index to gltransdetails table on cdrill							
	Insert @glxtabFC
	SELECT	GLTRANSHEADER.FY,GLTRANSHEADER.PERIOD ,GLTRANSHEADER.TRANS_NO,GltransHeader.TransactionType,GLTRANSHEADER.POST_DATE,GLTRANSHEADER.TRANS_DT,
			gltrans.GL_NBR,gl_nbrs.GL_DESCR,GlTransDetails.DEBIT, GlTransDetails.CREDIT, gltrans.SourceTable, gltrans.CIDENTIFIER,gltransdetails.cDrill
			,gltrans.SourceSubTable,gltrans.cSubIdentifier,GlTransDetails.cSubDrill
			,case 
				WHEN gltransheader.TransactionType = 'APPREPAY' THEn(SELECT CAST('AP Offset against Prepay: '+RTRIM(apmaster.ponum)  as varchar(100)) 
					FROM apmaster
					where apmaster.UNIQAPHEAD = GlTransDetails.cSubDrill)	
				WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'UniqueAr' THEN 
					(SELECT distinct CAST(CASE WHEN Acctsrec.lPrepay=1 THEN  'AR Offset using Prepay: '+ RTRIM(ACCTSREC.invno) 
					ELSE 'AR Offset against Prepay: '+ RTRIM(ACCTSREC.invno) END  as varchar(100))
					from AROFFSET , ACCTSREC 
					where aroffset.CTRANSACTION = gltransdetails.cDrill and acctsrec.uniquear = gltransdetails.csubdrill)
				WHEN gltransheader.TransactionType = 'ARPREPAY' and gltrans.cSubIdentifier = 'CTRANSACTION' 
					THEN (SELECT CAST(rtrim(gltrans.SourceTable)+'.'+rtrim(gltrans.CIDENTIFIER)+': '+rtrim(cDrill) as varchar(100)))
				when gltransheader.TransactionType = 'ARWO'  then (select CAST('Cust: '+rtrim(customer.custname)+'  Inv#: '+acctsrec.INVNO as varchar(100)) 
					from AR_WO
					INNER JOIN ACCTSREC ON AR_WO.UniqueAR = ACCTSREC.UNIQUEAR
					INNER JOIN CUSTOMER ON ACCTSREC.CUSTNO = CUSTOMER.CUSTNO
					where AR_WO.ARWOUNIQUE =gltransdetails.cDrill) 
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
				--WHEN gltransheader.TransactionType = 'CHECKS' THEN (SELECT CAST('Check#: '+RTRIM(checkno)+'  Bank Acct# '+RTRIM(BANKS.BK_ACCT_NO)+'  Supp: '+rtrim(supinfo.supname) as varchar(100)) --09/30/16 DRP: Replaced with the above two Check Selection areas
				--	FROM APCHKMST
				--	INNER JOIN SUPINFO ON APCHKMST.UNIQSUPNO = SUPINFO.UNIQSUPNO
				--	INNER JOIN BANKS ON APCHKMST.BK_UNIQ = BANKS.BK_UNIQ
				--	 WHERE apchkmst.APCHK_UNIQ =gltransdetails.cDrill)
				when gltransheader.TransactionType = 'CM'  then (select cast('Customer: ' +RTRIM(CustName)+', Credit Memo: '+ rtrim(cmemono) as CHAR (80))
					from cmmain 
					inner join Customer on cmmain.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = cmmain.cmunique)
				WHEN GLTRANSHEADER.TransactionType = 'CONFGVAR' THEN (SELECT CAST('WO#: '+Confgvar.wono+'  Date: '+ cast(cast(confgvar.datetime as DATE)as varchar(10))+' Part/Rev: '+rtrim(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty Trns: '+ cast(CAST(qtytransf as numeric(12,0))as varchar(12)) as varchar(100)) 
					FROm CONFGVAR 
					inner join INVENTOR on confgvar.UNIQ_KEY = inventor.UNIQ_KEY
					where Confgvar.UNIQCONF=gltransdetails.cDrill)
				when gltransheader.TransactionType = 'COSTADJ' THEN (SELECT CAST('PN/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+ '  QtyOH: '+ rtrim(updtstd.QTY_OH)+'  Old: '+rtrim(updtstd.OLDMATLCST)+'  New: '+RTRIM(updtstd.newmatlcst) as varchar(80))
					FROM UPDTSTD
					inner join INVENTOR on updtstd.UNIQ_KEY = inventor.UNIQ_KEY
					where updtstd.UNIQ_UPDT = gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'DEP' then (select cast('Deposit Number: ' + rtrim(cDrill)+'  Bank Acct# '+RTRIM(deposits.bk_acct_no)  as varchar (100))	
					from DEPOSITS
					where deposits.DEP_NO = gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'DM' THEN (SELECT CASE WHEN DMEMOS.DMTYPE = 1 THEN cast(rtrim(Dmemono)+'  Supp: '+rtrim(supname)+', '+CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END+ '  Against Inv' as varchar(100)) 
					when dmemos.dmtype = 2 then cast (RTRIM(dmemono)+'  Supp: '+ rtrim(supname)+','+  CASE WHEN DMEMOS.PONUM = '' THEN '' ELSE '  PO#:'+RTRIM(DMEMOS.PONUM)END + '  Against Acct' as varchar(100)) end 
					FROM dmemos inner join SUPINFO on DMEMOS.uniqsupno = supinfo.UNIQSUPNO  
					WHERE DMEMOS.UNIQDMHEAD  =gltransdetails.cDrill)
				WHEN GLTRANSHEADER.TransactionType = 'INVTCOSTS' THEN (select case when confgvar.wono = 'PORecon' then cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'PO#: '+confgvar.ponum+'  Qty: '+cast(CAST(confgvar.QTYTRANSF as numeric(12,0))as varchar(12)) as varchar(100)) 
					else cast (rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+'  '+'WO#: '+confgvar.wono+'  Qty: '+ cast(CAST(confgvar.QTYTRANSF as numeric(12,0))as varchar(12)) as varchar (100))end 
					FROm confgvar LEFT OUTER JOIN INVENTOR ON confgvar.uniq_key = inventor.uniq_key  where CONFGVAR.UNIQCONF = gltransdetails.cDrill) 
				when gltransheader.TransactionType = 'INVTISU' THEN (SELECT CAST ('PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(INVT_ISU.QTYISU )+'  Cost: '+RTRIM(invt_ISU.stdcost) as varchar (100))
					FROm Invt_ISU
					inner join INVENTOR on invt_ISU.UNIQ_KEY = inventor.UNIQ_KEY
					inner join INVTMFGR on invt_ISU.W_KEY = invtmfgr.W_KEY
					inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
					--- 07/07/16 YS remove RTRIM from cdrill, no need becuase of the varchar(). Will see if it makes the code run faster
					where invt_isu.INVTISU_NO = gltransdetails.cdrill)
				WHEN gltransheader.TransactionType = 'INVTREC' THEN (SELECT  CAST('PN/Rev: '+ RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  '+'Wh: '+RTRIM(warehous.WAREHOUSE)+'  Qty: '+RTRIM(invt_rec.qtyrec)+'  Cost: '+RTRIM(invt_rec.stdcost) as varchar (100)) 
					FROm Invt_rec
					inner join INVENTOR on invt_rec.UNIQ_KEY = inventor.UNIQ_KEY
					inner join INVTMFGR on invt_rec.W_KEY = invtmfgr.W_KEY
					inner join WAREHOUS on invtmfgr.UNIQWH = warehous.UNIQWH
					--- 07/07/16 YS remove RTRIM from cdrill, no need becuase of the varchar(). Will see if it makes the code run faster
					where INVT_REC.INVTREC_NO = gltransdetails.cdrill)
	--			04/15/2013 DRP: needed to look for INVTTRNS in sql
				--when gltransheader.TransactionType = 'INVTTRANS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) as varchar (100))
				when gltransheader.TransactionType ='INVTTRNS' THEN (SELECT CAST (RTRIM(INVTTRNS.REASON)+'  PN/Rev: ' + RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+RTRIM(invtTRNS.QTYXFER)+'  Cost: '+RTRIM(INVTTRNS.stdcost) as varchar (100))
					FROM INVTTRNS
					INNER JOIN INVENTOR ON INVTTRNS.UNIQ_KEY = INVENTOR.UNIQ_KEY
					WHERE INVTTRNS.INVTXFER_N = gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'JE' THEN (SELECT cast(rtrim(gljehdr.JETYPE)+' JE# '+cast(rtrim(gljehdr.JE_NO) as char (6))+'  Reason: '+RTRIM(GLJEHDR.REASON) as varCHAR (100)) 
					FROM  GLJEHDR WHERE gltransdetails.cDrill = gljehdr.UNIQJEHEAD)
				WHEN gltransheader.TransactionType = 'MFGRVAR' THEN (SELECT CAST('WO#: '+RTRIM(MFGRVAR.WONO)+'  Date:'+cast(cast(mfgrvar.datetime as DATE)as varchar(10))+'  Part/Rev: '+rtrim(inventor.part_no)+'/'+rtrim(inventor.revision)+' Desc: '+RTRIM(inventor.descript) as varchar(100)) 
					FROm MFGRVAR,INVENTOR
					--- 07/07/16 YS remove RTRIM from cdrill, no need becuase of the varchar(). Will see if it makes the code run faster
					where MFGRVAR.UNIQMFGVAR=GlTransDetails.CDRILL
					and inventor.UNIQ_KEY = mfgrvar.UNIQ_KEY)
				when gltransheader.TransactionType = 'NSF' then (select 'NSF: '+cast(RTRIM(cdrill) + ' for Dep#: ' + rtrim(ARRETCK.DEP_NO)+'  Receipt Advice: '+RTRIM(arretck.rec_advice)+'  Cust: '+RTRIM(custname)  as varchar(100)) 
					from ARRETCK
					inner join CUSTOMER on arretck.CUSTNO = customer.CUSTNO where gltransdetails.cdrill = arretck.UNIQRETNO) 
				WHEN gltransheader.TransactionType = 'PURCH' THEN (SELECT CAST(' Inv#: '+rtrim(apmaster.invno)+'  PO#: '+rtrim(apmaster.ponum)+ '  Supp: '+RTRIM(Supname)  as varchar(100)) 
					FROM Apmaster 
					inner join Supinfo on apmaster.UNIQSUPNO = supinfo.UNIQSUPNO 
					where apmaster.UNIQAPHEAD =gltransdetails.cDrill)  
				WHEN gltransheader.TransactionType = 'PURVAR' THEN (SELECT CAST('Recv#: '+rtrim(Sinvoice.receiverno)+'  '+'Inv#: '+rtrim(sinvoice.INVNO)+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision) as varchar(100)) 
					FROM pur_var
					inner join SINVDETL on Pur_Var.sdet_UNIQ = sinvdetl.SDET_UNIQ
					inner join SINVOICE on sinvdetl.sinv_uniq = sinvoice.SINV_UNIQ
					inner join POITEMS on sinvdetl.UNIQLNNO = POITEMS.UNIQLNNO
					inner join INVENTOR on poitems.UNIQ_KEY = inventor.UNIQ_KEY
					where pur_var.VAR_KEY =gltransdetails.cDrill) 
				WHEN gltransheader.TransactionType = 'ROUNDVAR' THEN (SELECT CAST('Rounding Variance for WO#: '+mfgrvar.WONO  as varchar(80)) 
					FROm MFGRVAR  where MFGRVAR.UNIQMFGVAR=gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'SALES' THEN (SELECT  CAST('Customer: '+RTRIM(CustName)+', Invoice: '+InvoiceNo as varchar(100)) 
					FROM Plmain 
					inner join Customer on Plmain.custno = customer.CUSTNO 
					where plmain.PACKLISTNO =gltransdetails.cDrill)
				WHEN gltransheader.TransactionType = 'SCRAP' THEN (SELECT CAST('WO#: '+SCRAPREL.wono+'  Date: '+ cast(cast(SCRAPREL.datetime as DATE)as varchar(10))+'  Part/Rev: '+RTRIM(inventor.part_no)+'/'+RTRIM(inventor.revision)+'  Qty: '+cast(CAST(scraprel.QTYTRANSF as numeric(12,0))as varchar(12))+'  Cost: '+cast(scraprel.stdcost as varchar(17)) as varchar(100)) 
					FROM SCRAPREL,INVENTOR
					where ScrapRel.TRANS_NO=gltransdetails.cDrill
					and inventor.UNIQ_KEY = scraprel.UNIQ_KEY)
				when gltransheader.TransactionType = 'UNRECREC' THEN (SELECT CAST('Recv# '+Porecloc.RECEIVERNO+'  '+'PO# '+RTRIM(poitems.ponum)+'  CO# '+RTRIM(pomain.conum)+'  Item# '+RTRIM(poitems.ITEMNO)+'  Supp:'+RTRIM(supinfo.supname)  as varchar(100)) 
					FROM porecrelgl 
					INNER JOIN PORECLOC ON Porecloc.LOC_UNIQ = Porecrelgl.LOC_UNIQ 
					inner join PORECDTL on porecloc.FK_UNIQRECDTL = porecdtl.UNIQRECDTL
					inner join POitems on porecdtl.UNIQLNNO = poitems.uniqlnno
					inner join POMAIN on poitems.PONUM = pomain.ponum
					inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
					where PorecRelGl.UNIQRECREL =gltransdetails.cDrill)
				ELSE CAST('Cannot Link back to source' as varchar(100))
				end as GenrRef
				,ISNULL(b.begbal,0.00) as BegBal ,SAVEINIT,	
				-- 01/05/17 VL added functional currency fields
				-- 09/27/17 VL fixed BegBalPR which took begbal incorrectly, should be begbalPR
				GlTransDetails.DEBITPR, GlTransDetails.CREDITPR, ISNULL(b.begbalPR,0.00) as BegBalPR, FF.Symbol AS FSymbol, PF.Symbol AS PSymbol

	FROM	GLTRANSHEADER  
				-- 01/05/17 VL added to show currency symbol
				INNER JOIN Fcused PF ON GLTRANSHEADER.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON GLTRANSHEADER.FuncFcused_uniq = FF.Fcused_uniq
			inner join gltrans on gltransheader.GLTRANSUNIQUE =GlTrans.Fk_GLTRansUnique 
			inner join GlTransDetails on gltrans.GLUNIQ_KEY =GlTransDetails.fk_gluniq_key  
			inner join GL_NBRS on gltrans.GL_NBR = gl_nbrs.GL_NBR 
			-- 09/27/17 VL added BegBalPR
			left outer JOIN (select	G.GL_NBR,SUM(g.debit-g.Credit) as BegBal, SUM(g.debitPR-g.CreditPR) as BegBalPR
						-- 12/06/19 VL changed back to use table to calculate BegBal, not the temp table which only contains the data for selected date range, need to find data before current date range
						FROM	GLTRANSHEADER GH2
								inner join Gltrans G on GH2.GLTRANSUNIQUE =G.Fk_GLTRansUnique 
	--<< 09/21/2012:  Added the gltransheader.trans_dt <= @lcPriorDate and removed the @lcFy and @lcPeriod from below								
						where	GH2.trans_dt < @lcPriorDate group by g.GL_NBR) B ON b.gl_nbr=gltrans.gl_nbr	--11/16/16 DRP:  change the .... gltransheader.trans_dt <= @lcPriorDate to be  gltransheader.trans_dt < @lcPriorDate 
									--gltransheader.fy = @lcFy
									--and gltransheader.PERIOD = @lcPeriod

	where
	--06/23/15 ys use exists	
	exists (select 1 from @GLNumber G1 where g1.gl_nbr=GLTRANS.GL_NBR)
	--1 = case when gltrans.GL_NBR in (select gl_nbr from @GLNumber ) then 1 else 0 end
			and GLTRANSHEADER.fy=@lcfy 
			AND GLTRANSHEADER.period = @lnPeriod
	--06/23/15 YS no need for this order by		
	-- 07/07/16 YS added identity column to fix the correct preceding record to calculate the correct running total. Added order by to have correct sequence
	order by gl_nbr,trans_no,trans_dt
	-- 09/26/2012 DRP:  UPdate the table with the license information
	
	-- 07/07/16 YS added identity column to fix the correct preceding record to calculate the correct running total

	select	fy,period,post_date,trans_no,Trans_Dt,TransactionType,gl_nbr,debit,credit,TransDescr,saveinit,GL_Descr,BegBal
			,RunningTotal =  BegBal + sum(debit-credit) over (partition by gl_nbr order by rownum range unbounded preceding)	--12/04/15 DRP:  added
			,SourceTable,Cidentifier,cDrill,SourceSubTable,cSubIdentifier,cSubDrill
			,rownum	--07/28/16 DRP:  added the rownum to the final results so we could fix the report form. 
			-- 01/05/17 VL added functional currency fields
			,debitPR,creditPR, BegBalPR
			,RunningTotalPR =  BegBalPR + sum(debitPR-creditPR) over (partition by gl_nbr order by rownum range unbounded preceding)
			,FSymbol, PSymbol
	from	@glxtabFC
	---order by gl_nbr,Trans_dt,Trans_no	--03/06/17 DRP:  added the sort order back so the XLS results match the Report form Results
	--- 04/04/17 YS order by rownum the end result, to match the order in which running total was calculated
	order by rownum
	END
END

end		
		