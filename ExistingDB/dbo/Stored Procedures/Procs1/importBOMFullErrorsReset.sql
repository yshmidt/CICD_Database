-- =============================================
-- Author:		David Sharp
-- Create date: 4/27/2012
-- Description:	reset import detail flags
-- =============================================
CREATE PROCEDURE [dbo].[importBOMFullErrorsReset]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @fade varchar(20)='i02fade',@none varchar(20)='00none'
	
	UPDATE importBOMFields
		SET [status]=@fade,[validation]=@none,[message]='',uniq_key=''
		WHERE fkImportId = @importId
	UPDATE importBOMAvl
		SET [status]=@fade,[validation]=@none,[message]='',uniqmfgrhd='',[load]=0
		WHERE fkImportId = @importId
END