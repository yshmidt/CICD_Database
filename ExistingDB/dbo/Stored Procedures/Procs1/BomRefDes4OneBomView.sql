CREATE PROC [dbo].[BomRefDes4OneBomView] @gUniq_key char(10)=' '
AS 
SELECT Bom_ref.Uniqbomno, Ref_des, Nbr, Bomparent, Item_no
	FROM Bom_ref, Bom_det 
	WHERE Bom_ref.Uniqbomno = Bom_det.Uniqbomno
	AND Bomparent = @gUniq_key




