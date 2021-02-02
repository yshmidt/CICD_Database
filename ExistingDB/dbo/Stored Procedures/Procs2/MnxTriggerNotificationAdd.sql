-- =============================================  
-- Author:  David Sharp  
-- Create date: 10/29/2012  
-- Description: add a new message for a user  
-- 1/9/2019 Added new parameter to insert recordid,moduleRoute and moduleid
-- =============================================  
CREATE PROCEDURE [dbo].[MnxTriggerNotificationAdd]  
 -- Add the parameters for the stored procedure here  
 @noticeType varchar(50)= N'Notice' --Notice, Action, Event  
   ,@recipientId uniqueidentifier  
   ,@senderId uniqueidentifier = '00000000-0000-0000-0000-000000000000'  
   ,@emailId uniqueidentifier = '00000000-0000-0000-0000-000000000000'  
   ,@subject varchar(200)=''  
   ,@body varchar(MAX)=''  
   ,@dateAdded smalldatetime = null  
   ,@dateRead smalldatetime = null  
   ,@dateRemind smalldatetime = null  
   ,@triggerId uniqueidentifier  
   ,@flagType varchar(10)='flagGray'  
   ,@notificationValues varchar(MAX)=''
   -- 1/9/2019 Added new parameter to insert recordid,moduleRoute and moduleid
   ,@recordId CHAR(100) = null
   ,@moduleId int = 0
   ,@moduleRoute varchar(100) =''
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
   
 IF @dateAdded IS NULL SET @dateAdded=GETDATE()  
  
    -- Insert statements for procedure here  
 INSERT INTO [dbo].wmTriggerNotification  
           ([noticeType]  
           ,[recipientId]  
           ,[senderId]  
           ,[emailId]  
           ,[subject]  
           ,[body]  
           ,[dateAdded]  
           ,[dateRead]  
           ,[dateRemind]  
           ,[triggerId]  
           ,[notificationValues]
		   ,[RecordId]
		   ,[ModuleId]
		   ,[ModuleRoute])  
   -- 1/9/2019 Added new parameter to insert recordid,moduleRoute and moduleid

     VALUES  
           (@noticeType  
           ,@recipientId  
           ,@senderId  
           ,@emailId  
           ,@subject  
           ,@body  
           ,@dateAdded  
           ,@dateRead  
           ,@dateRemind  
           ,@triggerId  
           ,@notificationValues
		   ,@recordId,
		   @moduleId
		   ,@moduleRoute)  
   -- 1/9/2019 Added new parameter to insert recordid,moduleRoute and moduleid
END