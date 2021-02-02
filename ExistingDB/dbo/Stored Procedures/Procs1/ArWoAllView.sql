CREATE PROCEDURE dbo.ArWoAllView 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT AR_WO.*, ACCTSREC.INVNO, ACCTSREC.CUSTNO
		from AR_WO, ACCTSREC 
		where AR_WO.UNIQUEAR = ACCTSREC.UNIQUEAR
END