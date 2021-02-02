CREATE PROCEDURE [dbo].[DepositView] 
	-- Add the parameters for the stored procedure here
	@gcDep_no as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 03/24/15 VL added fcused_uniq, fchist_key, tot_depFC and tot_depBK for FC
	-- 10/18/16 VL added Tot_depPR for presentation currency
	-- 12/10/20 VL added CreatedUserId and PaymentType
	SELECT Deposits.date, Deposits.bk_acct_no, Deposits.tot_dep,
  Deposits.dep_no, Banks.accttitle, Banks.acct_type, Banks.bank,
  Deposits.bk_uniq, BANKS.Gl_Nbr,DEPOSITS.cInitials,DEPOSITS.dDepDate, Deposits.tot_depFC, Deposits.tot_depBK, Deposits.Fcused_uniq, Deposits.Fchist_key, Deposits.Tot_DepPR, 
  Deposits.PRFcused_uniq, Deposits.FuncFcused_uniq,
  -- 12/10/20 VL added CreatedUserId and PaymentType
  CreatedUserId, deposits.PaymentType
 FROM deposits 
    INNER JOIN banks 
 ON  Deposits.bk_acct_no = Banks.bk_acct_no
 WHERE  Deposits.dep_no = @gcDep_no

END