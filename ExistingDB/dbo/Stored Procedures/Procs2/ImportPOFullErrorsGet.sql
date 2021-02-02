-- =============================================
-- Author:		Satish B
-- Create date: 6/13/2018
-- Description:	Get current errors for selected importId
-- exec ImportPOFullErrorsGet 'ff5ecc88-16d0-4e92-a216-0612cd5c2bd7','6238'
-- =============================================
Create PROCEDURE [dbo].[ImportPOFullErrorsGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@moduleId char(10)
AS
BEGIN
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	SELECT ibf.rowId,fd.fieldName,ibf.message AS title, ibf.status AS class 
		FROM importFieldDefinitions fd 
			 INNER JOIN ImportPODetails ibf ON fd.fieldDefId = ibf.fkFieldDefId
		WHERE ibf.fkPOImportId = @importId 
		       AND fd.ModuleId= @moduleId
END