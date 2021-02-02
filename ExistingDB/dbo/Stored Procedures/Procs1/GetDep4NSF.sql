CREATE PROCEDURE dbo.GetDep4NSF
	-- Add the parameters for the stored procedure here
	@gcDep_no as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Bank, Banks.Bk_Acct_no, Acct_Type, AcctTitle,Banks.Gl_nbr,Banks.Bk_uniq 
	FROM Deposits, Banks 
	WHERE Deposits.Bk_Uniq = Banks.Bk_Uniq 
		AND Deposits.Dep_no = @gcDep_No 
	

END