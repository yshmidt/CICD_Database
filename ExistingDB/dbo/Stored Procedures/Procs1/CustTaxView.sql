-- =============================================
-- Author:		Vicky Lu
-- Create date: 
-- Description:	Get Customer Tax information
-- Modification:
-- 11/26/19 VL changed for cube version
-- =============================================
CREATE PROCEDURE [dbo].[CustTaxView]
	@lcCustno as char(10)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- 11/26/19 VL changed for cube version
--SELECT Shiptax.unqshiptax, Shiptax.linkadd, Shiptax.custno,
--  Shiptax.address1, Shiptax.taxdesc, Shiptax.taxtype, Shiptax.tax_rate,
--  Shiptax.tax_id, Shiptax.recordtype, Shiptax.ptprod, Shiptax.ptfrt,
--  Shiptax.stprod, Shiptax.stfrt, Shiptax.sttx
-- FROM 
--     shiptax
-- WHERE   Shiptax.recordtype = 'S' 
--   AND  Shiptax.custno = @lcCustno

SELECT Shiptax.unqshiptax, Shiptax.linkadd, Shiptax.custno,
  Shiptax.address1, Shiptax.taxdesc, Shiptax.taxtype, Shiptax.tax_rate,
  Shiptax.tax_id, Shiptax.recordtype, Shiptax.ptprod, Shiptax.ptfrt,
  Shiptax.stprod, Shiptax.stfrt, Shiptax.sttx,
  modifiedDate, DefaultTax, Shiptax.IsSynchronizedFlag, Taxtabl.TaxType AS SetupTaxType, Taxtabl.TAXUNIQUE, IsProductTotal, IsFreightTotals, TaxApplicableTo
 FROM 
     shiptax INNER JOIN TAXTABL ON Shiptax.Tax_id = TAXTABL.Tax_id
 WHERE   Shiptax.recordtype = 'S' 
   AND  Shiptax.custno = @lcCustno

END
