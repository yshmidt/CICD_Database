CREATE PROCEDURE dbo.PlNote4ArAging
	-- Add the parameters for the stored procedure here
	@gcInvoiceNo as char(10) = " "
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Inv_Foot 
		FROM PlMain 
		WHERE InvoiceNo = @gcInvoiceNo
END