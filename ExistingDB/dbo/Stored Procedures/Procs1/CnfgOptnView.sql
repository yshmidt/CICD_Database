-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/11/2016
-- Description:	Order Configuration Options
-- =============================================
CREATE PROCEDURE [dbo].[CnfgOptnView]
	@gUniq_key char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT Cnfgoptn.isrequired, Inventor.part_class, Inventor.part_type, Inventor.part_no, Inventor.revision, Inventor.descript,
		Inventor.u_of_meas, Cnfgoptn.qtyper, Cnfgoptn.extendqty, Cnfgoptn.stdprice, Cnfgoptn.saleprice, Cnfgoptn.pdoptnuniq,
		Cnfgoptn.uniq_price, Cnfgoptn.uniq_optn, (Prodoptn.isrequired) AS old_isrequired, Cnfgoptn.uniq_fetr, Cnfgoptn.uniq_key, Cnfgoptn.compunqkey, Inventor.stdcost,
		Cnfgoptn.stdpricefc, Cnfgoptn.salepricefc
	FROM CnfgOptn INNER JOIN Prodoptn 
	ON (CnfgOptn.PDOPTNUNIQ = Prodoptn.PDOPTNUNIQ AND Cnfgoptn.COMPUNQKEY = Prodoptn.UNIQ_KEY)
	INNER JOIN Inventor 
	ON CnfgOptn.COMPUNQKEY = Inventor.Uniq_key 
	WHERE CnfgOptn.Uniq_key = @gUniq_key 
	ORDER BY Inventor.Part_no, Inventor.Revision
END