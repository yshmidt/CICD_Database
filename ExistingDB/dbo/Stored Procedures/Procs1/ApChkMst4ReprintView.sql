CREATE PROCEDURE [dbo].[ApChkMst4ReprintView] 
	-- Add the parameters for the stored procedure here
	@gcBatchUniq AS char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 09/04/12 YS added new column to save if the checks were cleared or reconciled
	-- 07/29/15 VL added FC fields
	-- 02/20/17 VL added functional currency code
	-- 10/15/20 VL added AcctNo Zendesk# 6643 customer request to add
		SELECT CAST(1 as bit) AS Yesno, ApchkMst.CheckNo,  ApchkMst.CheckDate, ApchkMst.CheckAmt, 
			ApchkMst.Status, ApchkMst.UniqSupNo,ApchkMst.Bk_Uniq, apchkmst.BK_ACCT_NO, apchkmst.R_Link , ApchkMst.ApChk_Uniq ,
			Supinfo.Supname ,ISNULL(ShipBill.Shipto,Supinfo.Supname) as Payee, ApchkMst.CheckAmtFC, ApchkMst.CheckAmtPR, Supinfo.AcctNo
		FROM ApchkMst INNER JOIN SUPINFO on ApchkMst.UNIQSUPNO=Supinfo.UNIQSUPNO 
		LEFT OUTER JOIN SHIPBILL ON ApchkMst.R_LINK =ShipBill.LINKADD 
		WHERE BatchUniq = @gcBatchUniq 
		and ApchkMst.Status IN(' ','Open','Printed/OS')  
		and apchkmst.ReconcileStatus =' '
		and Apchkmst.CHECKAMT <>0
		and Apchkmst.BATCHUNIQ <>' '	
		and Apchkmst.BATCHUNIQ+ApchkMst.CheckNo+ApchkMst.UniqSupNo+ApchkMst.Bk_Uniq 
		NOT IN (SELECT BATCHUNIQ+CheckNo+UniqSupNo+Bk_Uniq FROM ApchkMst WHERE  ApchkMst.Status='Voiding Entry')
END