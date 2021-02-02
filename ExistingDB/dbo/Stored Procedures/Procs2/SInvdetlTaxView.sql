-- =============================================
-- Author:		Vicky Lu
-- Create date: <Create Date,,>
-- Description:	Get PO reconcilation tax record
-- Modified:	
-- 05/03/16 VL: Added TaxDesc from Taxtabl
-- 09/06/16 VL: Change inner join to left outer join and show 'N/A' as tax_id and tax_desc for the old records that have no tax_id associated
-- =============================================
CREATE PROCEDURE [dbo].[SInvdetlTaxView]
	-- Add the parameters for the stored procedure here
	@gcsInv_uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT UniqSInvdetlTax, Sinv_uniq, Sdet_uniq, CASE WHEN SinvdetlTax.Tax_id<>'' THEN SinvdetlTax.Tax_id ELSE 'N/A     ' END AS Tax_id, SinvdetlTax.Tax_Rate, ISNULL(Taxdesc, 'N/A     ') AS TaxDesc
		FROM SinvdetlTax LEFT OUTER JOIN Taxtabl
		ON SinvdetlTax.Tax_id = Taxtabl.Tax_id
		WHERE SInv_Uniq = @gcsInv_uniq
	
END