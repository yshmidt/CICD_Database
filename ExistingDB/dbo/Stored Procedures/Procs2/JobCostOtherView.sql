CREATE PROC [dbo].[JobCostOtherView] @lcWono  AS char(10) = ' '
AS
BEGIN
SELECT Wono, Othdescr, Othamnt, Savedate, Saveinit, Uniq_misc
	FROM Jobcostm
	WHERE Wono = @lcWono

END
