CREATE PROC [dbo].[Bom_Det_CustPartNo_View] @gUniq_key AS char(10) = ' ', @gCustno AS char(10) = ' '
AS
SELECT CustPartNo, CustRev, Bom_det.Uniq_key
	FROM INVENTOR, BOM_DET
	WHERE INVENTOR.INT_UNIQ = BOM_DET.UNIQ_KEY 
	AND Inventor.Custno = @gCustNo 
	AND INVENTOR.PART_SOURC = 'CONSG'
	AND BOM_DET.BOMPARENT = @gUniq_key




