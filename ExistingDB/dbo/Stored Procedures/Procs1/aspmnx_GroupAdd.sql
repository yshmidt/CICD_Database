
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/06/2011
-- Description:	Insert New Group and return GroupId
-- 07/06/2017  Shripati to remove group description
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_GroupAdd]
	-- Add the parameters for the stored procedure here
	@Groupid uniqueidentifier , 
	@GroupName varchar(250)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 07/06/2017  Shripati to remove group description
	INSERT INTO aspmnx_Groups (GroupId,GroupName) VALUES (@groupId,@GroupName);
	
END