/*Please verify the procedure before run*/
  
-- =============================================    
-- Author:  Aloha  
-- Create date: 06/21/2013    
-- Description: Get the email details by message id.  
-- =============================================    
CREATE PROCEDURE [dbo].[MnxTriggerEmailsGet] 
 @messageid uniqueidentifier 
AS    
BEGIN    
 SET NOCOUNT ON;    
  
--SET @messageid=CAST(@messageid AS UNIQUEIDENTIFIER)  
SELECT [messageid]  
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
      ,[dateSent]  
      ,[dateFirstOpened]  
      ,[note]  
      ,[hasError]  
      ,[errorCode]  
      ,[errorMessage]  
      ,[deleteOnSend]  
  FROM [wmTriggerEmails]  
  WHERE [messageid]=@messageid   
    
  END 