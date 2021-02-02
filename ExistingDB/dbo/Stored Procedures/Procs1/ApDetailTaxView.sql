-- =============================================
-- Author:		Vicky Lu
-- Create date: <Create Date,,>
-- Description:	Get PO reconcilation tax record
-- Modified:	
-- 05/03/16 VL: Added TaxDesc from Taxtabl
-- 09/01/16 VL: Change inner join to left outer join and show 'N/A' as tax_id and tax_desc for the old records that have no tax_id associated
-- =============================================
CREATE PROCEDURE [dbo].[ApDetailTaxView]
	-- Add the parameters for the stored procedure here
	@gcUniqApHead as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT UniqApDetailTax, UniqApHead, UniqApdetl, CASE WHEN ApDetailTax.Tax_id<>'' THEN ApDetailTax.Tax_id ELSE 'N/A     ' END AS Tax_id, ApDetailTax.Tax_Rate, 
		ISNULL(Taxdesc, 'N/A     ') AS TaxDesc
		FROM ApDetailTax LEFT OUTER JOIN Taxtabl
		ON ApDetailTax.Tax_id = Taxtabl.Tax_id
		WHERE UniqApHead = @gcUniqApHead
	
END