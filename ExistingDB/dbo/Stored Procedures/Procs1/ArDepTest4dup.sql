CREATE PROCEDURE dbo.ArDepTest4dup
	-- Add the parameters for the stored procedure here
	@gcInvNo as char(10) = ' '

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT InvNo FROM ARDEP where INVNO = @gcInvNo
END