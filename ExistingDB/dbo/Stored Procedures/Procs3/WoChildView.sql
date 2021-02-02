CREATE PROC [dbo].[WoChildView] @gWono AS char(10) = ''
AS
SELECT ChildWo, ParentWo, WChildPaUk, Part_no, Revision
	FROM Wchildpa, Woentry, Inventor
	WHERE Wchildpa.ChildWo = Woentry.Wono
	AND Woentry.Uniq_key = Inventor.Uniq_key
	AND ParentWo = @gWono
	ORDER BY 1,2,3,4,5