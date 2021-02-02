CREATE PROCEDURE dbo.GetTotalCMs4InvNo
	-- Add the parameters for the stored procedure here
	@gcInvoiceNo as char(10)= ' ', @gcCmemoNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT SUM(Cmtotal) AS CmTotalSum 
		FROM Cmmain 
		WHERE Invoiceno = @gcInvoiceNo
		AND Cmemono <> @gcCmemoNo
		AND cStatus <> 'CANCELLED' 

END