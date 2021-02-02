-- =============================================
-- Author:		David Sharp
-- Create date: 5/2/2012
-- Description:	Delete import Ref Desg detail
-- =============================================
CREATE PROCEDURE [dbo].[importBOMRefDelete]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@rowId uniqueidentifier,
	@refdesIds varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @tRefDesgs Table (refId uniqueidentifier)
    INSERT INTO @tRefDesgs SELECT CAST(id as uniqueidentifier) from fn_simpleVarcharlistToTable(@refdesIds,',')
    
    
	DELETE FROM importBOMRefDesg
		WHERE fkImportId=@importId AND fkRowId=@rowId AND refdesId IN (SELECT refId FROM @tRefDesgs)
END
