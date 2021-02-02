-- =============================================
-- Author:		Rajendra K	
-- Create date: <07/26/2017>
-- Description:Get LotAllocatedQty
--exec GetLotAllocatedQty 20,'C20TU15UEI','0000000500'
-- =============================================
CREATE PROCEDURE GetLotAllocatedQty
(
@Qty NUMERIC(10,2),
@UniqLot CHAR(10),
@WoNo CHAR(10)
)
AS
BEGIN
   SET NOCOUNT ON 
		  SELECT SUM(QTYALLOC) AS Allocated
		  ,W_KEY
		  ,LOTCODE
		  ,Reference
		  ,ExpDate
		  ,PONUM
		INTO #tempInvtResCte
		  FROM 
		  INVT_RES IR 
		  WHERE IR.WONO = @WoNo 
		  GROUP BY W_KEY
				  ,LOTCODE
				  ,Reference
				  ,ExpDate
				  ,PONUM
		IF NOT EXISTS(SELECT 1 FROM #TempInvtResCte)
		BEGIN
			SELECT @Qty
		END
		ELSE
		BEGIN
		    SELECT  		   
				TOP(1) @Qty - COALESCE(IR.Allocated,0) AS LotResQty
			FROM INVTLOT IL  
			LEFT JOIN #tempInvtResCte IR ON IL.W_KEY = IR.W_KEY
				   AND IL.LOTCODE = IR.LOTCODE
				   AND IL.REFERENCE = IR.REFERENCE
				   AND COALESCE(IL.EXPDATE,GETDATE()) = COALESCE(IR.EXPDATE,GETDATE())
				   AND IL.PONUM = IR.PONUM	
			WHERE IL.UNIQ_LOT = @UniqLot
		END
END