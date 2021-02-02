 
CREATE PROCEDURE [dbo].[ContractSupplierView] @gUniq_key AS Char(10) = ' '

AS
BEGIN
--06/13/18 YS contract structure has changed
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
--06/13/18 YS contract structure has changed
SELECT h.UniqSupno, 
	--Prim_sup, 
	contract.CONTR_UNIQ , Uniq_key, Supname
	FROM contractHeader h inner join Supinfo on h.uniqsupno=supinfo.UNIQSUPNO
	inner join contract on h.ContractH_unique=CONTRACT.contractH_unique 
	WHERE Contract.Uniq_key = @gUniq_key
	ORDER BY Supname

END