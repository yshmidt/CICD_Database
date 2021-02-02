-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/05/2016
-- Description:	Product Type Feature setup, used in Product Type setup
-- Modification"
-- 05/09/16 VL	Added Old_IsRequired, so can be used in SO module and don't need to create 2nd similar SP 
-- =============================================
CREATE PROCEDURE [dbo].[ProdFetrView]
	-- Add the parameters for the stored procedure here
	@ProdTpUniq as Char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT Feature.Descript, Prodfetr.prodtpuniq, Prodfetr.pdfetruniq, Prodfetr.prodfeuniq, Prodfetr.isrequired, Prodfetr.isexcl, Prodfetr.ISREQUIRED AS Old_isrequired
		FROM Prodfetr INNER JOIN Feature
		ON Prodfetr.ProdFeUniq = Feature.ProdFeUniq
		WHERE ProdFetr.ProdTpUniq = @ProdTpUniq
		ORDER BY Feature.Descript
 	
END