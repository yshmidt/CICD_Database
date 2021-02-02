-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/10/2016
-- Description:	Order Configuration Feture
-- =============================================
CREATE PROCEDURE [dbo].[CnfgFetrView]
	@gUniq_key char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT Cnfgfetr.isrequired, Feature.descript, Cnfgfetr.uniq_key, Cnfgfetr.pdfetruniq, Cnfgfetr.uniq_fetr,
		Prodfetr.isrequired AS old_isrequired, Prodfetr.isexcl
	FROM Cnfgfetr INNER JOIN ProdFetr ON CnfgFetr.PdfetrUniq = Prodfetr.PdfetrUniq
	INNER JOIN Feature ON Prodfetr.PRODFEUNIQ = Feature.PRODFEUNIQ
	WHERE CnfgFetr.UNIQ_KEY = @gUniq_key
	ORDER BY Feature.descript
END