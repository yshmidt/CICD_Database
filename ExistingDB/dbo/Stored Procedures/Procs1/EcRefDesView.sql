CREATE PROC [dbo].[EcRefDesView] @gUniqEcNo AS char(10) = ' '
AS
SELECT Uniqecrfno, Uniqecdet, Uniqbomno, Ref_des, Nbr, Uniqecno
	FROM Ecrefdes
	WHERE Ecrefdes.UniqEcNo = @gUniqEcNo
	ORDER BY Nbr






