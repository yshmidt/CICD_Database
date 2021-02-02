-- =============================================
-- Author:		Vicky Lu
-- Create date: <Create Date,,>
-- Description:	Get DM tax record
-- Modified:	
-- 05/03/16 VL: Added TaxDesc from Taxtabl
-- 09/01/16 VL: Change inner join to left outer join and show 'N/A' as tax_id and tax_desc for the old records that have no tax_id associated
-- 06/28/17 VL: Found comment in 09/01/16 to change from inner join to outer join, but the code still use innver join, changed again
-- =============================================
CREATE PROCEDURE [dbo].[ApDmdetlTaxView]
	-- Add the parameters for the stored procedure here
	@gcUniqDMHead as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT UniqApdmdetlTax, UniqDmhead, Uniqdmdetl, CASE WHEN ApDmdetlTax.Tax_id<>'' THEN ApDmdetlTax.Tax_id ELSE 'N/A     ' END AS Tax_id, ApDmdetlTax.Tax_Rate,
		ISNULL(Taxdesc, 'N/A     ') AS TaxDesc
		FROM ApDmdetlTax LEFT JOIN TAXTABL
		ON ApDmdetlTax.TAX_ID = TAXTABL.TAX_ID
		WHERE UniqDmhead = @gcUniqDMHead
	
END