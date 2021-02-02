
-- Author:		Rajendra K	
-- Create date: <08/10/2018>
-- Description:CalculateTotalShortageQty
-- exec CalculateTotalShortageQty 
-- =============================================
CREATE PROCEDURE [dbo].[CalculateTotalShortageQty] 
	@tWONOList AS dbo.tSimulationData READONLY,
	@tPartList AS dbo.tSimulationPartData READONLY,
	@allowReserveQry BIt = 0
AS
BEGIN

IF OBJECT_ID('tempdb..#wonoList') IS NOT NULL DROP TABLE #wonoList
IF OBJECT_ID('tempdb..#avlQTY') IS NOT NULL DROP TABLE #avlQTY
IF OBJECT_ID('tempdb..#BuildableList') IS NOT NULL DROP TABLE #BuildableList
IF OBJECT_ID('tempdb..#WONOBuildableQTY') IS NOT NULL DROP TABLE #WONOBuildableQTY
 
   CREATE TABLE #wonoList
  (
  RowNumber INT,
  WONO CHAR(10),
  UNIQ_KEY CHAR(10),  
  RowUId uniqueidentifier,
  QTY NUMERIC(12,2) 
  )
  -- ;WITH cteWONOList AS(
  --SELECT DISTINCT WONO,W.UNIQ_KEY  FROM WOENTRY W INNER JOIN BOM_DET B ON W.UNIQ_KEY = B.BOMPARENT WHERE W.WONO IN ('0000000126')
  --)

  --INSERT INTO #wonoList SELECT DISTINCT ROW_NUMBER() OVER(ORDER BY WONO) AS RowNumber,WONO,UNIQ_KEY,'33f76a2c-46ec-4d66-9bba-02c9b41ab390'  FROM cteWONOList

  --SELECT * FROM #wonoList
  INSERT INTO #wonoList SELECT  Id AS RowNumber,WONO, UniqKey,RowUID,QTY FROM @tWONOList W

  CREATE TABLE #avlQTY
  (  
  UNIQ_KEY CHAR(10),  
  AVL_Qty NUMERIC(10,5),
  ShortageQty NUMERIC(10,5),
  TotalShortageQty NUMERIC(10,5),
  )

  CREATE TABLE #BuildableList
  (
  Buildable_QTY NUMERIC(10,5),
  UNIQ_KEY CHAR(10),  
  BLDQTY NUMERIC(10,5),
  QTY NUMERIC(12,2),
  TotalReq NUMERIC(10,5),
  Avialable NUMERIC(10,5),
  )

  CREATE TABLE #WONOBuildableQTY
  (
  ROWNUMBER INT ,
  BldQty INT
  )
  
  INSERT INTO #avlQTY  SELECT B.UNIQ_KEY
  ,CASE WHEN @allowReserveQry = 1 THEN SUM(IM.QTY_OH + IM.RESERVED)/w.QTY ELSE SUM(Im.QTY_OH)/w.QTY END
  ,(BLDQTY* B.QTY)-(CASE WHEN @allowReserveQry = 1 THEN SUM(IM.QTY_OH + IM.RESERVED)/w.QTY ELSE SUM(Im.QTY_OH)/w.QTY END)AS  ShortageQty 
  ,(BLDQTY* B.QTY)-(CASE WHEN @allowReserveQry = 1 THEN SUM(IM.QTY_OH + IM.RESERVED)/w.QTY ELSE SUM(Im.QTY_OH)/w.QTY END)AS  TotalShortageQty
  FROM #wonoList W 
  INNER JOIN BOM_DET B ON W.UNIQ_KEY = B.BOMPARENT 
  INNER JOIN INVTMFGR IM ON B.UNIQ_KEY = IM.UNIQ_KEY WHERE w.QTY !=0 GROUP BY B.UNIQ_KEY,w.QTY 

	DECLARE @MyCursor CURSOR;
	DECLARE @RowNumber INT;
	BEGIN
	  SET @MyCursor = CURSOR FOR
	  SELECT RowNumber FROM #wonoList

	  OPEN @MyCursor 
	  FETCH NEXT FROM @MyCursor 
	  INTO @RowNumber

	  WHILE @@FETCH_STATUS = 0
	  BEGIN
	    DECLARE @bldQTY INT;
		INSERT INTO #BuildableList
		SELECT DISTINCT AVL_Qty/WL.QTY AS Buildable_QTY,B.UNIQ_KEY,BLDQTY,WL.Qty,BLDQTY* B.QTY AS TotalReq ,AVL_Qty AS Avialable 
		FROM WOENTRY W INNER JOIN BOM_DET B ON W.UNIQ_KEY = B.BOMPARENT 
		INNER JOIN #avlQTY IM ON B.UNIQ_KEY = IM.UNIQ_KEY
		INNER JOIN #wonoList WL ON W.UNIQ_KEY = WL.UNIQ_KEY

		WHERE WL.RowNumber = @RowNumber
		GROUP BY W.WONO,B.UNIQ_KEY,BLDQTY,b.QTY ,AVL_Qty,WL.Qty
		ORDER BY Buildable_QTY

		SELECT TOP 1 @bldQTY =Buildable_QTY FROM #BuildableList order by Buildable_QTY

		INSERT INTO #WONOBuildableQTY
		SELECT @RowNumber,@bldQTY

		UPDATE A
		SET A.AVL_Qty = (A.AVL_Qty - (B.QTY * @bldQTY))
		,ShortageQty = (ShortageQty + ((B.QTY * @bldQTY)))
        ,TotalShortageQty = (TotalShortageQty + (ShortageQty + ((B.QTY * @bldQTY))))
		FROM #avlQTY  AS A
	         INNER JOIN #BuildableList AS B 
			 ON B.UNIQ_KEY = A.UNIQ_KEY

		DELETE FROM #BuildableList

	    FETCH NEXT FROM @MyCursor 
	    INTO @RowNumber 
	  END; 


	  CLOSE @MyCursor ;
	  DEALLOCATE @MyCursor;

	  SELECT WONO,UNIQ_KEY AS UniqKey,B.ROWNUMBER AS Id,W.RowUId AS RowUID,ISNULL(BldQty,0) AS BldQty FROM #WONOBuildableQTY B INNER JOIN #wonoList W ON B.RowNumber = W.RowNumber
END
END