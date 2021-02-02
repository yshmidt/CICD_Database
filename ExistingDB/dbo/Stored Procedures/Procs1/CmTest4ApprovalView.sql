CREATE PROCEDURE dbo.CmTest4ApprovalView
	-- Add the parameters for the stored procedure here
@gcCmUnique as Char(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT cAppvName 
		FROM CmMain 
		WHERE CmUnique = @gcCmUnique 
		and cStatus = 'APPROVED'

END