-- =============================================
-- Author:		David Sharp
-- Create date: 6/22/2012
-- Description:	get a list of all time records over the last x days
-- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
-- Raviraj P : 1/19/2017 By default sort with DATE_IN column
-- =============================================
CREATE PROCEDURE [dbo].[timeLogAllGet] 
	@dateIn datetime, 
	@dateOut datetime, 
	@userId uniqueidentifier = null, 
	@gridId varchar(50) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
    IF @userId IS NULL
		BEGIN
			;WITH timeLogFullLog As ( -- Raviraj P : 1/19/2017 By default sort with DATE_IN column
				SELECT	WONO,DEPT_ID,DEPT_CUR.NUMBER,TIME_USED,
							originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
							DEPT_CUR.TMLOGTPUK,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted,TMLOGTP.TMLOG_DESC -- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
					FROM DEPT_CUR 
					INNER JOIN  TMLOGTP on DEPT_CUR.TMLOGTPUK = TMLOGTP.TMLOGTPUK -- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
					WHERE (originalDateIn >= @dateIn) AND (originalDateOut <= @dateOut)
				UNION ALL
				SELECT	WONO,DEPT_ID,DEPT_LGT.NUMBER,TIME_USED,
							originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
							DEPT_LGT.TMLOGTPUK,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted,TMLOGTP.TMLOG_DESC -- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
					FROM DEPT_LGT 
					INNER JOIN TMLOGTP on DEPT_LGT.TMLOGTPUK = TMLOGTP.TMLOGTPUK -- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
					WHERE originalDateIn >= @dateIn AND originalDateOut <= @dateOut )

					SELECT * from timeLogFullLog order by DATE_IN desc; -- Raviraj P : 1/19/2017 By default sort with DATE_IN column
		END
    ELSE
		BEGIN
				;WITH timeLogFullLog As ( -- Raviraj P : 1/19/2017 By default sort with DATE_IN column
				SELECT	WONO,DEPT_ID,DEPT_CUR.NUMBER,TIME_USED,
							originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
							DEPT_CUR.TMLOGTPUK,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted,TMLOGTP.TMLOG_DESC -- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
					FROM DEPT_CUR 
					INNER JOIN TMLOGTP on DEPT_CUR.TMLOGTPUK = TMLOGTP.TMLOGTPUK -- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
					WHERE inUserId = @userId AND originalDateIn >= @dateIn AND originalDateOut <= @dateOut
				UNION ALL
				SELECT	WONO,DEPT_ID,DEPT_LGT.NUMBER,TIME_USED,
							originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
							DEPT_LGT.TMLOGTPUK,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted,TMLOGTP.TMLOG_DESC -- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
					FROM DEPT_LGT 
					INNER JOIN TMLOGTP on DEPT_LGT.TMLOGTPUK = TMLOGTP.TMLOGTPUK -- Raviraj P : 1/9/2017 Display TMLOG_DESC with time log data
					WHERE inUserId = @userId AND originalDateIn >= @dateIn AND originalDateOut <= @dateOut 
				)
				SELECT * from timeLogFullLog order by DATE_IN desc; -- Raviraj P : 1/19/2017 By default sort with DATE_IN column
		END
	
	--Added for grid customization 7/20/2012
	EXEC MnxUserGetGridConfig @userId, @gridId

END