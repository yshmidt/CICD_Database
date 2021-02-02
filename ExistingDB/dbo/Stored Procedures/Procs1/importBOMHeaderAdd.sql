-- =============================================  
-- Author:  David Sharp  
-- Create date: 4/18/2012  
-- Description: add import Header  
-- 09/17/15 DS changed @assyRev size to 8  
--04/06/18 YS changed assyno size to char(35) 
-- 05/21/2019 Vijay G : change type of @startedBy and  @completedBy column to insert userid value in this column
-- =============================================  
CREATE PROCEDURE [dbo].[importBOMHeaderAdd]   
 -- Add the parameters for the stored procedure here  
 -- 05/21/2019 Vijay G : change type of @startedBy and  @completedBy column to insert userid value in this column
 @importId uniqueidentifier,@startedBy uniqueidentifier, @partSource varchar(10)='MAKE', @status varchar(10)='NEW',  
 @completeDate smalldatetime='',@completedBy uniqueidentifier =null,@custNo varchar(10)='',  
 --04/06/18 YS changed assyno size to char(35)  
 @assyNo varchar(35)='',@assyRev varchar(8)='',@assyDesc varchar(45)='',  
 @partClass varchar(8)='',@partType varchar(8)='',@uniq_key varchar(10) = '',@message varchar(MAX)=''  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 --IF (@custNo = '' OR @custNo IS NULL) SET @custNo = '000000000~'  
 --IF (@assyNo = '' OR @assyNo IS NULL) SET @assyNo = ''  
 --IF (@assyRev = '' OR @assyRev IS NULL) SET @assyRev = ''  
 --IF (@assyDesc = '' OR @assyDesc IS NULL) SET @assyDesc = ''  
   
    -- Insert statements for procedure here  
 INSERT INTO [dbo].[importBOMHeader]  
           ([importId]  
           ,[startDate]  
           ,[startedBy]  
           ,[source]  
           ,[status]  
           ,[completeDate]  
           ,[completedBy]  
           ,[custNo]  
           ,[assyNum]  
           ,[assyRev]  
           ,[assyDesc]  
           ,[partClass]  
           ,[partType]  
           ,[uniq_key]  
           ,[message])  
  VALUES  
           (@importId  
           ,GETDATE()  
           ,@startedBy  
           ,@partSource  
           ,@status  
           ,@completeDate  
           ,@completedBy  
           ,COALESCE(@custNo,'')  
           ,COALESCE(@assyNo,'')  
           ,COALESCE(@assyRev,'')  
           ,COALESCE(@assyDesc,'')  
           ,@partClass  
           ,@partType  
           ,@uniq_key  
           ,@message)  
END