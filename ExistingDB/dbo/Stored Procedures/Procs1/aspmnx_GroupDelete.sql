-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/06/2011
-- Description:	Delete Group
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_GroupDelete] 
	-- Add the parameters for the stored procedure here
	@Groupid uniqueidentifier 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --This will not only remove record from the Groups table, but also from GroupRoles and GroupUsers based on the foreign key 
    DELETE FROM aspmnx_Groups WHERE GroupId=@GroupId;
	
END