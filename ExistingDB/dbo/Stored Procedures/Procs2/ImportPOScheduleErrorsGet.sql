-- =============================================
-- Author:		Satish B
-- Create date: 6/14/2018
-- Description:	Get current errors for selected importId for schedule grid
-- exec ImportPOScheduleErrorsGet 'ff5ecc88-16d0-4e92-a216-0612cd5c2bd7','6238'
-- =============================================
CREATE PROCEDURE [dbo].[ImportPOScheduleErrorsGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@moduleId char(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ibf.fkrowId,fd.fieldName,ibf.message AS title, ibf.status AS class,ibf.ScheduleRowId
		FROM importFieldDefinitions fd 
			 INNER JOIN ImportPOSchedule ibf ON fd.fieldDefId = ibf.fkFieldDefId
		WHERE ibf.fkPOImportId = @importId  
		       AND fd.ModuleId= @moduleId
END