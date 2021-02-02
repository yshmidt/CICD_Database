-- =============================================  
-- Author:  David Sharp  
-- Create date: 10/29/2012  
-- Description: get a user new message count  
-- 01/07/14 SL: modified to get the next 6 records.
-- 1/23/17 Raviraj P :modified to get the next 14 records with new MX UI.
-- =============================================  
CREATE PROCEDURE [dbo].[MnxTriggerNotificationTopGet]  
 -- Add the parameters for the stored procedure here  
 @recipientId uniqueidentifier,  
 @fromMessageCount int = 1  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 DECLARE @root varchar(MAX)  
 DECLARE @moreAvailable bit = 0  
 DECLARE @itemsAvailable int
 SELECT @root=CUSTOMROOTURL FROM GENERALSETUP  
    -- Insert statements for procedure here  
 --SELECT TOP (@count) tm.*, COALESCE(u.UserName,'')SenderName, ta.bodyTemplate,ta.subjectTemplate,ta.summaryTemplate,tm.notificationValues,@root rootUrl  
 -- FROM wmTriggerNotification tm LEFT OUTER JOIN aspnet_Users u ON tm.senderId=u.UserId    
 --  LEFT OUTER JOIN MnxTriggersAction ta ON tm.triggerId=ta.actTriggerId  
 -- WHERE recipientId=@recipientId AND (dateRemind IS NULL OR dateRemind<=GETDATE()) ORDER BY dateAdded DESC

 
   ;With tempTable as (
   SELECT  ROW_NUMBER() OVER(ORDER BY dateadded DESC) AS RowNumber,COUNT(*) OVER () AS TotalRows, tm.*, COALESCE(u.UserName,'')SenderName, ta.bodyTemplate,ta.subjectTemplate,ta.summaryTemplate,@root rootUrl  
  FROM wmTriggerNotification tm LEFT OUTER JOIN aspnet_Users u ON tm.senderId=u.UserId    
  LEFT OUTER JOIN MnxTriggersAction ta ON tm.triggerId=ta.actTriggerId  
  WHERE recipientId=@recipientId AND (dateRemind IS NULL OR dateRemind<=GETDATE()))
  
  
  select * FROM tempTable WHERE RowNumber BETWEEN @fromMessageCount AND @fromMessageCount+ 14 -- 1/23/17 Raviraj P :modified to get the next 14 records with new MX UI.
  
END 