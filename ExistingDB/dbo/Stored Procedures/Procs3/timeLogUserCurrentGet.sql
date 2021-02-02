-- =============================================
-- Author:		David Sharp
-- Create date: 6/22/2012
-- Description:	
-- 10/03/2018 : Raviraj P : Get user login type from TMLOGTP table
-- =============================================
CREATE PROCEDURE [dbo].[timeLogUserCurrentGet] 
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --Get the max permitted mintues to display warning if exceeded.
    DECLARE @max int
	SELECT @max = [MAXHRINSYS]*60 FROM TMLOGST
	
	SELECT *,DEPT_CUR.TMLOGTPUK AS timeTypeId,TMLOGTP.TMLOG_DESC AS LoginType,CASE WHEN DATEDIFF(minute,DATE_IN,DATE_OUT)>@max THEN 1 ELSE 0 END AS excessHrs FROM DEPT_CUR 
		LEFT JOIN  TMLOGTP on DEPT_CUR.TMLOGTPUK = TMLOGTP.TMLOGTPUK -- 10/03/2018 : Raviraj P : Get user login type from TMLOGTP table
		WHERE inUserId=@userId AND uDeleted = 0
END