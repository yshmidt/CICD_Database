CREATE PROC [dbo].[PlPricesTaxInfoView4NewCM] @gcPacklistNo AS char(10) = ' '
AS
BEGIN
-- 03/19/15 VL changed to not calculate tax_amt, and only get tax_rate (group by type) and will be used in form
--DECLARE @CMTax TABLE (UniqPlpricesTax char(10), Pluniqlnk char(10), Tax_amt numeric(12,4), Tax_amtFC numeric(12,4))
DECLARE @CMTax TABLE (UniqPlpricesTax char(10), Pluniqlnk char(10), Tax_rate numeric(8,4))

;WITH zPtax AS
(SELECT UniqPlpricesTax, PlpricesTax.PlUniqlnk, SUM(Tax_rate) AS Tax_rate -- SUM(Extended*Tax_rate/100) AS Tax_amt, SUM(ExtendedFC*Tax_rate/100) AS Tax_amtFC
	FROM Plprices, Plpricestax
	WHERE Plprices.Pluniqlnk= PlpricesTax.Pluniqlnk
	AND Plpricestax.Taxtype = 'P'
	AND PlpricesTax.Packlistno = @gcPacklistNo
	GROUP BY UniqPlpricesTax, PlpricesTax.PlUniqlnk),	
zEtax AS
(SELECT UniqPlpricesTax, PlpricesTax.PlUniqlnk, SUM(Tax_rate) AS Tax_rate -- SUM(Extended*Tax_rate/100) AS Tax_amt, SUM(ExtendedFC*Tax_rate/100) AS Tax_amtFC
	FROM Plprices, Plpricestax
	WHERE Plprices.Pluniqlnk= PlpricesTax.Pluniqlnk
	AND Plpricestax.Taxtype = 'E'
	AND PlpricesTax.Packlistno = @gcPacklistNo
	GROUP BY UniqPlpricesTax, PlpricesTax.PlUniqlnk),
zEtax2 as
(SELECT Plpricestax.UniqPlpricesTax, PlpricesTax.PlUniqlnk, ZPTax.Tax_rate*PlpricesTax.Tax_rate/100 AS Tax_rate -- ZPTax.Tax_amt*Tax_rate/100 AS Tax_amt, ZPTax.Tax_amtFC*Tax_rate/100 AS Tax_amtFC
	FROM Plpricestax, ZPtax
	WHERE Plpricestax.PlUniqlnk = ZPtax.PlUniqlnk
	AND Plpricestax.Taxtype = 'E'
	AND Plpricestax.Sttx = 1
	AND Plpricestax.Packlistno = @gcPacklistNo),
zSTax AS 
(SELECT UniqPlpricesTax, PlpricesTax.PlUniqlnk, SUM(Tax_rate) AS Tax_rate -- SUM(Extended*Tax_rate/100) AS Tax_amt, SUM(ExtendedFC*Tax_rate/100) AS Tax_amtFC
	FROM Plprices, Plpricestax
	WHERE Plprices.Pluniqlnk= PlpricesTax.Pluniqlnk
	AND Plpricestax.Taxtype = 'S'
	AND PlpricesTax.Packlistno = @gcPacklistNo
	GROUP BY UniqPlpricesTax, PlpricesTax.PlUniqlnk)

INSERT INTO @CMTax 
	SELECT * FROM ZPtax
	UNION
	SELECT * FROM ZEtax
	UNION
	SELECT * FROM ZEtax2
	UNION
	SELECT * FROM ZStax

;WITH ZTax AS 
(SELECT UniqPlpricesTax, PlUniqlnk, SUM(Tax_rate) AS Tax_rate -- SUM(Tax_Amt) AS Tax_Amt, SUM(Tax_AmtFC) AS Tax_AmtFC
	FROM @CMTax
	GROUP BY UniqPlpricesTax, PlUniqlnk)

SELECT PlpricesTax.*, ZTax.Tax_rate -- ZTax.Tax_amt, ZTax.Tax_amtFC
			FROM PlpricesTax, ZTax
			WHERE PlpricesTax.UniqPlpricesTax = ZTax.UniqPlpricesTax
			AND PlpricesTax.Packlistno= @gcPacklistNo

END