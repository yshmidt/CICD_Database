CREATE PROCEDURE dbo.Test4CMStatus
	-- Add the parameters for the stored procedure here
	@gcCmemoNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT cStatus 
		from CMMAIN 
		WHERE CMEMONO = @gcCmemoNo
END