-- Author:		Rajendra K	
-- Create date: <11/22/2018>
-- Description: Calculate BuildableQty
-- exec CalculateBuildableQty 
-- 06/18/2019 Rajendra K  : Added where condition 
-- 06/19/2019 Rajendra K  : Changed BldQty calculation 
-- 06/19/2019 Rajendra K  : Added table @KitBomView & @KitBom  & Cursor to get BomExplod all Qty
-- 06/19/2019 Rajendra K  : Changed selection of BldQty, Qty
-- =============================================
CREATE PROCEDURE [dbo].[CalculateBuildableQty] 
	@tWONOList AS dbo.tSimulationData READONLY,
	@allowReserveQry BIT= 0
AS
BEGIN

SET NOCOUNT ON
IF OBJECT_ID('tempdb..#wonoList') IS NOT NULL DROP TABLE #wonoList
IF OBJECT_ID('tempdb..#avlQTY') IS NOT NULL DROP TABLE #avlQTY
IF OBJECT_ID('tempdb..#WONOBuildableQTY') IS NOT NULL DROP TABLE #WONOBuildableQTY
IF OBJECT_ID('tempdb..#tempUniqKeyList') IS NOT NULL DROP TABLE #tempUniqKeyList
IF OBJECT_ID('tempdb..#tempQtyList') IS NOT NULL DROP TABLE #tempQtyList
IF OBJECT_ID('tempdb..#tempWOList') IS NOT NULL DROP TABLE #tempWOList

 
  CREATE TABLE #wonoList
  (
    RowNumber INT,
    WONO CHAR(10),
    UNIQ_KEY CHAR(10),  
    RowUId uniqueidentifier,
    QTY NUMERIC(12,2) 
  )

  --Following commented code will be use for testing purpose
  --;WITH cteWONOList AS(
  --SELECT DISTINCT WONO,W.UNIQ_KEY,W.BLDQTY  FROM WOENTRY W INNER JOIN BOM_DET B ON W.UNIQ_KEY = B.BOMPARENT WHERE W.WONO IN ('0000000104','0000000260','0000000607')
  --)
  --SELECT DISTINCT ROW_NUMBER() OVER(ORDER BY WONO) AS RowNumber,WONO,UNIQ_KEY,'33f76a2c-46ec-4d66-9bba-02c9b41ab390' AS UID,BLDQTY 
  --INTO #tempWOList 
  -- FROM cteWONOList
  --INSERT INTO #wonoList SELECT DISTINCT RowNumber,WONO,UNIQ_KEY,UID,BLDQTY  FROM #tempWOList
  --SELECT * FROM #wonoList

  INSERT INTO #wonoList SELECT Id AS RowNumber,WONO, UniqKey,RowUID,QTY FROM @tWONOList W
  
  CREATE TABLE #avlQTY
  (
  UNIQ_KEY CHAR(10),  
  AVL_Qty NUMERIC(18,5)
  )

  CREATE TABLE #WONOBuildableQTY
  (
  ROWNUMBER INT ,
  BldQty INT,
  UNIQ_KEY CHAR(10),  
  ShortageQty NUMERIC(10,5),
  TotalShortageQty NUMERIC(10,5)
  )
  
-- 06/19/2019 Rajendra K  : Added table @KitBomView & @KitBom  & Cursor to get BomExplod all Qty
	 DECLARE  @KitBomView TABLE (Dept_id CHAR(8),Uniq_key CHAR(10),BomParent CHAR(10),Qty NUMERIC(10,2), ShortQty NUMERIC(10,2), 
 Used_inKit CHAR(8), Part_Sourc CHAR(10) ,Part_No CHAR(100),Revision CHAR(8), Descript varchar(100), Part_class CHAR(8), Part_type  CHAR(8)
 , U_of_meas  CHAR(4), Scrap NUMERIC(6,2), SetupScrap NUMERIC(4,0) , CustPartNo  CHAR(35), SerialYes CHAR(8),Qty_Each numeric(12,2),UniqueId CHAR(10));

 DECLARE  @KitBom TABLE (Dept_id CHAR(8),Uniq_key CHAR(10),BomParent CHAR(10),Qty NUMERIC(10,2), ShortQty NUMERIC(10,2),Qty_Each numeric(12,2),wono char(10));

  DECLARE @WCursor CURSOR;
		DECLARE @WONONumber INT,@wono char(10);
		BEGIN
		  SET @WCursor = CURSOR FOR
		  SELECT WONO FROM #wonoList
		 
		  OPEN @WCursor 
		  FETCH NEXT FROM @WCursor 
		  INTO @WONONumber

		  WHILE @@FETCH_STATUS = 0
		  BEGIN

		 SET  @wono = (SELECT[dbo].[PADL](@WONONumber,10,'0'));
		   INSERT INTO @KitBomView EXEC [dbo].[KitBomInfoView] @wono
		   INSERT INTO @KitBom(Dept_id ,Uniq_key,BomParent,Qty ,ShortQty ,Qty_Each ,wono) 
		   SELECT w.Dept_id ,w.Uniq_key,w.BomParent,w.Qty , w.ShortQty ,w.Qty_Each,@wono from @KitBomView w

		   DELETE FROM @KitBomView
		   FETCH NEXT FROM @WCursor 
		    INTO @WONONumber 
		  END; 

		  CLOSE @WCursor ;
		  DEALLOCATE @WCursor;
	 END

		--Get distinct UNIQ_KEY
		SELECT DISTINCT UNIQ_KEY
		INTO #tempUniqKeyList
		FROM @KitBom 
		GROUP BY UNIQ_KEY 		

		--Get Available Qty for each UNIQ_KEY
		INSERT INTO #avlQTY(UNIQ_KEY,AVL_Qty)
		SELECT t.UNIQ_KEY AS UNIQ_KEY,CASE WHEN @allowReserveQry = 1 THEN SUM(IM.QTY_OH) ELSE SUM(IM.QTY_OH - IM.RESERVED) END AS  AVL_Qty
		FROM #tempUniqKeyList t INNER JOIN INVTMFGR IM ON t.UNIQ_KEY = IM.UNIQ_KEY GROUP BY t.UNIQ_KEY

		DECLARE @WOCursor CURSOR;
		DECLARE @RowNumber INT;
		BEGIN
		  SET @WOCursor = CURSOR FOR
		  SELECT RowNumber FROM #wonoList

		  OPEN @WOCursor 
		  FETCH NEXT FROM @WOCursor 
		  INTO @RowNumber

		  WHILE @@FETCH_STATUS = 0
		  BEGIN
		    DECLARE @bldQTY INT;
		
			--Get WOQty, AvlQty, ReqQty and BldQty
			-- 06/19/2019 Rajendra K  : Changed selection of BldQty, Qty
			SELECT KB.UNIQ_KEY
				  ,KB.Qty_Each AS Qty
				  ,a.AVL_Qty
				  ,kb.ShortQty AS ReqQty 
				  ,CASE WHEN a.AVL_Qty =0 OR w.QTY = 0 OR KB.Qty_Each = 0 THEN 0  
				    ELSE 
					CASE WHEN  a.AVL_Qty >= (KB.ShortQty)
					 THEN CAST(w.QTY AS INT)
						ELSE  CAST(a.AVL_Qty /KB.ShortQty AS INT) END					 
					 END AS  BldQty 
			INTO #tempQtyList 
			FROM #wonoList w				
			INNER JOIN @KitBom KB ON w.WONO = KB.wono	
			INNER JOIN BOM_DET b ON kb.BOMPARENT = b.BOMPARENT			
			INNER JOIN #avlQTY a ON a.UNIQ_KEY =  KB.UNIQ_KEY
			WHERE RowNumber = @RowNumber
			GROUP BY kb.Uniq_key ,a.AVL_Qty,kb.ShortQty,KB.Qty_Each,w.QTY
			ORDER BY BldQty
			
			--Set @bldQTY for Current Assembly
			SET @bldQTY = (SELECT TOP 1 BldQty  FROM #tempQtyList WHERE Qty <> 0 ORDER BY BldQty)-- 06/19/2019 Rajendra K  : Changed BldQty calculation 

			UPDATE A
			SET A.AVL_Qty = CAST((A.AVL_Qty - (B.ReqQty * @bldQTY)) AS NUMERIC(18,5))
			FROM #avlQTY  AS A
		         INNER JOIN #tempQtyList AS B 
				 ON B.UNIQ_KEY = A.UNIQ_KEY


		  --Get BldQty,ShortageQty and TotalShortageQty 
			INSERT INTO #WONOBuildableQTY 
			SELECT @RowNumber
				  ,@bldQTY
				  ,t.UNIQ_KEY
				  ,ReqQty - AVL_Qty
				  ,CASE WHEN w.TotalShortageQty IS NULL OR w.TotalShortageQty = 0  THEN  ReqQty - AVL_Qty ELSE (ReqQty - AVL_Qty) +w.TotalShortageQty END 
			FROM #tempQtyList t LEFT JOIN #WONOBuildableQTY w ON t.UNIQ_KEY = w.UNIQ_KEY

			DROP TABLE #tempQtyList
		    
			FETCH NEXT FROM @WOCursor 
		    INTO @RowNumber 
		  END; 

		  CLOSE @WOCursor ;
		  DEALLOCATE @WOCursor;

		  SELECT WONO,B.UNIQ_KEY AS UniqKey
				,B.ROWNUMBER AS Id
				,W.RowUId AS RowUID
				,ISNULL(BldQty,0) AS BldQty 
				,CASE WHEN ShortageQty > 0 THEN ShortageQty ELSE 0 END ShortageQty
				,CASE WHEN TotalShortageQty  > 0 THEN TotalShortageQty  ELSE (CASE WHEN ShortageQty > 0 THEN ShortageQty ELSE 0 END) END TotalShortageQty
				FROM #WONOBuildableQTY B INNER JOIN #wonoList W ON B.RowNumber = W.RowNumber	
	END
END