CREATE PROC [dbo].[QatmplwoView] @lcTemplUniq AS char(10) = ' '
AS
	SELECT * 
		FROM Qatmplwo
		WHERE TEMPLUNIQ = @lcTemplUniq
