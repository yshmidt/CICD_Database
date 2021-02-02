CREATE PROCEDURE [dbo].[ApTestSinvoiceForInvNoView]
      -- Add the parameters for the stored procedure here
      @gcInvNo as char(20) = '', @gcUniqSupNo as char(10)= ''
 
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
 
    -- Insert statements for procedure here
      select Sinvoice.Sinv_uniq
            from Sinvoice
            where Sinvoice.InvNo = @gcInvNo
                   and Sinvoice.is_rel_Ap = 1
                   and EXISTS (SELECT 1 FROM ApMaster WHERE ApMaster.UniqSupNo = @gcUniqSupNo and Apmaster.UniqApHead=Sinvoice.fk_UniqApHead)
 
END