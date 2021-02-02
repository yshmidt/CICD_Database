  
-- =============================================    
-- Author:Vijay G   
-- Create date: 07/10/2019  
--12/20/2019 Modified Vijay G Change the module id while requesting 
-- =============================================    
CREATE PROCEDURE [dbo].[ECOProcessApprove]    
  @ecoNum char(20) = null    
  ,@wfRequesterId uniqueidentifier=null    
 AS    
 BEGIN    
  SET NOCOUNT ON     
 -- SET NOCOUNT ON added to prevent extra result sets from    
 SET NOCOUNT ON;    
 DECLARE @totalAmount numeric(11,2)    
  ,@wfHeaderId char(10)    
  ,@lnTotalCount int    
  ,@lnCnt int    
  ,@metaDataName char(25)    
  ,@groupUserIdCount int    
  ,@groupUserIdCnt int    
  ,@wfConfigId char(10)    
  ,@wfRequestId char(10)    
  ,@isGroup bit     
  ,@isAll bit     
  ,@approverGid uniqueidentifier      
  ,@moduleId char(10)    
    
 DECLARE @tInserted TABLE(wfConfigId char(10),approverGid uniqueidentifier, configName char(100), metaDataId char(10), isAll bit,     
        wfid char(10), stepNumber int, isGroup bit,operator char(20),nId Int IDENTITY(1,1))    
    
 DECLARE @groupUserIds Table(fkuserid uniqueidentifier,rowId Int IDENTITY(1,1))    
    
    -- Insert statements for trigger here    
    BEGIN TRANSACTION    
  BEGIN        
      -- Get module id  
   --12/20/2019 Modified Vijay G Change the module id while requesting   
   SELECT @moduleId=moduleid FROM MnxModule WHERE ModuleName ='Engineering Change & Deviation Control (ECO)'     
   -- Get Workflow header details    
   SELECT @wfHeaderId = WFid FROM WFHeader WHERE ModuleId=@moduleId    
   --Get requestor id    
   -- Get the metadataname    
   SELECT @metaDataName = MetaDataName FROM MnxWFMetaData WHERE ModuleId=@moduleId    
 INSERT @tInserted     
    SELECT wfConfigId,approverid, configName , metaDataId,isAll,    
     wfid , stepNumber, isGroup,    
     REPLACE(LTRIM(RTRIM(operatorType)),LTRIM(RTRIM(@metaDataName)),'') AS operator    
    FROM WFConfig    
    WHERE WFConfig.WFid = @wfHeaderId     
    ORDER BY StepNumber    
    SET @lnTotalCount = @@ROWCOUNT;    
    SET @lnCnt = 0    
      --Satish B : Remove unneccesory block and make it common and add only one entry in WFrequest for each request    
   -- Check weather the record is exist or not(usefull when rejected at originator)    
   IF EXISTS(SELECT RecordId FROM WFRequest WHERE RecordId=@ecoNum)    
    BEGIN    
     DELETE FROM WFInstance WHERE WFRequestId IN (SELECT WFRequestId FROM WFRequest WHERE RecordId=@ecoNum)    
     DELETE FROM WFRequest WHERE RecordId=@ecoNum    
    END    
       
   SET @wfRequestId = dbo.fn_GenerateUniqueNumber()    
    
   INSERT INTO WFRequest(ModuleId,RecordId,RequestDate,WFComplete,WFRequestId,    
   RequestorId,IsDeleted)    
-- 05/22/2019 : Satish B : Set approver date as current date not POdate    
   VALUES(@moduleId, @ecoNum,GETDATE(),'',@wfRequestId,@wfRequesterId,0)      
   BEGIN    
     WHILE @lnTotalCount > @lnCnt    
      BEGIN    
       SET @lnCnt = @lnCnt + 1     
       SELECT @wfConfigId = wfConfigId ,@isGroup =isGroup , @isAll = isAll,@approverGid =approverGid FROM @tInserted WHERE nId = @lnCnt;    
          BEGIN                  
    IF @isGroup = 1       
             BEGIN    
             --select * from aspmnx_groupUsers    
              SET NOCOUNT ON;    
              INSERT @groupUserIds    
              SELECT fkuserid FROM aspmnx_groupUsers WHERE fkgroupid = @approverGid;    
              SET @groupUserIdCount = @@ROWCOUNT;    
              SET @groupUserIdCnt = 0;    
              IF @groupUserIdCount <> 0      
               BEGIN    
               WHILE @groupUserIdCount> @groupUserIdCnt    
                BEGIN    
                  SET @groupUserIdCnt = @groupUserIdCnt + 1;    
                  INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId,Approver,WFConfigId)    
                  VALUES('',0, dbo.fn_GenerateUniqueNumber(), @wfRequestId,    
                  (SELECT fkuserid FROM @groupUserIds WHERE rowId = @groupUserIdCnt),@wfConfigId)    
                END    
              END    
             END    
            ELSE     
             BEGIN     
              INSERT INTO WFInstance(Comments,IsApproved,WFInstanceId,WFRequestId,WFConfigId,Approver)    
              VALUES('',0, dbo.fn_GenerateUniqueNumber(),@wfRequestId,@wfConfigId,@approverGid)    
             END    
          END      
    END     
    END     
  END    
 COMMIT    
END 