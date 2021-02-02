
/*Please verify the procedure before run*/

-- =============================================  
-- Author:  Aloha
-- Create date: 06/21/2013  
-- Description: add a new email detail for a user  
-- 01/15/14 YS Added new column fktriggerID - link to mnxTriggersAction or wmTriggers
-- =============================================  
CREATE PROCEDURE [dbo].[MnxTriggerEmailsAdd]  
 -- Add the parameters for the stored procedure here  
  @messageid uniqueidentifier
   ,@toEmail varchar(MAX)
   ,@tocc varchar(MAX)  
   ,@tobcc varchar(MAX)   
   ,@fromEmail varchar(50)
   ,@fromPw varchar(50)
   ,@subject varchar(200)  
   ,@body varchar(MAX)  
   ,@attachments varchar(MAX)  
   ,@isHtml bit  
   ,@dateAdded smalldatetime = null
   ,@deleteOnSend bit  
   -- 01/15/14 added link to mnxTriggersAction or wmTriggers. Empty if not provided
   ,@fktriggerID varchar(50)=' '
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON; 

IF @dateAdded IS NULL SET @dateAdded=GETDATE()  

INSERT INTO [dbo].[wmTriggerEmails]
           ([messageid]
           ,[toEmail]
           ,[tocc]
           ,[tobcc]
           ,[fromEmail]
           ,[fromPw]
           ,[subject]
           ,[body]
           ,[attachments]
           ,[isHtml]
           ,[dateAdded]
           ,[deleteOnSend]
           ,[fktriggerID]
           )
     VALUES
           (@messageid
           ,@toEmail
           ,@tocc
           ,@tobcc
           ,@fromEmail
           ,@fromPw
           ,@subject
           ,@body
           ,@attachments
           ,@isHtml
           ,@dateAdded
           ,@deleteOnSend
           ,@fktriggerID 
           )
           
END  