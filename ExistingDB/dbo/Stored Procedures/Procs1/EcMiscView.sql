CREATE PROC [dbo].[EcMiscView] @gUniqEcNo AS char(10) = ' '
AS
SELECT Uniqmiscno, Uniqecno, Descript, Cost, Type
FROM Ecmisc
WHERE Ecmisc.Uniqecno = @gUniqecno





