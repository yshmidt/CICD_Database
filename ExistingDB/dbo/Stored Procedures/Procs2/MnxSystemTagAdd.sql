-- =============================================
-- Author:		David Sharp
-- Create date: 11/9/2012
-- Description:	add system tag
-- =============================================
CREATE PROCEDURE MnxSystemTagAdd 
	-- Add the parameters for the stored procedure here
	@tagName varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    /* tagName is the primary key.  tagId is just for linking */
	INSERT INTO MnxSystemTags (sTagId,tagName)
	SELECT dbo.fn_GenerateUniqueNumber(),@tagName
END