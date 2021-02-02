-- =============================================
-- Author:Rajendra K
-- Create date: 10/30/2017
-- Description:	Used to Get InvtResNo by UniqLot
-- EXEC GetInvtResNoByLotUniq 'O6Z1HW0IKA'
-- =============================================
CREATE PROCEDURE GetInvtResNoByLotUniq
(
@uniqLot CHAR(10)=''
)
AS
BEGIN
SET NOCOUNT ON;
			;WITH InvtResList AS(
			SELECT ROW_NUMBER() OVER(PARTITION by IL.UNIQ_LOT ORDER BY DATETIME desc) AS RowNum
			,IL.UNIQ_LOT
			,IR.InvtRes_No 
			FROM INVT_RES IR INNER JOIN INVTLOT IL ON IR.LOTCODE = IL.LOTCODE 
													  AND IR.EXPDATE = IL.EXPDATE 
													  AND IR.REFERENCE = IL.REFERENCE 
													  AND IR.PONUM = IL.PONUM
													  AND IL.UNIQ_LOT = @uniqLot
			)
			SELECT InvtRes_No AS InvtResNo FROM InvtResList WHERE RowNum = 1
END