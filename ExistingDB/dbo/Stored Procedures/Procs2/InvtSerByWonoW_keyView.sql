
CREATE PROC [dbo].[InvtSerByWonoW_keyView] @gWono AS char(10)='', @gUniq_key char(10)='', @lcW_key AS char(10)=''
AS
SELECT Serialno, Wono, Id_Value, SerialUniq
	FROM InvtSer
	WHERE Wono = @gWono
	AND UNIQ_KEY = @gUniq_key
	AND Id_Key = 'W_KEY'
	AND Id_Value = @lcW_key
	AND IsReserved = 0
	ORDER BY Serialno