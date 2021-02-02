-- =============================================
-- Author:Rajendra K
-- Create date: 07/03/2017
-- Description:	Used to Get InvtResNo by IpKey
-- Modification
   -- 08/11/2017 Rajendra K : Renamed CTE ZRes to Res
-- EXEC GetInvtResNoByIpKey 'O6Z1HW0IKA'
-- =============================================
CREATE PROCEDURE GetInvtResNoByIpKey
(
@Sid CHAR(10)=''
)
AS
BEGIN
SET NOCOUNT ON;
			-- 08/11/2017 Rajendra K : Renamed CTE ZRes to Res
			;WITH ZRes AS(
			SELECT ROW_NUMBER() OVER(PARTITION by ipkeyunique ORDER BY DATETIME desc) AS RowNum
			,IRP.ipkeyunique
			,IR.InvtRes_No 
			FROM INVT_RES IR INNER JOIN IReserveIpKey IRP ON IR.INVTRES_NO = IRP.invtres_no AND (IRP.ipkeyunique = @Sid
			OR  IRP.ipkeyunique IN (SELECT originalipkeyunique from IPkey where ipkeyunique IN(@Sid))) AND IRP.qtyAllocated > 0
			)
			SELECT InvtRes_No AS InvtResNo FROM ZRes WHERE RowNum = 1
END