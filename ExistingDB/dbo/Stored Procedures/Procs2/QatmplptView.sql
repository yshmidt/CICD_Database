CREATE PROC [dbo].[QatmplptView] @lcTemplUniq AS char(10) = ' '
AS
	SELECT Qatmplpt.*, Part_no, Revision, Descript
		FROM Qatmplpt, Inventor
		WHERE Qatmplpt.Uniq_key = Inventor.Uniq_key 
		AND TEMPLUNIQ = @lcTemplUniq
		ORDER BY PART_NO, Revision	