-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/06/2011
-- Description:	Remove Role from a group
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_RemoveRoleFromGroup] 
	-- Add the parameters for the stored procedure here
	@GroupRoleId uniqueidentifier
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   
	DELETE FROM aspmnx_GroupRoles WHERE GroupRoleId=@GroupRoleId;
	
END