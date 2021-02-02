-- =============================================
-- Author:		Vicky Lu
-- Create date: <02/05/2015>
-- Description:	Get tax by PO uniquelnno
-- Modified:	
-- 05/03/16 VL: Added TaxDesc from Taxtabl
-- =============================================
CREATE PROCEDURE [dbo].[GetTaxbyPOUniqlnno] 
@Uniqlnno varchar(max) = ' '
AS

BEGIN
DECLARE @POUniqlnno TABLE (Uniqlnno char(10))
INSERT INTO @POUniqlnno SELECT * from dbo.fn_simpleVarcharlistToTable(@Uniqlnno,',') 

SELECT Uniqlnno, PoitemsTax.Tax_id, PoitemsTax.Tax_rate, Taxdesc
	FROM PoitemsTax INNER JOIN Taxtabl
	ON PoitemsTax.Tax_id = Taxtabl.Tax_id  
	WHERE Uniqlnno IN (SELECT Uniqlnno FROM @POUniqlnno)
END     