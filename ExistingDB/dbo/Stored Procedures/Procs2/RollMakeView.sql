
CREATE PROC [dbo].[RollMakeView]

AS
BEGIN
SET NOCOUNT ON;

SELECT Uniq_field, Rundate, Curlevel, Maxlevel
	FROM Rollmake

END 






