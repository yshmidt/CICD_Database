-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/06/2011
-- Description:	Remove User from a group
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_RemoveUserFromGroup] 
	-- Add the parameters for the stored procedure here
	@GroupUserId uniqueidentifier
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    
	DELETE FROM aspmnx_GroupUsers WHERE aspmnx_GroupUsers.groupusersID=@GroupUserId;
	
END
