-- =============================================
-- Author:		David Sharp
-- Create date: 02/24/2014
-- Description:	update the date and run count for the report
-- =============================================
CREATE PROCEDURE dbo.MnxRptUpdateRunCount 
	-- Add the parameters for the stored procedure here
	@rptId nvarchar(10), 
	@type nvarchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @SQL nvarchar(MAX) = 'UPDATE MnxReports SET dateLastRun=GETDATE(), ' + @type + 'Count='+ @type +'Count + 1 WHERE rptId = @rptId'
    --SELECT @SQL
    EXEC sp_executesql @SQL, N'@rptId nvarchar(10)',@rptId=@rptId
END
