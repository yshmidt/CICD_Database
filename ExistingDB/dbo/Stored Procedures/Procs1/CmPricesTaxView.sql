-- =============================================
-- Author:		Vicky Lu
-- Create date: <Create Date,,>
-- Description:	Get CM price tax record
-- Modified:	
-- 05/03/16 VL: Added TaxDesc from Taxtabl
-- 10/31/16 VL: added PR fields
-- =============================================
CREATE PROC [dbo].[CmPricesTaxView] 
	-- Add the parameters for the stored procedure here
@gcCmUnique AS char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 03/18/15 VL changed to get Tax_amt info
		--SELECT CmpricesTax.*
		--	FROM CmpricesTax
		--	WHERE CmpricesTax.CmUnique= @gcCmUnique

-- 10/31/16 VL added PR fields
DECLARE @CMTax TABLE (UniqCmpricesTax char(10), CmprUniq char(10), Tax_amt numeric(12,4), Tax_amtFC numeric(12,4), Tax_amtPR numeric(12,4))

-- 10/31/16 VL added PR fields
;WITH zPtax AS
(SELECT UniqCmpricesTax, Cmpricestax.Cmpruniq, ISNULL(SUM(Cmextended*Tax_rate/100),0) AS Tax_amt, ISNULL(SUM(CmextendedFC*Tax_rate/100),0) AS Tax_amtFC, ISNULL(SUM(CmextendedPR*Tax_rate/100),0) AS Tax_amtPR
	FROM Cmprices, Cmpricestax
	WHERE Cmprices.CmPruniq= CmpricesTax.CmPruniq
	AND Cmpricestax.Taxtype = 'P'
	AND CmpricesTax.CmUnique = @gcCmUnique
	GROUP BY UniqCmpricestax, Cmpricestax.Cmpruniq),
zEtax AS
(SELECT UniqCmpricesTax, Cmpricestax.Cmpruniq, ISNULL(SUM(Cmextended*Tax_rate/100),0) AS Tax_amt, ISNULL(SUM(CmextendedFC*Tax_rate/100),0) AS Tax_amtFC, ISNULL(SUM(CmextendedPR*Tax_rate/100),0) AS Tax_amtPR
	FROM Cmprices, Cmpricestax
	WHERE Cmprices.CmPruniq= CmpricesTax.CmPruniq
	AND Cmpricestax.Taxtype = 'E'
	AND CmpricesTax.CmUnique = @gcCmUnique
	GROUP BY UniqCmpricestax, Cmpricestax.Cmpruniq),
zEtax2 as
(SELECT Cmpricestax.UniqCmpricesTax, Cmpricestax.Cmpruniq, ZPTax.Tax_amt*Tax_rate/100 AS Tax_amt, ZPTax.Tax_amtFC*Tax_rate/100 AS Tax_amtFC, ZPTax.Tax_amtPR*Tax_rate/100 AS Tax_amtPR
	FROM Cmpricestax, ZPtax
	WHERE Cmpricestax.CmprUniq = ZPtax.Cmpruniq
	AND Cmpricestax.Taxtype = 'E'
	AND CmpricesTax.Sttx = 1
	AND CmpricesTax.CmUnique = @gcCmUnique),
zSTax AS 
(SELECT UniqCmpricesTax, Cmpricestax.Cmpruniq, ISNULL(SUM(Cmextended*Tax_rate/100),0) AS Tax_amt, ISNULL(SUM(CmextendedFC*Tax_rate/100),0) AS Tax_amtFC, ISNULL(SUM(CmextendedPR*Tax_rate/100),0) AS Tax_amtPR
	FROM Cmprices, Cmpricestax
	WHERE Cmprices.CmPruniq= CmpricesTax.CmPruniq
	AND Cmpricestax.Taxtype = 'S'
	AND CmpricesTax.CmUnique = @gcCmUnique
	GROUP BY UniqCmpricestax, Cmpricestax.Cmpruniq)

-- 10/31/16 VL added PR fields
INSERT INTO @CMTax 
	SELECT * FROM ZPtax
	UNION
	SELECT * FROM ZEtax
	UNION
	SELECT * FROM ZEtax2
	UNION
	SELECT * FROM ZStax
;WITH ZTax AS 
(SELECT UniqCmpricesTax, ROUND(ISNULL(SUM(Tax_Amt),0),2) AS Tax_Amt, ROUND(ISNULL(SUM(Tax_AmtFC),0),2) AS Tax_AmtFC, ROUND(ISNULL(SUM(Tax_AmtPR),0),2) AS Tax_AmtPR
	FROM @CMTax
	GROUP BY UniqCmpricesTax)

--  05/03/16 VL added Taxtabl.TaxDesc
--SELECT CmpricesTax.*, ZTax.Tax_amt, ZTax.Tax_amtFC
--			FROM CmpricesTax, ZTax
--			WHERE CmpricesTax.UniqCmpricesTax = ZTax.UniqCmpricesTax
--			AND CmpricesTax.CmUnique= @gcCmUnique
-- 10/31/16 VL added PR fields
SELECT CmpricesTax.*, ZTax.Tax_amt, ZTax.Tax_amtFC, ZTax.Tax_amtPR, TaxDesc
			FROM CmpricesTax INNER JOIN ZTax
			ON CmpricesTax.UniqCmpricesTax = ZTax.UniqCmpricesTax
			INNER JOIN TAXTABL
			ON CMPRICESTAX.TAX_ID = TAXTABL.Tax_id
			WHERE CmpricesTax.CmUnique= @gcCmUnique


END