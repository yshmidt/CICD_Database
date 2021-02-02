-- =============================================
-- Author:		David Sharp
-- Create date: 6/20/2013
-- Description:	update setting values
-- =============================================
CREATE PROCEDURE settingsUpdateValues 
	-- Add the parameters for the stored procedure here
	@moduleId int, 
	@settingName varchar(MAX),
	@settingValue varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    UPDATE MnxSettingsManagement SET settingValue=@settingValue
    WHERE moduleId=@moduleId AND settingName=@settingName
END