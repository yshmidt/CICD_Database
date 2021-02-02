CREATE PROCEDURE [dbo].[QkViewSerialnoDefectHistView] @lcSerialUniq char(10) = ' '
AS
BEGIN

SET NOCOUNT ON;

DECLARE @lcWono char(10), @llSQC_Installed bit

SELECT @lcWono = Wono 
	FROM INVTSER
	WHERE SERIALUNIQ = @lcSerialUniq

SELECT @llSQC_Installed = Installed
	FROM ITEMS
	WHERE Screenname = 'DFCTENTR'
	
IF @llSQC_Installed = 1 AND @lcWono <> ''
	SELECT Date, Inspby, ChgDept_id, Def_code, Location, Partmfgr, ISNULL(Part_no,SPACE(25)) AS Part_no, ISNULL(Revision, SPACE(8)) AS Revision, LocQty
		FROM Qadef, Qainsp, Qadefloc LEFT OUTER JOIN Inventor
		ON Qadefloc.Uniq_key = Inventor.Uniq_key 
		WHERE Qadef.Locseqno = Qadefloc.Locseqno 
		AND Qainsp.Qaseqmain = Qadef.Qaseqmain 
		AND Qadef.SerialUniq = @lcSerialUniq
		AND Qadef.Wono = @lcWono
		ORDER BY Date
ELSE
	SELECT NULL AS Date, SPACE(10) AS Inspby, SPACE(4) AS ChgDept_id, SPACE(10) AS Def_Code, SPACE(30) AS Location, SPACE(8) AS Partmfgr,
		SPACE(25) AS Part_no, SPACE(8) AS Revision, 0000 AS LocQty
		FROM QAINSP
		WHERE 1 = 2
END