-- =============================================
-- Author:		Vicky Lu
-- Create date: 2011/04/21
-- Description:	Calculate standard cost for WO issued component
-- Modification:
-- 04/17/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[sp_IssuUpCost] @gWono AS char(10) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

WITH ZCost AS
(
SELECT Uniq_key, Qtyisu, Stdcost AS OldUnitCost, Qtyisu * Stdcost AS OldCost, 
		-- 04/17/17 VL added functional currency code
		 StdcostPR AS OldUnitCostPR, Qtyisu * StdcostPR AS OldCostPR
	FROM Invt_isu 
	WHERE Invt_isu.Wono = @gWono
)

SELECT C.*, I.StdCost AS NewUnitCost, Part_Sourc, C.Qtyisu*I.StdCost AS NewCost,
		-- 04/17/17 VL added functional currency code
		I.StdCostPR AS NewUnitCostPR, C.Qtyisu*I.StdCostPR AS NewCostPR 
	FROM ZCost C, Inventor I
	WHERE C.Uniq_key = I.Uniq_key

RETURN
END






