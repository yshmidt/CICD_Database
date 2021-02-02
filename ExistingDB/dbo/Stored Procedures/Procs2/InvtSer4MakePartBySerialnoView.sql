CREATE PROC [dbo].[InvtSer4MakePartBySerialnoView] @lcSerialno AS char(30) = ''
AS
SELECT INVTSER.*
	FROM INVTSER, Inventor 
	WHERE INVTSER.UNIQ_KEY = INVENTOR.UNIQ_KEY 
	AND INVENTOR.PART_SOURC = 'MAKE'
	AND Serialno = @lcSerialno
