-- =============================================
-- Author:		Vicky Lu
-- Create date: 2013/01/18
-- Description:	Calculate standard cost for WO issued component, include overissue qty (used in Kit close report)
-- Modification:
-- 05/17/17 VL Added functional currency code
-- 05/17/17 VL changed the output fields sequence
-- =============================================
CREATE PROCEDURE [dbo].[sp_IssuUpCost_IncludeOverIsu] @gWono AS char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

WITH ZCost AS
(
SELECT Uniq_key, Qtyisu, Stdcost AS OldUnitCost, Qtyisu * Stdcost AS OldCost,
	-- 05/17/17 VL added functional currency code
	StdcostPR AS OldUnitCostPR, Qtyisu * StdcostPR AS OldCostPR 
	FROM Invt_isu 
	WHERE Invt_isu.Wono = @gWono
UNION ALL
	(SELECT Kamain.UNIQ_KEY, -Kamain.SHORTQTY AS QtyIsu, Inventor.STDCOST AS OldUniqCost, -Kamain.SHORTQTY * Inventor.STDCOST AS OldCost,
	-- 05/17/17 VL added functional currency code
	Inventor.STDCOSTPR AS OldUniqCostPR, -Kamain.SHORTQTY * Inventor.STDCOSTPR AS OldCostPR
		FROM KAMAIN, INVENTOR
		WHERE Kamain.UNIQ_KEY = Inventor.UNIQ_KEY 
		AND Kamain.WONO = @gWono
		ANd SHORTQTY < 0)
)

SELECT C.Uniq_key, C.Qtyisu, C.OldUnitCost, C.OldCost, I.StdCost AS NewUnitCost, Part_Sourc, C.QtyIsu*I.StdCost AS NewCost,
	-- 04/10/17 VL added functional currency code
	C.OldUnitCostPR, C.OldCostPR, I.StdCostPR AS NewUnitCostPR, C.QtyIsu*I.StdCostPR AS NewCostPR
	FROM ZCost C, Inventor I
	WHERE C.Uniq_key = I.Uniq_key


RETURN
END

