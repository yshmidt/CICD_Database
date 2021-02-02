CREATE PROCEDURE [dbo].[ApBatchView]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/13/15 VL added FC fields
	-- 01/13/17 VL added PR fields
	-- 03/09/17 VL added Bank_BalPR field that was missed when I added PR on 01/13/17
SELECT Apbatch.batchuniq, Apbatch.batch_date, Apbatch.batch_tot,
  Apbatch.is_edited, Apbatch.is_closed, Apbatch.bk_uniq,
  Apbatch.batchdescr, Banks.bank, Banks.bk_acct_no, Banks.accttitle,
  Apbatch.datepaid, Banks.bank_bal,APBATCH.RecVer, 
  ApBatch.batch_totFC, ApBatch.Fcused_uniq, ApBatch.Fchist_key, ApBatch.PmtType, ApBatch.PmtCurrency, Banks.bank_balFC, Banks.Currency,
  -- 01/13/17 VL added PR fields
  ApBatch.Batch_TotPR, Banks.Bank_BalPR, Apbatch.PRFcused_uniq, Apbatch.FuncFcused_uniq
 FROM 
     apbatch 
    LEFT OUTER JOIN Banks 
  on  Apbatch.bk_uniq = Banks.bk_uniq
  where APBATCH.IS_CLOSED = 0

END