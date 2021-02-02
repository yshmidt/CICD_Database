-- =============================================
-- Author:Rajendra K
-- Create date: 06/28/2017
-- Description:	Used to Get InvtResNo by SerialUniq
-- Modification
   --08/11/2017 Rajendra K : Renamed CTE ZRes to Res
-- EXEC GetInvtResNoBySerialUniq '_26Z0SZSGK'
-- =============================================
CREATE PROCEDURE GetInvtResNoBySerialUniq
(
@SerialUniq CHAR(10)=''
)
AS
BEGIN
SET NOCOUNT ON;
			--08/11/2017 Rajendra K : Renamed CTE ZRes to Res
			;WITH ZRes AS(
			SELECT ROW_NUMBER() OVER(PARTITION by serialuniq ORDER BY DATETIME desc) AS RowNum
			,IR.InvtRes_No 
			,SerialUniq 
			FROM INVT_RES IR INNER JOIN IReserveSerial IRS ON IR.INVTRES_NO = IRS.invtres_no AND IRS.serialuniq = @SerialUniq AND IRS.isDeallocate = 0
			)
			SELECT InvtRes_No AS InvtResNo FROM ZRes WHERE RowNum = 1
END