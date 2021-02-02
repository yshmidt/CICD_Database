
CREATE PROCEDURE [dbo].[ContractAddPartView] @gUniqSupno as Char(10)=' '
AS
BEGIN
--- 06/13/18 YS contract structure has changed
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT Part_no, Revision, Descript, Part_class, Part_type, Uniq_key
	FROM Inventor
	WHERE (Part_Sourc = 'BUY' OR Part_Sourc = 'MAKE') 
	AND Status = 'Active'
	AND Uniq_key NOT IN 
		--- 06/13/18 YS contract structure has changed
		(SELECT Uniq_key FROM Contract inner join contractheader h on contract.contracth_unique=h.contracth_unique  WHERE UniqSupno = @gUniqSupno)
	ORDER BY 1,2

END