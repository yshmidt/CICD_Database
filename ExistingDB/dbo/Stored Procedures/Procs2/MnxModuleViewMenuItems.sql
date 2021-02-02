-- =============================================
-- Author:		David Sharp
-- Create date: 12/19/2011
-- Description:	Get a list of menu items for a module
-- =============================================
CREATE PROCEDURE [dbo].[MnxModuleViewMenuItems] 
	-- Add the parameters for the stored procedure here
	@moduleId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT resourceKey, [action], listOrder ,isTutorial
	FROM MnxModuleMenus
	WHERE fkmoduleId = @moduleId 
END
