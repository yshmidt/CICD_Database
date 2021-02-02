CREATE PROC [dbo].[OpenCARView] 
AS
BEGIN
SELECT EstComp_dt, NewDue_dt, Carno, Prob_type, compdate, completeby
	FROM CRACTION
	WHERE (COMPDATE IS NULL 
	OR COMPLETEBY = '')
	ORDER BY ESTCOMP_DT, NEWDUE_DT, CARNO
	
END
