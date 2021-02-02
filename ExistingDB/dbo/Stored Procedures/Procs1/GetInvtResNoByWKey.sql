-- =============================================
-- Author:Rajendra K
-- Create date: 06/28/2017
-- Description:	Used to Get InvtResNo by WKey
-- Modification
   -- 08/11/2017 Rajendra K : Renamed CTE ZRes to Res
-- EXEC GetInvtResNoByWKey '_1ED0O2FSC'
-- =============================================
CREATE PROCEDURE GetInvtResNoByWKey
(
@WKey CHAR(10)=''
)
AS
BEGIN
SET NOCOUNT ON;
			-- 08/11/2017 Rajendra K : Renamed CTE ZRes to Res
			;WITH Res AS(
			SELECT ROW_NUMBER() OVER(PARTITION by W_Key ORDER BY DATETIME desc) AS RowNum
			,IR.InvtRes_No 
			,W_Key 
			FROM INVT_RES IR WHERE IR.W_KEY = @WKey AND QTYALLOC > 0
			)
			SELECT InvtRes_No AS InvtResNo FROM Res WHERE RowNum = 1
END