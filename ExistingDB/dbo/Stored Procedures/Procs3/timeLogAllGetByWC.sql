--======================================
-- Author:	Anuj K
-- Create date: 5/13/2016
-- Description:	get a list of all time records for provided work center
-- =============================================
CREATE PROCEDURE [dbo].[timeLogAllGetByWC] --'stag'
	@userId varchar(20),
	@wcName varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @userId IS NULL
    BEGIN
    	SELECT	distinct d.WONO,d.DEPT_ID,d.NUMBER,TIME_USED,
					originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
					t.TMLOG_DESC as TmLogDesc,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted
			FROM DEPT_CUR d JOIN TMLOGTP t ON d.TMLOGTPUK = t.TMLOGTPUK 
			WHERE DEPT_ID = @wcName
		UNION ALL
		SELECT	distinct WONO,DEPT_ID,d.NUMBER,TIME_USED,
					originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
					t.TMLOG_DESC as TmLogDesc,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted
			FROM DEPT_LGT d JOIN TMLOGTP t ON d.TMLOGTPUK = t.TMLOGTPUK WHERE DEPT_ID = @wcName
    END
    ELSE
    BEGIN
		SELECT distinct	d.WONO,d.DEPT_ID,d.NUMBER,TIME_USED,
					originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
					t.TMLOG_DESC as TmLogDesc,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted
			FROM DEPT_CUR d JOIN TMLOGTP t ON d.TMLOGTPUK = t.TMLOGTPUK WHERE inUserId = @userId AND DEPT_ID = @wcName
		UNION ALL
		SELECT	distinct WONO,DEPT_ID,d.NUMBER,TIME_USED,
					originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,outUserId,LOGOUT_INI,
					t.TMLOG_DESC as TmLogDesc,OVERTIME,IS_HOLIDAY,UNIQLOGIN,comment,uDeleted
			FROM DEPT_LGT d JOIN TMLOGTP t ON d.TMLOGTPUK = t.TMLOGTPUK WHERE inUserId = @userId AND DEPT_ID = @wcName
	END
	
	--Added for grid customization 7/20/2012
	--EXEC MnxUserGetGridConfig @userId, @gridId

END