-- =============================================
-- Author:		David Sharp
-- Create date: 4/27/2012
-- Description:	reset import detail flags
-- 02/19/14 DS added a reset to the validated flag
-- =============================================
CREATE PROCEDURE [dbo].[importBOMFullReset]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@reflag bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @fade varchar(20)='i02fade',@none varchar(20)='00none'
	IF @reflag = 1 
		UPDATE importBOMHeader SET isValidated = 0 WHERE importId = @importId

	UPDATE importBOMFields
		SET [status]=@fade,[validation]=@none,[message]='',adjusted=original,uniq_key=''
		WHERE fkImportId = @importId
	UPDATE importBOMAvl
		SET [status]=@fade,[validation]=@none,[message]='',uniqmfgrhd='',[load]=1,adjusted=original
		WHERE fkImportId = @importId
	DELETE FROM importBOMAvl
		WHERE original=''
END