CREATE PROC [dbo].[Bom_det4Uniq_keyDept_idView] @gUniq_key AS char(10) = '', @lcDept_id AS char(4) = ''
AS
SELECT Uniq_key 
	FROM Bom_det 
	WHERE Bom_det.Bomparent = @gUniq_key
	AND Dept_id = @lcDept_id


