-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <09/07/2011>
-- Description:	Get Users information. Will return multiple data sets
-- 4. All Groups and those that are assigned to a given user
-- Modified:	01/29/16 DRP:  User requested that the results be ordered by GroupName.  So on screen they would be in order within the Group/User Setup
-- =============================================

CREATE PROCEDURE [dbo].[aspmnxSP_GetUserGroups]
	-- Add the parameters for the stored procedure here
	@UserId uniqueidentifier=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    ----4. All Groups and those that are assigned to a given user
	-- Removed GroupDescr column  Updated by Shripati
	SELECT Groupid,groupName,isnull(Z.Assigned,cast(0 as bit)) as Assigned	  
	from aspmnx_Groups OUTER APPLY (SELECT CAST(1 as bit) as Assigned from aspmnx_groupUsers where fkUserId = @UserId and fkgroupid =aspmnx_Groups.groupId ) as Z  
	order by groupname	--01/29/16 DRP:  added sort order per request
END
