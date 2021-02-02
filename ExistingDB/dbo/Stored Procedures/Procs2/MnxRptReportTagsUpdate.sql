-- =============================================
-- Author:		David Sharp
-- Create date: 4/16/14
-- Description:	Update Report Tags
-- =============================================
CREATE PROCEDURE MnxRptReportTagsUpdate 
	-- Add the parameters for the stored procedure here
	@rptId varchar(10), 
	@tagIds varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @tags TABLE (tagName varchar(10))
	IF @tagIds IS NOT NULL AND @tagIds <> ''
		INSERT INTO @tags SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@tagIds,',')

	DELETE FROM MnxReportTags WHERE rptId = @rptId

	INSERT INTO MnxReportTags (rptId,fksTagId)
	SELECT @rptId,sTagId 
		FROM @tags t INNER JOIN MnxSystemTags st ON st.tagName = t.tagName
END