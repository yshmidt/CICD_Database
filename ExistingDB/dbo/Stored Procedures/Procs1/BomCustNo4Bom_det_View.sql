CREATE PROC [dbo].[BomCustNo4Bom_det_View] @gUniq_key AS char(10) = ''
AS
SELECT BOMCUSTNO, Bom_det.UNIQ_KEY, Part_Sourc
	FROM BOM_DET, INVENTOR
	WHERE Bom_det.Uniq_key = Inventor.Uniq_key
	AND Bom_det.BomParent = @gUniq_key



