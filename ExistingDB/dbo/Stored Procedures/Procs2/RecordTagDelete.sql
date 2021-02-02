
CREATE PROCEDURE [dbo].[RecordTagDelete] 
	-- Add the parameters for the stored procedure here
	@recordTagId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   DELETE FROM RecordTags WHERE RecordTagId = @recordTagId;
END