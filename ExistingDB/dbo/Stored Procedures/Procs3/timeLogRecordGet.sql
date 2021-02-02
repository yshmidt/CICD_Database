-- =============================================
-- Author:		David Sharp
-- Create date: 7/3/2012
-- Description:	Get a specific time record
--- 06/13/16 YS currently is not working, comment the code and will check if we can remove it
-- =============================================
CREATE PROCEDURE [dbo].[timeLogRecordGet]
	-- Add the parameters for the stored procedure here
	@uniqlogin varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    --Get the max permitted mintues to display warning if exceeded.
    DECLARE @max int
	SELECT @max = [MAXHRINSYS]*60 FROM TMLOGST

	--SELECT *,CASE WHEN DATEDIFF(minute,DATE_IN,DATE_OUT)>@max THEN 1 ELSE 0 END AS excessHrs
	--	FROM DEPT_LGT
	--	WHERE UNIQLOGIN=@uniqlogin
	--UNION ALL
	--SELECT *,CASE WHEN DATEDIFF(minute,DATE_IN,DATE_OUT)>@max THEN 1 ELSE 0 END AS excessHrs
	--	FROM DEPT_CUR
	--	WHERE UNIQLOGIN=@uniqlogin
		
	----Get the time types
	--SELECT TMLOG_NO timeType,TMLOG_DESC descript,NUMBER,TMLOGTPUK timeTypeId fROM TMLOGTP
		

END