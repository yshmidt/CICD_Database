CREATE PROCEDURE dbo.ArDepositView 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
	FROM ARDEP
	WHERE REC_AMOUNT <> DEP_CREDIT 
END