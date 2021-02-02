CREATE PROCEDURE [dbo].[CmPriorTotal4InvoiceView]
	-- Add the parameters for the stored procedure here
	@gcInvoiceNo as char(10) = ' ' ,@gcCmemoNo char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 03/17/15 VL added FC fields
	-- 11/02/16 VL added PR fields
	SELECT ISNULL(sum(cmTotal),0.00) as CmTotalSum, ISNULL(sum(cmTotalFC),0.00) as CmTotalSumFC, ISNULL(sum(cmTotalPR),0.00) as CmTotalSumPR
		FROM CmMain 
		WHERE cmmain.InvoiceNo = @gcInvoiceNo
		AND cmmain.CMEMONO <>@gcCmemoNo 
		AND cStatus <> 'CANCELLED'
		
END
IF @@ERROR<>0 OR @@TRANCOUNT=0 BEGIN IF @@TRANCOUNT>0 ROLLBACK SET NOEXEC ON END