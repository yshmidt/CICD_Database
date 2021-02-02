CREATE PROC [dbo].[EcDetlView] @gUniqEcNo AS char(10) = ' '
AS
SELECT Uniqecdet, Uniqecno, Ecdetl.Uniq_key, Detstatus, Oldqty, Newqty, Used_inkit, Part_class, 
	Part_type, Custno, Part_no, Revision, Custpartno, Custrev, Descript, Part_sourc, Chgamt, Item_no, 
	Scrapitem, Ecdetl.Stdcost, Dept_id, Uniqbomno, Status, U_of_meas
FROM Ecdetl INNER JOIN Inventor
ON Ecdetl.Uniq_key = Inventor.Uniq_key
WHERE Ecdetl.UniqEcNo = @gUniqEcNo
ORDER BY Item_no










