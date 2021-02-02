
CREATE PROCEDURE [dbo].[BomCustNoView] @sUniq_key char(10)=' ', @gCustno char(10)=' '

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;


SELECT Uniq_key,Part_class, Part_type, Custno, Part_no, Revision, CustPartno, Custrev, Descript, 
	U_of_meas, Pur_uofm, Ord_Policy, Package, No_pkg, Inv_note, Buyer_Type, StdCost, Minord, OrdMult,
	UserCost, Pull_in, Push_out, Status, GrossWt, ReOrderQty, ReordPoint, Part_Spec, Pur_ltime, Pur_lUnit,
	Kit_lTime, Kit_lUnit, Prod_lTime, Prod_lUnit, Part_Sourc, Day, DayofMo, DayofMo2, SaleTypeId, FeedBack,
	BomCustno, LaborCost, Int_Uniq, Prod_id, FgiNote
FROM Inventor
WHERE Int_uniq = @sUniq_key
AND Custno = @gCustNo
AND Part_sourc = 'CONSG     '



END


