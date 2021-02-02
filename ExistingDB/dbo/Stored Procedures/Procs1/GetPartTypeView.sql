-- =============================================
-- Author: Satish B
-- Create date: 07/05/2017
-- Description:	Get all part type in Line Card module against selected class
-- exec GetPartTypeView '','battery',1,100,0
-- =============================================
CREATE PROCEDURE [dbo].[GetPartTypeView] 
-- Add the parameters for the stored procedure here
	@partType char(8)='',
	@partClass char(8)='',
	@startRecord int =1,
    @endRecord int =10, 
	@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
     SET NOCOUNT ON	 
	 SELECT COUNT(1) AS RowCnt -- Get total counts 
	 INTO #tempPartTypeView
	 FROM PARTTYPE
	 WHERE PART_CLASS=@partClass
		  AND ((@partType IS NULL OR @partType='') OR (PARTTYPE.PART_TYPE =@partType))

	 SELECT --0 AS IsChecked
			  partType.PART_TYPE AS Type
			 ,partType.PREFIX AS Prefix
			 ,partType.UNIQPTYPE
			 ,supType.UNQSUPCLAS
			 ,supType.UNQSUPTYPE
			 ,CASE WHEN supType.UNIQPTYPE IS NULL THEN 0 ELSE 1 END AS IsSort
	 FROM PARTTYPE partType
		  LEFT JOIN SUPTYPE supType ON partType.UNIQPTYPE=supType.UNIQPTYPE
	 
	 WHERE partType.PART_CLASS=@partClass
	   	  AND ((@partType IS NULL OR @partType='') OR (partType.PART_TYPE =@partType))
	 ORDER BY IsSort DESC
	 OFFSET(@startRecord-1) ROWS
	 FETCH NEXT @EndRecord ROWS ONLY;

	 SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPartTypeView) -- Set total count to Out parameter 
END

