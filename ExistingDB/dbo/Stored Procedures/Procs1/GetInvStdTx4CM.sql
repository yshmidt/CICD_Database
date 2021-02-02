CREATE PROCEDURE dbo.GetInvStdTx4CM
	-- Add the parameters for the stored procedure here
	@gcPacklistNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Tax_Id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_Rate 
		FROM INVSTDTX
		WHERE PackListNo = @gcPacklistNo
			and INVOICENO = ' ' 
			and TAX_TYPE = 'C'
			
END