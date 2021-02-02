-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/06/2011
-- Description:	Assign User to a group
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_AddUserToGroup] 
	-- Add the parameters for the stored procedure here
	@Groupid uniqueidentifier , 
	@UserId uniqueidentifier
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --GroupuserId will be auto generated
	INSERT INTO aspmnx_GroupUsers (fkGroupId,fkUserId) VALUES (@groupId,@UserId);
	
END
