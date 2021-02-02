CREATE PROC [dbo].[WoParentView] @gWono AS char(10) = ''
AS
SELECT ParentWo, ChildWo, WChildPaUk, Part_no, Revision
	FROM Wchildpa, Woentry, Inventor
	WHERE Wchildpa.ParentWo = Woentry.Wono
	AND Woentry.Uniq_key = Inventor.Uniq_key
	AND ChildWo = @gWono
	ORDER BY 1,2,3,4,5