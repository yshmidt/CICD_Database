-- =============================================
-- Author:	Mahesh B
-- Create date: 01-28-2020
-- Description: Adding the New Work Order Log detail
-- =============================================
CREATE PROCEDURE AddNewWorkOrderLogDetails
 @userId UNIQUEIDENTIFIER,  
 @record VARCHAR(10),  
 @dept_id VARCHAR(10),  
 @timeType VARCHAR(10),  
 @isHoliday BIT = 0,  
 @deleted BIT = 0,  
 @comment VARCHAR(MAX)='',  
 @number INT,
 @originalDateIn DATETIME,
 @originalDateOut DATETIME,
 @uniqLogin CHAR(10) =''  OUTPUT,
 @timeUsed INT

AS
BEGIN
	DECLARE @initials VARCHAR(4)  
	SELECT @initials = Initials FROM aspnet_Profile WHERE UserId=@userId  
	SET @record = CASE WHEN @record='' THEN @record ELSE dbo.padl(RTRIM(LTRIM(@record)),10,'0') END
	SET @uniqLogin = dbo.fn_GenerateUniqueNumber()

	INSERT INTO DEPT_LGT(  
	WONO  
	,DEPT_ID  
	,NUMBER  
	,TIME_USED  
	,originalDateIn  
	,DATE_IN  
	,originalDateOut  
	,DATE_OUT  
	,inUserId  
	,LOG_INIT  
	,outUserId  
	,LOGOUT_INI  
	,TMLOGTPUK  
	,OVERTIME  
	,IS_HOLIDAY  
	,UNIQLOGIN  
	,uDeleted  
	,comment  
	,LastUpdatedBy
	,LastUpdatedDate
	) VALUES(
	@record,
	@dept_id,
	@number,
	(CASE WHEN @timeUsed = 0 THEN DATEDIFF(MINUTE,@originalDateIn,@originalDateOut) ELSE  @timeUsed * 60 END),
	(CASE WHEN @timeUsed != 0 THEN NULL ELSE  @originalDateIn END),  --@originalDateIn,
	(CASE WHEN @timeUsed != 0 THEN NULL ELSE  @originalDateIn END),  --@originalDateIn,
	(CASE WHEN @timeUsed != 0 THEN NULL ELSE  @originalDateOut END), --@originalDateOut,
	(CASE WHEN @timeUsed != 0 THEN NULL ELSE  @originalDateOut END), --@originalDateOut,
	@userId,
	@initials,
	@userId,
	@initials,
	@timeType,
	0, --OVERTIME
	@isHoliday,
	@uniqLogin,
	0, --uDeleted
	@comment,
	@userId,
	GETDATE()
	)
END