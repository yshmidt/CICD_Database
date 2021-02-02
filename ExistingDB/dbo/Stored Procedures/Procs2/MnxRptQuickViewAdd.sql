-- =============================================
-- Author:		David Sharp
-- Create date: 4/16/2014
-- Description:	Add a new QuickView
-- =============================================
CREATE PROCEDURE MnxRptQuickViewAdd 
	@rptTitle varchar(100),
	@rptTitleLong varchar(100),
	@rptDescription varchar (500),
	@sequence int = 1000,
	@display bit = 1,
	@dataSource varchar(50),
	@reportType varchar(50) = 'QuickView',
	@paramGroup varchar(50) = '',
	@groupedCol varchar(100) = '',
	@maxSqlTimeout int = 30,
	@tagIds varchar(MAX) = '',
	@isCustomer bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE	@rptId varchar(10)

	SET @rptId = dbo.fn_GenerateUniqueNumber()

	IF @isCustomer = 0
	BEGIN
		INSERT INTO MnxReports (rptId,rptTitle,rptTitleLong,rptDescription,sequence,display,dataSource,reportType,paramGroup,groupedCol,maxSqlTimeout)
		SELECT 	@rptId, @rptTitle, @rptTitleLong, @rptDescription, @sequence, @display, @dataSource, @reportType, @paramGroup, @groupedCol, @maxSqlTimeout
	END
	ELSE
	BEGIN
		INSERT INTO wmReportsCust(rptId,rptTitle,rptTitleLong,rptDescription,sequence,display,dataSource,reportType,paramGroup,groupedCol)
		SELECT 	@rptId, @rptTitle, @rptTitleLong, @rptDescription, @sequence, @display, @dataSource, @reportType, @paramGroup, @groupedCol
	END

	DECLARE @tags TABLE (fksTagId varchar(10))
	IF @tagIds IS NOT NULL AND @tagIds <> ''
		INSERT INTO @tags SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@tagIds,',')

	INSERT INTO MnxReportTags (rptId,fksTagId)
	SELECT @rptId,fksTagId FROM @tags

	SELECT * FROM MnxReports WHERE rptId = @rptId
END