-- =============================================
-- Author:		David Sharp
-- Create date: 4/27/2012
-- Description:	reset import detail flags
-- =============================================
CREATE PROCEDURE [dbo].[importBOMRowAllErrorsReset]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,@rowId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE importBOMFields
		SET [status]='i02fade',[validation]='00none',[message]='',uniq_key=''
		WHERE fkImportId = @importId AND rowId = @rowId
END