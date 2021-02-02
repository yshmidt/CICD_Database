-- =============================================
-- Author:		David Sharp
-- Create date: 11/9/2012
-- Description:	add system tag
-- =============================================
CREATE PROCEDURE MnxSystemTagUpdate
	-- Add the parameters for the stored procedure here
	@tagId char(10),
	@tagName varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    UPDATE MnxSystemTags
		SET tagName = @tagName
		WHERE sTagId = @tagId
END