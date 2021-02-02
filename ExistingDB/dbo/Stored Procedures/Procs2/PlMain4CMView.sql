CREATE PROCEDURE [dbo].[PlMain4CMView] 
@gcInvoiceNo as CHAR(10) = ' ',@lcRemoveCMUnique char(10)=' '
-- 02/27/12 YS added second parameter, to calculate balance for the invoice, but remove amount for the current CM if any
-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 02/21/12 YS find sum of the closed credit memos for each invoice  
    -- 02/21/12 YS added invoice balance to display on the screen
    -- 02/21/12 YS added all the original amounts with prefix orig
	-- 03/13/15 VL added FC fields and fob, shipvia, SHIPCHARGE, ATTENTION, Plmain.TERMS
	-- 10/31/16 VL added PR fields
	-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
	SELECT plmain.custno,plmain.packlistno,plmain.invtotal-ISNULL(CM.SumCmTotal,0.00) as InvTotal,tottaxe-ISNULL(CM.SumCm_Tottaxe,0.00) as TotTaxE ,
	freightamt-ISNULL(cm.SumCm_Frt,0.00) as freightamt ,tottaxf-ISNULL(CM.SumCm_frt_tax,0.0) as TotTaxF, ISNULL(CM.SumCmTotal,0.00) as SumCmTotal, 
	plmain.INVOICENO,plmain.invdate,plmain.sono,totexten-ISNULL(cm.Sum_cmTotExten,0.00) as TotExten,inv_foot,linkadd,frt_gl_no,fc_gl_no,plmain.blinkadd ,
	-- 01/16/2020 YS added new column to plmain table pono for the manual invoice w/o sales order. Need to identify the table in the sql
	PlMain.dsctamt-ISNULL(SumCmdsctAmt,0.00) as dsctamt,disc_gl_no, Ar_Gl_No,CAST(ISNULL(Somain.PoNo,Plmain.Pono) as CHAR(20)) as PONO, Somain.OrderDate,Customer.CustName  ,ISNULL(CC.ClosedTotal,0.00) as ClosedTotal ,
	ACCTSREC.INVTOTAL as InvoiceTotal,ACCTSREC.Arcredits,plmain.tottaxe as OrigTotTaxe,plmain.freightamt as OrigFreightAmt,plmain.TotTaxF as OrigTotTaxF,
	PlMain.TotExten as OrigTotExten,PlMain.INVTOTAL as OrigInvTotal,PlMain.dsctamt as OrigDsctAmt,
	plmain.invtotalFC-ISNULL(CM.SumCmTotalFC,0.00) as InvTotalFC, tottaxeFC-ISNULL(CM.SumCm_TottaxeFC,0.00) as TotTaxEFC, 
	freightamtFC-ISNULL(cm.SumCm_FrtFC,0.00) as freightamtFC, tottaxfFC-ISNULL(CM.SumCm_frt_taxFC,0.0) as TotTaxFFC, 
	ISNULL(CM.SumCmTotalFC,0.00) as SumCmTotalFC, totextenFC-ISNULL(cm.Sum_cmTotExtenFC,0.00) as TotExtenFC, 
	PlMain.dsctamtFC-ISNULL(SumCmdsctAmtFC,0.00) as dsctamtFC, ISNULL(CC.ClosedTotalFC,0.00) as ClosedTotalFC, 
	ACCTSREC.INVTOTALFC as InvoiceTotalFC, ACCTSREC.ArcreditsFC, plmain.tottaxeFC as OrigTotTaxeFC, plmain.freightamtFC as OrigFreightAmtFC, 
	plmain.TotTaxFFC as OrigTotTaxFFC, PlMain.TotExtenFC as OrigTotExtenFC, PlMain.INVTOTALFC as OrigInvTotalFC, PlMain.dsctamtFC as OrigDsctAmtFC,
	Plmain.Fcused_uniq, Plmain.Fchist_key, fob, shipvia, SHIPCHARGE, ATTENTION, Plmain.TERMS,
	-- 10/31/16 VL added PR fields
	plmain.invtotalPR-ISNULL(CM.SumCmTotalPR,0.00) as InvTotalPR, tottaxePR-ISNULL(CM.SumCm_TottaxePR,0.00) as TotTaxEPR, 
	freightamtPR-ISNULL(cm.SumCm_FrtPR,0.00) as freightamtPR, tottaxfPR-ISNULL(CM.SumCm_frt_taxPR,0.0) as TotTaxFPR, 
	ISNULL(CM.SumCmTotalPR,0.00) as SumCmTotalPR, totextenPR-ISNULL(cm.Sum_cmTotExtenPR,0.00) as TotExtenPR, 
	PlMain.dsctamtPR-ISNULL(SumCmdsctAmtPR,0.00) as dsctamtPR, ISNULL(CC.ClosedTotalPR,0.00) as ClosedTotalPR, 
	ACCTSREC.INVTOTALPR as InvoiceTotalPR, ACCTSREC.ArcreditsPR, plmain.tottaxePR as OrigTotTaxePR, plmain.freightamtPR as OrigFreightAmtPR, 
	plmain.TotTaxFPR as OrigTotTaxFPR, PlMain.TotExtenPR as OrigTotExtenPR, PlMain.INVTOTALPR as OrigInvTotalPR, PlMain.dsctamtPR as OrigDsctAmtPR, Plmain.PRFcused_Uniq, Plmain.FUNCFCUSED_UNIQ
	FROM plmain LEFT OUTER JOIN SOMAIN ON plmain.SONO=somain.sono 
	INNER JOIN ACCTSREC ON plmain.CUSTNO=ACCTSREC.CUSTNO and plmain.INVOICENO=ACCTSREC.INVNO   
	INNER JOIN CUSTOMER ON Plmain.CUSTNO =Customer.Custno
	OUTER APPLY (SELECT Sum(Cm_Frt) as SumCm_Frt, Sum(tottaxe) as SumCm_Tottaxe,Sum(cm_frt_tax) as SumCm_frt_tax ,SUM(cmmain.CMTOTEXTEN) as Sum_cmTotExten ,SUM(cmmain.cmtotal) as SumCmTotal,
						SUM(cmmain.DSCTAMT) as SumCmdsctAmt,
						Sum(Cm_FrtFC) as SumCm_FrtFC, Sum(tottaxeFC) as SumCm_TottaxeFC,Sum(cm_frt_taxFC) as SumCm_frt_taxFC ,SUM(cmmain.CMTOTEXTENFC) as Sum_cmTotExtenFC ,SUM(cmmain.cmtotalFC) as SumCmTotalFC,
						SUM(cmmain.DSCTAMTFC) as SumCmdsctAmtFC,
						-- 10/31/16 VL added PR fields
						Sum(Cm_FrtPR) as SumCm_FrtPR, Sum(tottaxePR) as SumCm_TottaxePR,Sum(cm_frt_taxPR) as SumCm_frt_taxPR ,SUM(cmmain.CMTOTEXTENPR) as Sum_cmTotExtenPR ,SUM(cmmain.cmtotalPR) as SumCmTotalPR,
						SUM(cmmain.DSCTAMTPR) as SumCmdsctAmtPR
					FROM CMMAIN where cmmain.cStatus <> 'CANCELLED' and Cmmain.CUSTNO=plmain.CUSTNO and cmmain.INVOICENO =plmain.INVOICENO and CmMain.cmUnique<>@lcRemoveCMUnique) CM  
	OUTER APPLY
	-- 10/31/16 VL added PR fields
	(SELECT SUM(cmtotal) as ClosedTotal, SUM(cmtotalFC) as ClosedTotalFC, SUM(cmtotalPR) as ClosedTotalPR FROM CMMAIN where Cmmain.CUSTNO=plmain.CUSTNO and cmmain.INVOICENO =plmain.INVOICENO and CSTATUS='APPROVED') CC  				
	WHERE plmain.invoiceno = @gcInvoiceno 

END