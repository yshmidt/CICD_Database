CREATE PROCEDURE [dbo].[QkViewSerialnoTransferHistView] @lcSerialUniq char(10) = ' '
AS
BEGIN
---06/13/18 YS the structure is changed and activities removed
SET NOCOUNT ON;

DECLARE @lcWono char(10), @lcSerialno char(30)

SELECT @lcWono = Wono, @lcSerialno = Serialno
	FROM INVTSER
	WHERE SERIALUNIQ = @lcSerialUniq
---06/13/18 YS the structure is changed and activities removed
SELECT DISTINCT Date, D1.Dept_name  AS Fr_Dept_name,
	D2.Dept_name To_Dept_name,	Qty, [By] AS XferBy
	FROM transfer inner join DEPTS D1 on transfer.FR_DEPT_ID=D1.DEPT_ID
	inner join DEPTS D2 on TO_DEPT_ID =d2.DEPT_ID
	inner join TRANSFERSNX s on transfer.XFER_UNIQ=s.FK_XFR_UNIQ
	WHERE Transfer.Wono = @lcWono
	AND s.FK_SERIALUNIQ= @lcSerialUniq
	ORDER BY [Date]
	

	

END