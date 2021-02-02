-- =============================================
-- Author:		David Sharp
-- Create date: 6/4/2012
-- Description:	converts all default values to approved values
-- =============================================
CREATE PROCEDURE dbo.importBOMFullDefaultToApproved 
	-- Add the parameters for the stored procedure here
	@importId uniqueIdentifier 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE importBOMFields
		SET [status]='i01green',[message]='approved default',[validation]='03user'
		WHERE fkImportId=@importId AND [status]='i03blue'
	--@importId, @p2
END