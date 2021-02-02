 
CREATE PROCEDURE [dbo].[ContractPart_noView]
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT DISTINCT Part_class, Part_type, Part_no, Revision, Descript, Contract.Uniq_key
FROM Contract, Inventor
WHERE Contract.Uniq_key = Inventor.Uniq_key
ORDER BY Part_no


END