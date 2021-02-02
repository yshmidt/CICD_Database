-- =============================================
-- Author:		Shripati
-- Create date: 09/06/2011
-- Description:	Check Group Exist
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_GroupExist] 
	-- Add the parameters for the stored procedure here
	@groupId      uniqueidentifier=null,
	@groupName VARCHAR(50) 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Select statements for procedure here
	IF(@groupId IS NOT NULL) 
    SELECT COUNT(groupName) FROM aspmnx_Groups WHERE groupId !=@groupId and groupName=@groupName;
	ELSE
	SELECT COUNT(groupName) FROM aspmnx_Groups WHERE groupName=@groupName;
END