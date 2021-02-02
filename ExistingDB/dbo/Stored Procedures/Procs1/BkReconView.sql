-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/09/2012
-- Description:	Bank Reconciliation
-- =============================================
CREATE PROCEDURE [dbo].[BkReconView]
	-- Add the parameters for the stored procedure here
	@lcReconUniq char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    SELECT [RECONUNIQ]
      ,[RECONDATE]
      ,[STMTDATE]
      ,bkrecon.[BK_UNIQ]
      ,[StmtTotalDep]
      ,[StmtWithdrawl]
      ,[SVCCHGS]
      ,[INTEARNED]
      ,[RECONSTATUS]
      ,[RECONNOTE]
      ,[INIT]
      ,[EDITDT]
      ,[EDITHIST]
      ,[EDITREASON]
      ,[ThisStmtBalance]
      ,[DEPCORR]
      ,[DEPNOTE]
      ,[WITHDRCORR]
      ,[WITHDRNOTE]
      ,[LASTSTMBAL]
      ,[LASTSTMTDT]
      ,Banks.bk_acct_no
      ,Banks.accttitle 
      ,Banks.bank
      ,Banks.gl_nbr
      , Banks.bc_gl_nbr
      , Banks.int_gl_nbr
      ,Banks.BANK_BAL 
	FROM bkrecon INNER JOIN BANKS 
    ON  Bkrecon.bk_uniq = Banks.bk_uniq
	WHERE  Bkrecon.reconuniq = @lcReconUniq
  
END