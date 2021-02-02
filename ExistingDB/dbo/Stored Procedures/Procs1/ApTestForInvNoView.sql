
CREATE PROCEDURE [dbo].[ApTestForInvNoView]
      -- Add the parameters for the stored procedure here
      @gcUniqApHead as char(10)= '', @gcInvNo as char(20) = '', @gcUniqSupNo as char(10)= ''
 
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
 
    -- Insert statements for procedure here
      select UniqApHead
            from ApMaster
            where UniqApHead <> @gcUniqApHead
                  and InvNo = @gcInvNo
                  and UniqSupNo = @gcUniqSupNo
 
END
