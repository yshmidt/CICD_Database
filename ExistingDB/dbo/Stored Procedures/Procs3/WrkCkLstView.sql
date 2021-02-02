CREATE PROC [dbo].[WrkCkLstView] @gUniq_key AS char(10) = ''
AS
SELECT *
	FROM WrkCkLst
	WHERE UNIQ_KEY = @gUniq_key

