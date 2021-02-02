-- =============================================
-- Author:		David Sharp
-- Create date: 7/5/2012
-- Description:	Punch a user out of all jobs
-- Raviraj P 12/27/2016 : select & delete only the jobs information without day in/out details
-- 12/27/16 YS changed like '%DAY IN OR OUT%' to just '%DAY IN%' Currently user can overwrite our default login type and call it for example Day In/Out. 
-- In the new design when we control the types we can use an exact name.
-- right now I would just use DAY In part and hope, that the user has that part in the name. Otherwise we would have to tell them not to change default login types 
-- 01/06/17 YS change to check TMLOG_NO = 'T' - for day in out, user can change the decription
-- Raviraj P 10/04/2018 : -- Check record is exists or not in DEPT_CUR then insert 
-- =============================================
CREATE PROCEDURE [dbo].[timeLogPunchOutAll] 
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @initials varchar(4),@TMLOGTPUKDayInOrOutKey char(10)
	SELECT @initials = Initials FROM aspnet_Profile WHERE UserId=@userId
	---01/06/17 YS change to check TMLOG_NO = 'T' - for day in out, user can change the decription
	--SELECT @TMLOGTPUKDayInOrOutKey = TMLOGTPUK FROM TMLOGTP where TMLOG_DESC like '%DAY IN%'
	SELECT @TMLOGTPUKDayInOrOutKey = TMLOGTPUK FROM TMLOGTP where TMLOG_NO ='T'
    
	-- Raviraj P 10/04/2018 : -- Check record is exists or not in DEPT_CUR then insert 
	IF EXISTS(SELECT 1 FROM DEPT_CUR WHERE inUserId=@userId and TMLOGTPUK <> @TMLOGTPUKDayInOrOutKey AND UNIQLOGIN NOT IN (SELECT UNIQLOGIN FROM DEPT_LGT))
	BEGIN
	-- Insert statements for procedure here
		INSERT INTO DEPT_LGT(WONO,DEPT_ID,NUMBER,TIME_USED,
						originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
						TMLOGTPUK,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted)
		SELECT WONO,DEPT_ID,NUMBER,
				CAST(DATEDIFF(minute,DATE_IN,GETDATE())AS INT),
				originalDateIn,DATE_IN,
				GETDATE(),GETDATE(),--originalDateOut, DATE_OUT
				inUserId,LOG_INIT,@userId,@initials,
				TMLOGTPUK,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted
		FROM DEPT_CUR WHERE inUserId=@userId and TMLOGTPUK <> @TMLOGTPUKDayInOrOutKey -- Raviraj P 12/27/2016 : select & delete only the jobs information without day in/out details
				AND UNIQLOGIN NOT IN (SELECT UNIQLOGIN FROM DEPT_LGT)
	END	
	DELETE FROM DEPT_CUR WHERE inUserId=@userId and TMLOGTPUK <> @TMLOGTPUKDayInOrOutKey -- Raviraj P 12/27/2016 : select & delete only the jobs information without day in/out details
END