CREATE PROC [dbo].[InvtSerTransferHistView] @gWono AS char(10) = '', @lcSerialno AS char(30) = ''
AS
---06/13/18 YS the structure is changed and activities removed
SELECT DISTINCT transfer.Wono, Serialno, Date, Fr_dept_id, D1.Dept_name AS Fr_Dept_name,
	To_dept_id, d2.Dept_name AS To_Dept_name,	Qty, [By] AS XferBy, Fr_actvkey, To_actvkey 
	FROM Transfer inner join DEPTS D1 on transfer.FR_DEPT_ID=D1.DEPT_ID
	inner join DEPTS D2 on TO_DEPT_ID =d2.DEPT_ID
	inner join TRANSFERSNX s on transfer.XFER_UNIQ=s.FK_XFR_UNIQ
	inner join invtser on s.FK_SERIALUNIQ=invtser.serialuniq
	---, ACTIVITY A1, Activity A2
	--WHERE Transfer.FR_DEPT_ID = CASE WHEN Fr_actvkey = '' THEN D1.DEPT_ID ELSE A1.ACTIV_ID END
	--AND Transfer.To_Dept_id = CASE WHEN To_actvkey = '' THEN D2.DEPT_ID ELSE A2.ACTIV_ID END
	where Transfer.Wono = @gWono
	AND invtser.Serialno= @lcSerialno
	ORDER BY [Date]









