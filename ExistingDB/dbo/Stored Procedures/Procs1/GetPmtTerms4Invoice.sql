CREATE PROCEDURE dbo.GetPmtTerms4Invoice
	-- Add the parameters for the stored procedure here
	@gcInvNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Terms
		from PLMAIN 
		Where InvoiceNo = @gcInvNo
END