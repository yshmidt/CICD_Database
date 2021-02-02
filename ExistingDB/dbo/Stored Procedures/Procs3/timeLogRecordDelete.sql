-- =============================================
-- Author:		David Sharp
-- Create date: 6/22/2012
-- Description:	delete a time record.  If trueDelete is not set, it marks the record as deleted and adds the comment.
-- =============================================
CREATE PROCEDURE [dbo].[timeLogRecordDelete]
	-- Add the parameters for the stored procedure here
	@uniqlogin varchar(10),
	@comment varchar(MAX)='',
	@trueDelete bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @trueDelete = 1
    BEGIN
		DELETE FROM DEPT_LGT WHERE UNIQLOGIN=@uniqlogin
		DELETE FROM DEPT_CUR WHERE UNIQLOGIN=@uniqlogin
    END
    ELSE
    BEGIN
		UPDATE DEPT_LGT SET uDeleted=1,comment=@comment WHERE UNIQLOGIN=@uniqlogin
		UPDATE DEPT_CUR SET uDeleted=1,comment=@comment WHERE UNIQLOGIN=@uniqlogin
		
		-- If the record was in the DEPT_CUR table, move to DEPT_LGT
		INSERT INTO DEPT_LGT(WONO,DEPT_ID,NUMBER,TIME_USED,
							originalDateIn,DATE_IN,originalDateOut,DATE_OUT,inUserId,LOG_INIT,
							TMLOGTPUK,OVERTIME,IS_HOLIDAY,UNIQLOGIN,uDeleted,comment,LOGOUT_INI)
		SELECT WONO,DEPT_ID,NUMBER,
					DATEDIFF(minute,DATE_IN,GETDATE()),
					originalDateIn,DATE_IN,
					GETDATE(),GETDATE(),--originalDateOut, DATE_OUT
					inUserId,LOG_INIT,
					TMLOGTPUK,OVERTIME,IS_HOLIDAY,UNIQLOGIN,uDeleted,comment,'DELETED'
			FROM DEPT_CUR WHERE UNIQLOGIN=@UNIQLOGIN
			
		DELETE FROM DEPT_CUR WHERE UNIQLOGIN=@UNIQLOGIN
    END
	

END