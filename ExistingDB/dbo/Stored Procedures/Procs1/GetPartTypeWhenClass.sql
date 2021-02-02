-- =============================================
-- Author: Satish B
-- Create date: 07/05/2017
-- Description:	Get part type against selected class in Line Card module
-- exec GetPartTypeWhenClass '6MMSNDN0EO','',1,100,0
-- ============================================= 
CREATE PROCEDURE [dbo].[GetPartTypeWhenClass] 
-- Add the parameters for the stored procedure here
	@uniqSupCls char(10) ='',
	@partType char(8)=null,
	@startRecord int =1,
    @endRecord int =10, 
    @outTotalNumberOfRecord int OUTPUT
AS
BEGIN
     SET NOCOUNT ON	 
	 SELECT COUNT(1) AS RowCnt -- Get total counts 
	 INTO #tempSupPartTypeView
	 FROM SUPTYPE supType
		  INNER JOIN PARTTYPE partType ON partType.UNIQPTYPE=supType.UNIQPTYPE
	 WHERE supType.UNQSUPCLAS = @uniqSupCls
			AND ((@partType IS NULL OR @partType='') OR (PARTTYPE.PART_TYPE =@partType))

	 SELECT --0 AS IsChecked
			 partType.PART_TYPE AS Type
			 ,partType.PREFIX AS Prefix
			 ,supType.UNQSUPCLAS
			 ,supType.UNQSUPTYPE
			 ,partType.UNIQPTYPE
	FROM SUPTYPE supType
		  INNER JOIN PARTTYPE partType ON partType.UNIQPTYPE=supType.UNIQPTYPE
	 WHERE supType.UNQSUPCLAS = @uniqSupCls
		  AND ((@partType IS NULL OR @partType='') OR (PARTTYPE.PART_TYPE =@partType))
	 ORDER BY partType.PART_TYPE
	 OFFSET(@startRecord-1) ROWS
	 FETCH NEXT @EndRecord ROWS ONLY;

	 SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempSupPartTypeView) -- Set total count to Out parameter 
END



		