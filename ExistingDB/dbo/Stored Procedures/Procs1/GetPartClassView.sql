-- =============================================
-- Author:Satish B
-- Create date: 07/04/2017
-- Description:	Get all part class in Line Card module
-- exec GetPartClassView '','_0TG0X7XQU',1,100,0
-- =============================================
CREATE PROCEDURE [dbo].[GetPartClassView] 
	@partClass char(8)='',
	@uniqSupno char(10) ='',
	@startRecord int =1,
    @endRecord int =10, 
	@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
     SET NOCOUNT ON	 
	 SELECT COUNT(1) AS RowCnt -- Get total counts 
	 INTO #tempPartClassView
	 FROM  SUPPORT support 
		   LEFT JOIN Supclass supClass ON support.Text2 = supClass.PART_CLASS AND (supClass.UniqSupno = @uniqSupno)
	 WHERE support.FIELDNAME = 'PART_CLASS' 
		   AND ((@partClass IS NULL OR @partClass='') OR (SUPPORT.TEXT2 =@partClass))
	 
	 SELECT  support.TEXT2 AS Class
			,support.TEXT AS Description
			,support.UNIQFIELD
			,support.FIELDNAME
			,supClass.UNQSUPCLAS
			,supClass.UNIQSUPNO
			,supClass.PART_CLASS
			--,0 AS IsChecked
			,CASE WHEN supClass.PART_CLASS IS NULL THEN 0 ELSE 1 END AS IsSort
	 FROM  SUPPORT support 
		   LEFT JOIN Supclass supClass ON support.Text2 = supClass.PART_CLASS AND (supClass.UniqSupno = @uniqSupno)
	 WHERE support.FIELDNAME = 'PART_CLASS' 
				AND ((@partClass IS NULL OR @partClass='') OR (SUPPORT.TEXT2 =@partClass))
	 ORDER BY IsSort DESC
	 OFFSET(@startRecord-1) ROWS
	 FETCH NEXT @EndRecord ROWS ONLY;

	 SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPartClassView) -- Set total count to Out parameter 
END
