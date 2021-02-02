-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/16/10>
-- Description:	<Create list of sub reports>
-- =============================================
CREATE PROCEDURE dbo.ReportsSubListView
	-- Add the parameters for the stored procedure here
	@gctype as char(15)=' ' 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Title2, Type, RptType,Options,
		RptName,RptDetail,Label, Askdate, 
		MultipleEmail,CASE 
						WHEN lIs_CR=1 Then 'MCR' 
						ELSE 'M  ' END AS ReportSource,Sequence,FilePath,lIs_CR,Comments2 
	FROM Reports where type2<>' ' AND Show=1 and [TYPE]=@gcType
	order by Type,Sequence
	END
