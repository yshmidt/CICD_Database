-- =============================================
-- Author:		David Sharp
-- Create date: 5/2/2012
-- Description:	update Ref Desg info
-- =============================================
CREATE PROCEDURE [dbo].[importBOMRefUpdate] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier, 
	@rowId uniqueidentifier,
	@refdesId uniqueidentifier,
	@ref varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    UPDATE importBOMRefDesg
		SET refDesg = @ref
		WHERE fkImportId=@importId AND refdesId=@refdesId AND fkRowId=@rowId
		
END
