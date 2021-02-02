
CREATE PROCEDURE [dbo].[ActivityVolumeView] @pShftDept_id AS char(4) = ' ', @pShftActiv_id AS char(4) = ' ', @pShftShift_no numeric(3,0) = 1
AS 

BEGIN
SET NOCOUNT ON;

SELECT *
	FROM Actcap
	WHERE Dept_id = @pShftDept_id
	AND Activ_id = @pShftActiv_id
	AND Shift_no = @pShftShift_no

END
