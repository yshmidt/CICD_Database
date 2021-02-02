-- =============================================  
-- Author:  David Sharp  
-- Create date: 6/22/2012  
-- Description: Punch a user in to a job  
-- 10/10/2018 : Raviraj P : set client side timeout date  
-- 01/07/2020 : Mahesh B : Set the value of LastUpdatedBy
-- 03/12/2020 : Rajendra K : set client side timeout date to calculate TIME_USED
-- =============================================  
CREATE PROCEDURE [dbo].[timeLogPunchOut]   
 -- Add the parameters for the stored procedure here  
 @userId uniqueidentifier,  
 @UNIQLOGIN varchar(10),  
 @originalDateIn datetime  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
   
 DECLARE @initials varchar(4)  
 SELECT @initials = Initials FROM aspnet_Profile WHERE UserId=@userId  
    -- Insert statements for procedure here  
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
	,LastUpdatedBy -- 01/07/2020 : Mahesh B : Set the value of LastUpdatedBy
	)  
 SELECT 
    WONO
	,DEPT_ID
	,NUMBER
	,DATEDIFF(minute,DATE_IN,@originalDateIn)--GETDATE() -- 03/12/2020 : Rajendra K : set client side timeout date to calculate TIME_USED 
	,originalDateIn
	,DATE_IN
	,@originalDateIn
	,@originalDateIn--originalDateOut 10/10/2018 : Raviraj P : set client side timeout date  
  ,inUserId
	,LOG_INIT
	,@userId
	,@initials
	,TMLOGTPUK
	,OVERTIME
	,IS_HOLIDAY
	,UNIQLOGIN
	,uDeleted
	,comment
	,@userId-- 01/07/2020 : Mahesh B : Set the value of LastUpdatedBy
  FROM DEPT_CUR WHERE UNIQLOGIN=@UNIQLOGIN  
    
 DELETE FROM DEPT_CUR WHERE UNIQLOGIN=@UNIQLOGIN  
END