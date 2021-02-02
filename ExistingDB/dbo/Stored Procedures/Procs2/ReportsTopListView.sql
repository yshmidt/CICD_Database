-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/16/10>
-- Description:	<Create list of reports>
-- =============================================
CREATE PROCEDURE [dbo].[ReportsTopListView]
	-- Add the parameters for the stored procedure here
	@gctype as char(15)=' ' 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Title, Type, RptType,Options,
		RptName,Label, Askdate, 
		MultipleEmail,CASE 
						WHEN lIs_CR=1 Then 'MCR' 
						ELSE 'M  ' END AS ReportSource,Sequence,FilePath,lIs_CR,Comments	
		FROM Reports where type2=' ' AND Show=1 and [TYPE]=@gcType
	UNION 
		SELECT DISTINCT Reports.Title,Reports.Type,Reports.RptType,' ' as Options,Reports.RptName,Reports.Label,CAST(0 as bit) as AskDate,
		Reports.MultipleEmail , CASE 
						WHEN lIs_CR=1 Then 'MCR' 
						ELSE 'M  ' END AS ReportSource,
		R2.Sequence,CAST(' ' as varchar(254)) as FilePath,Reports.lIs_CR,Reports.Comments 
		FROM Reports,
		(SELECT R3.RptName,MIN(Sequence) as Sequence FROm Reports R3 GROUP BY rptname) R2 
		 where Reports.type2<>' ' AND Reports.Show=1 and Reports.TYPE=@gcType AND Reports.Rptname=R2.RptName
	UNION 
		SELECT Title, Type, RptType,Options,
		RptName,Label, Askdate, 
		MultipleEmail,'C   ' AS ReportSource,Sequence,FilePath,CAST(0 as bit) as  lIs_CR,Comments 
		FROM CustRept WHERE type2=' ' and [TYPE]=@gcType order by 9,10
END
