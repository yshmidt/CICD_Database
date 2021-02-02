-- =============================================
-- Author:		Rajendra K	
-- Create date: <07/26/2017>
-- Description:Get MfgrAllocatedQty
-- exec GeMfgrAllocatedQty 20,'_1ZN0OW0ED','0000000254'
-- =============================================
CREATE PROCEDURE GetMfgrAllocatedQty
(
@Qty NUMERIC(10,2),
@WKey CHAR(10),
@WoNo CHAR(10)
)
AS
BEGIN
   SET NOCOUNT ON
   SELECT SUM(QTYALLOC) AS Allocated,W_KEY
   INTO #tempInvtRes
		  FROM 
		  INVT_RES IR 
		 
		  WHERE IR.WONO = @WoNo AND W_KEY = @WKey
		  GROUP BY W_KEY 
  IF NOT EXISTS(SELECT 1 FROM #TempInvtRes)
  BEGIN
	SELECT @Qty
  END
  ELSE
  BEGIN
	SELECT 
	 @Qty - ISNULL(IR.Allocated,0) AS Reserved		 
	FROM Invtmfgr invtMf 
	 INNER JOIN #tempInvtRes IR ON invtMf.W_KEY = IR.W_KEY AND invtMf.W_KEY = @WKey
  END
END