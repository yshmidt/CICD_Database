
CREATE PROC [dbo].[MiscMainview] (@gWono char(10) ='')
AS
SELECT Miscmain.Misckey, Wono, Dept_id, Part_no, Revision, Descript, Miscmain.ShortQty, Qty, Part_sourc, Part_class, 
	Part_type, Shreason, Bomparent, cSavedBy
	FROM Miscmain
	WHERE Miscmain.Wono = @gWono 
	ORDER BY Misckey







