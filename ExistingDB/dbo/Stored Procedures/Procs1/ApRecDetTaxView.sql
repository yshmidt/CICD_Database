-- =============================================
-- Author:		Vicky Lu
-- Create date: <02/05/2015>
-- Description:	Get recurring AP tax records
-- Modified:	
-- 05/03/16 VL: Added TaxDesc from Taxtabl
-- 09/06/16 VL: Change inner join to left outer join and show 'N/A' as tax_id and tax_desc for the old records that have no tax_id associated
-- =============================================
CREATE PROCEDURE [dbo].[ApRecDetTaxView]
	-- Add the parameters for the stored procedure here
	@gcUniqRecur as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT UniqAprecdetTax, UniqRecur, Uniqdetrec, CASE WHEN Aprecdettax.Tax_id<>'' THEN Aprecdettax.Tax_id ELSE 'N/A     ' END AS Tax_id, Aprecdettax.Tax_Rate, ISNULL(Taxdesc, 'N/A     ') AS TaxDesc
		FROM Aprecdettax LEFT OUTER JOIN Taxtabl
		ON Aprecdettax.Tax_id = Taxtabl.Tax_id
		WHERE UniqRecur = @gcUniqRecur
	
END