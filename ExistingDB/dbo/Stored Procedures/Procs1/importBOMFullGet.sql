-- =============================================
-- Author:		David Sharp
-- Create date: 4/18/2012
-- Description:	get full import details
-- =============================================
CREATE PROCEDURE [dbo].[importBOMFullGet] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,@userId uniqueidentifier,@gridId varchar(50)=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Get Header infor
	EXEC importBOMHeaderGet @importId, @userId
    -- Get the import items
    EXEC importBOMRowAllGet @importId
    -- Get grid customization information
    IF NOT @gridId IS NULL
		EXEC MnxUserGetGridConfig @userId, @gridId
    -- Get the items available for mass update
    -- David Sharp removed 6/26/2012 to allow it to be a separate call
    --EXEC importBOMFullMassUpdatesGet @importId
    SELECT 'Removed' AS MassUpdate
    -- Get the import errors
    EXEC importBOMFullErrorsGet @importId
    -- Get the duplicate refs
    EXEC importBOMRefDuplicatesGet @importId
END