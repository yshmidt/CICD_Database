CREATE PROC [dbo].[Invtmfgr4W_keyView] @lcW_key AS char(10) = ''
AS
SELECT *
	FROM InvtMfgr
	WHERE W_KEY = @lcW_key



