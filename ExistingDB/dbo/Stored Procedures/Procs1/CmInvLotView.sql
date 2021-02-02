CREATE PROCEDURE [dbo].[CmInvLotView] 
	-- Add the parameters for the stored procedure here
@gcCmUnique AS Char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * 
	from CmInvLot
	where CmInvLot.cmUnique = @gcCmUnique

END


