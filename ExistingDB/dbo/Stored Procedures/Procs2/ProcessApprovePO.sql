-- =============================================  
-- Author:Satish B  
-- Create date: 08/23/2018  
-- Description : Get approve request list  
-- Modified : 12/1/2018 : Satish B : Insert isDeleted = 0 in WFRequest table  
-- Modified : 01/03/2019 : Satish B : Remove unneccesory block and make it common and add only one entry in WFrequest for each request  
-- Modified : 05/06/2019 : Satish B : Add extra output parameter @noSetup  
-- Modified : 05/20/2019 : Satish B : Added filters to send approver request base on condition  
-- Modified : 05/22/2019 : Satish B : Set approver date as current date not POdate  
-- Modified : 06/12/2019 : Satish B : Remove filter @isAll = 1  
-- Modified : 11/14/2019 : Shiv P : Insert the value in IsCancel column of WfRequest  
-- Modified : 05/08/2020 : Shiv P : Add condition <= and >= for the boundary value amount 
-- =============================================  
CREATE PROCEDURE ProcessApprovePO  
  @poNum char(15) = null  
  ,@wfRequesterId uniqueidentifier=null  
  ,@noSetup BIT OUTPUT  
 AS  
 BEGIN  
  SET NOCOUNT ON   
  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 SET NOCOUNT ON;  
 DECLARE @totalAmount numeric(11,2)  
  ,@poDate DATETIME  
  ,@wfHeaderId char(10)  
  ,@lnTotalCount int  
  ,@lnCnt int  
  ,@metaDataName char(25)  
  ,@groupUserIdCount int  
  ,@groupUserIdCnt int  
  ,@startValue numeric(11,2)  
  ,@endValue numeric(11,2)  
  ,@operatorType char(20)  
  ,@wfConfigId char(10)  
  ,@wfRequestId char(10)  
  ,@isGroup bit   
  ,@isAll bit   
  ,@approverGid uniqueidentifier  
  ,@approverUid uniqueidentifier  
  --,@wfRequesterId uniqueidentifier  
  ,@moduleId char(10)  
  ,@isRecordExist bit = 0  
  ,@count int  
  
 DECLARE @tInserted TABLE(wfConfigId char(10),approverGid uniqueidentifier, configName char(100), metaDataId char(10),    
        operatorType char(20), startValue numeric(12,2), endValue numeric(12,2),  isAll bit,   
        wfid char(10), stepNumber int, isGroup bit,operator char(20),nId Int IDENTITY(1,1))  
  
 DECLARE @groupUserIds Table(fkuserid uniqueidentifier,rowId Int IDENTITY(1,1))  
  
    -- Insert statements for trigger here  
    BEGIN TRANSACTION  
  BEGIN      
      -- Get module id  
   SELECT @moduleId=moduleid FROM MnxModule WHERE ModuleName ='PO'  
   -- Total sum of po quantity   
   SELECT @totalAmount = POTOTAL,@poDate=PODATE FROM POMAIN WHERE PONUM= @poNum    
   -- Get Workflow header details  
   SELECT @wfHeaderId = WFid FROM WFHeader WHERE ModuleId=@moduleId  
   --Get requestor id  
   -- Get the metadataname  
   SELECT @metaDataName = MetaDataName FROM MnxWFMetaData WHERE ModuleId=@moduleId  
     
   INSERT @tInserted   
    SELECT wfConfigId,approverid, configName , metaDataId,operatorType, startValue, endValue,isAll,  
     wfid , stepNumber, isGroup,  
     REPLACE(LTRIM(RTRIM(operatorType)),LTRIM(RTRIM(@metaDataName)),'') AS operator  
    FROM WFConfig  
    WHERE WFConfig.WFid = @wfHeaderId   
-- 05/20/2019 : Satish B : Added filters to send approver request base on condition  
    AND (((OPERATORTYPE = 'GREATER THAN' AND ENDVALUE < @totalAmount))  
	-- Modified : 05/08/2020 : Shiv P : Add condition <= and >= for the boundary value amount   
    OR ((OPERATORTYPE ='BETWEEN') AND (StartValue <= @totalAmount AND EndValue >= @totalAmount))    
    OR (OPERATORTYPE ='N/A')    
    OR(OPERATORTYPE ='LESS THAN' AND EndValue > @totalAmount))   
    ORDER BY StepNumber  
    SET @lnTotalCount = @@ROWCOUNT;  
    SET @lnCnt = 0  
      --Satish B : Remove unneccesory block and make it common and add only one entry in WFrequest for each request  
   -- Check weather the record is exist or not(usefull when rejected at originator)  
   IF EXISTS(SELECT RecordId FROM WFRequest WHERE RecordId=@poNum)  
    BEGIN  
     DELETE FROM WFInstance WHERE WFRequestId IN (SELECT WFRequestId FROM WFRequest WHERE RecordId=@poNum)  
     DELETE FROM WFRequest WHERE RecordId=@poNum  
    END  
     
   SET @wfRequestId = dbo.fn_GenerateUniqueNumber()  
     
   -- Modified : 11/14/2019 : Shiv P : Insert the value in IsCancel column of WfRequest  
     INSERT INTO WFRequest(ModuleId,RecordId,RequestDate,WFComplete,WFRequestId,  
     RequestorId,IsDeleted,IsCancel)  
     VALUES(@moduleId, @poNum,GETDATE(),'',@wfRequestId,@wfRequesterId,0 ,CASE WHEN EXISTS(SELECT 1 FROM POITEMS WHERE LCANCEL=0 AND PONUM=@poNum) THEN 0 ELSE 1 END)   
  
-- 05/22/2019 : Satish B : Set approver date as current date not POdate  
      
   BEGIN  
    IF @lnTotalCount <> 0    
    BEGIN  
  SET @noSetup = 0   
     WHILE @lnTotalCount > @lnCnt  
      BEGIN  
       SET @lnCnt = @lnCnt + 1   
       SELECT @startValue = startValue , @endValue=endValue, @operatorType = LTRIM(RTRIM(operator)),@wfConfigId = wfConfigId  
       ,@isGroup =isGroup , @isAll = isAll,@approverGid =approverGid FROM @tInserted WHERE nId = @lnCnt;  
  
          BEGIN   
--  06/12/2019 : Satish B : Remove filter @isAll = 1             
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
    ELSE  
     SET @noSetup=1  
   END  
  END  
 COMMIT  
END 