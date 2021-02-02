CREATE PROCEDURE [dbo].[WarehouseNoMrbWipWowipView]
AS 
BEGIN
	SELECT Warehouse, UniqWh, WHNO, WH_GL_NBR, Wh_Descr
		FROM Warehous 
        WHERE Warehouse <> 'MRB' 
        AND WAREHOUSE <> 'WIP' 
        AND WAREHOUSE <> 'WO-WIP'
        ORDER BY Whno
END



