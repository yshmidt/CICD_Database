CREATE PROC [dbo].[BomReplView] @lcUniq_key AS char(10) = ' '
AS
BEGIN

SELECT CAST(1 AS bit) as Checkon, Part_no, Revision, Part_class, Part_type, Descript, Bom_status,
	CASE WHEN CustName IS NULL THEN SPACE(30) ELSE CustName END AS CustName,
	Item_no, Uniqbomno, Bomparent, Bom_det.uniq_key, Dept_id, Qty, Item_note, Offset, Term_dt, Eff_dt, Used_inkit
	FROM Bom_det INNER JOIN Inventor 
		LEFT OUTER JOIN Customer
	ON Inventor.bomcustno = Customer.custno
	ON Bomparent = Inventor.Uniq_key
	WHERE Bom_det.Uniq_key = @lcUniq_key
	AND 1 = CASE WHEN (Eff_dt IS NULL OR DATEDIFF(day,EFF_DT,GETDATE())>=0)
						AND (Term_dt IS NULL OR DATEDIFF(day,GETDATE(),Term_dt)>0) 
			THEN 1 ELSE 0 END

END