
CREATE PROC [dbo].[InvtSerByWonoDeptkeyActvkeyView] @gWono AS char(10)='', @lcDeptkey AS char(10)='', @lcActvkey AS char(10)=''
AS
SELECT Serialno, Wono, Id_Value, SerialUniq, ActvKey
	FROM InvtSer
	WHERE Wono = @gWono
	AND Id_Key = 'DEPTKEY'
	AND Id_Value = @lcDeptKey
	AND Actvkey = @lcActvKey
	ORDER BY Serialno