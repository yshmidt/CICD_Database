--02/09/18 YS changed size of the lotcode column to 25 char
-- 05/07/14 VL change @ldExpdate from smalldatetime to char(20) because passed in will be char, 
CREATE PROC [dbo].[InvtSerByWonoW_keyLotView] @gWono AS char(10)='', @gUniq_key char(10)='', @lcW_key AS char(10)='', 
	@lcLotCode AS nvarchar(25) = '', @ldExpdate AS char(20) = '', @lcReference AS char(12)=''
AS
SELECT Serialno, Wono, Id_Value, SerialUniq
	FROM InvtSer
	WHERE Wono = @gWono
	AND UNIQ_KEY = @gUniq_key
	AND Id_Key = 'W_KEY'
	AND Id_Value = @lcW_key
	AND LotCode = @lcLotCode
	AND ISNULL(EXPDATE,1) = ISNULL(CASE WHEN @ldExpdate='' THEN NULL ELSE CAST(@ldExpdate AS smalldatetime) END,1)
	--AND ExpDate = @ldExpDate
	AND Reference = @lcReference
	AND IsReserved = 0
	ORDER BY Serialno