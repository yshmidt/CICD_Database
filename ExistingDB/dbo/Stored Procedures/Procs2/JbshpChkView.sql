CREATE PROC [dbo].[JbshpChkView] @lcJbShpChkUk AS char(10) = ' '
AS

BEGIN
SELECT *
	FROM JbshpChk
	WHERE JBSHPCHKUK = @lcJbShpChkUk

END