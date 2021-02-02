CREATE PROC [dbo].[QatempltView] @lcTemplUniq AS char(10) = ' '
AS
	SELECT * 
		FROM Qatemplt
		WHERE TEMPLUNIQ = @lcTemplUniq
