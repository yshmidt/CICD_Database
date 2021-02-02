CREATE PROCEDURE dbo.AcctsRec4CustView
	-- Add the parameters for the stored procedure here
	@gcCustNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * 
	FROM ACCTSREC 
	WHERE CUSTNO = @gcCustNo
END