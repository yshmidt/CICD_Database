-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/06/2011
-- Description:	Get list of the Groups
-- 07/06/2017 Shripati for Remove GroupDescr column 
-- =============================================
CREATE PROCEDURE [dbo].[aspmnxSP_GetGroups]
	-- Add the parameters for the stored procedure here	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/06/2017 Shripati for Remove GroupDescr column 
	SELECT GroupId,groupName FROM aspmnx_Groups ORDER BY groupName
END