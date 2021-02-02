
-- 11/12/14 VL dded PriceFC for foreign currency module
-- 04/03/17 VL added PricePR for functional currency project

CREATE PROCEDURE [dbo].[ContPricView] @gContr_Uniq AS Char(10) = ' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT Quantity, Price, PriceFC, Pric_uniq, Mfgr_uniq, Contr_uniq, PricePR
	FROM Contpric
	WHERE Contpric.Contr_uniq = @gContr_uniq
	ORDER BY Quantity

END