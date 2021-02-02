-- =============================================
-- Author:		David Sharp
-- Create date: 4/16/2012
-- Description:	get current errors for selected importId
-- =============================================
CREATE PROCEDURE [dbo].[importBOMFullErrorsGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ibf.rowId,fd.fieldName,ibf.message AS title, ibf.status AS class 
		FROM importBOMFieldDefinitions fd inner join importBOMFields ibf ON fd.fieldDefId = ibf.fkFieldDefId
		WHERE (ibf.fkImportId = @importId) AND (ibf.status <> 'i00skipped')--AND (ibf.status <> 'i00white')
END