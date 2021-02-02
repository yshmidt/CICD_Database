-- =============================================
-- Author:Satish B
-- Create date: 07/05/2017 
-- Description:	Get saved part class against supplier in Line Card module
-- exec GetSupClassView '_1D50WFSWT','',1,100,0
-- =============================================
CREATE PROCEDURE [dbo].[GetSupClassView] 
    -- Add the parameters for the stored procedure here
	@uniqSupno char(10) ='',
	@partClass char(8)='',
	@startRecord int =1,
    @endRecord int =10, 
	@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
	 SET NOCOUNT ON	 
	 SELECT COUNT(1) AS RowCnt -- Get total counts 
	 INTO #tempSupClassView
	 FROM Supclass supClass
		  INNER JOIN SUPPORT support ON supClass.PART_CLASS=support.TEXT2
	 WHERE supClass.PART_CLASS =support.TEXT2
		  AND support.FIELDNAME ='PART_CLASS'
		  AND supClass.UNIQSUPNO = @uniqSupno
		  AND ((@partClass IS NULL OR @partClass='') OR (Part_class =@partClass))
	 
	 SELECT supClass.UNQSUPCLAS
		   ,supClass.UNIQSUPNO
		   ,supClass.Part_class AS Class
		   ,support.Text AS Description 
		   ,supClass.PART_CLASS
		   --,0 AS IsChecked
	 FROM Supclass supClass
		  INNER JOIN SUPPORT support ON supClass.PART_CLASS=support.TEXT2
	 WHERE supClass.PART_CLASS =support.TEXT2
		  AND support.FIELDNAME ='PART_CLASS'
		  AND supClass.UNIQSUPNO = @uniqSupno
		  AND ((@partClass IS NULL OR @partClass='') OR (Part_class =@partClass))
	 ORDER BY supClass.Part_class
	 OFFSET(@startRecord-1) ROWS
	 FETCH NEXT @EndRecord ROWS ONLY;

	 SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempSupClassView) -- Set total count to Out parameter 
END
