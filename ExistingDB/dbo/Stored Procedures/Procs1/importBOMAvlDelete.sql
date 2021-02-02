-- =============================================
-- Author:		David Sharp
-- Create date: 5/2/2012
-- Description:	Delete import Ref Desg detail
-- =============================================
CREATE PROCEDURE [dbo].[importBOMAvlDelete]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@rowId uniqueidentifier,
	@avlRowIds varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @tAvls Table (avlId uniqueidentifier)
    INSERT INTO @tAvls SELECT CAST(id as uniqueidentifier) from fn_simpleVarcharlistToTable(@avlRowIds,',')
    
	DELETE FROM importBOMAvl
		WHERE fkImportId=@importId AND fkRowId=@rowId AND avlRowId IN (SELECT avlId FROM @tAvls)
END
