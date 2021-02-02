-- =============================================
-- Author:		Rajendra K	
-- Create date: <07/26/2017>
-- Description:Calculate Buildable Qty By WONO
-- EXEC CalculateBuildableQtyByWONO 0000000009,_0TQ0MOGPO
-- ============================================= 

CREATE PROCEDURE CalculateBuildableQtyByWONO
	@wono int='',
	@uniqKey  varchar(50)='',
	@allowReserveQry BIT= 0
AS
BEGIN 
	
	DECLARE @wonumber int=(SELECT WOENTRY.WONO FROM WOENTRY WHERE WOENTRY.WONO= @wono)

	DECLARE @uniq varchar(50)=(SELECT INVENTOR.UNIQ_KEY FROM INVENTOR WHERE INVENTOR.UNIQ_KEY=@uniqKey)

	IF(@wonumber IS NULL AND @uniq IS NULL )
	BEGIN
	RETURN ''
	END
	ELSE
	BEGIN
	SELECT DISTINCT WO.WONO 
	 ,WO.UNIQ_KEY AS UniqKey
	 ,B.QTY 
	 ,RTRIM(I.PART_NO) + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PART_NO
    ,I.DESCRIPT AS DESCRIPT
    ,CASE WHEN @allowReserveQry = 1 THEN (IM.QTY_OH+IM.RESERVED) ELSE IM.QTY_OH END AS TotalAvlQty --TotalAvlQty
    ,(K.ACT_QTY+K.allocatedQTY+K.SHORTQTY) AS ReqQty  --ReqQty
    ,(CASE WHEN @allowReserveQry = 1 THEN (IM.QTY_OH+IM.RESERVED) ELSE IM.QTY_OH END)-(K.ACT_QTY+K.allocatedQTY+K.SHORTQTY) AS TotalShort --TotalShortage
    ,(CASE WHEN @allowReserveQry = 1 THEN (IM.QTY_OH+IM.RESERVED) ELSE IM.QTY_OH END)/NULLIF(B.QTY,0.00) AS BuildableQuantity 
	,'' AS WorkCenter
	FROM WOENTRY WO 
	INNER JOIN INVENTOR I ON WO.UNIQ_KEY = I.UNIQ_KEY
	INNER JOIN BOM_DET B ON B.UNIQ_KEY = I.UNIQ_KEY 
	INNER JOIN KAMAIN K ON WO.UNIQ_KEY=k.UNIQ_KEY
	INNER JOIN INVTMFGR IM   ON  I.UNIQ_KEY=IM.UNIQ_KEY
	WHERE 
	WO.UNIQ_KEY=B.UNIQ_KEY OR @wono=WO.WONO OR @uniqKey=WO.UNIQ_KEY	
	AND @wono IS NULL AND @uniqKey=''
	END
END
