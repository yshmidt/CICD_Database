-- =============================================  
-- Author:  Satish B  
-- Create date: 03/04/2019  
-- Description: Update PO Upload schedule detail 
-- Modified  10/14/2020 Shiv P : Change @schdQty parameter datatype to numeric(10,2)  
-- =============================================  
CREATE PROCEDURE [dbo].[ImportPOScheduleInsert]  
 -- Add the parameters for the stored procedure here  
   @importId uniqueidentifier,@rowId uniqueidentifier,@scheduleRowId uniqueidentifier,@moduleId varchar(10),
    @uniqDetNo varchar(10),@schdDate date=NULL ,@origCommit date=NULL,@prjNumber varchar(10)  
	-- Modified  10/14/2020 Shiv P : Change @schdQty parameter datatype to numeric(10,2) 
   ,@schdQty numeric(10,2),@warehouse varchar(6),@location varchar(200),@requesttp varchar(40),@requestor varchar(40),@glnbr varchar(13)  
  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    DECLARE   
   @schdDateId uniqueidentifier,@reqDateId uniqueidentifier,@origCommitId uniqueidentifier,@schdQtyId uniqueidentifier,@locationId uniqueidentifier,  
   @requesttpId uniqueidentifier,@requestorId uniqueidentifier,@glnbrId uniqueidentifier,@warehouseId uniqueidentifier,@prjNumberId uniqueidentifier  
   
 DECLARE @white varchar(10)='i00white',@lock varchar(10)='i00lock',@green varchar(10)='i01green',@fade varchar(10)='i02fade',  
   @none varchar(10)='00none',@sys varchar(10)='01system',@user varchar(10)='03user'  
   
 --Get ID values for each field type   
 SELECT @schdDateId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'SCHDDATE' AND ModuleId=@moduleId    
 SELECT @reqDateId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'REQDATE'  AND ModuleId=@moduleId    
 SELECT @origCommitId =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'ORIGCOMMITDT'AND ModuleId=@moduleId    
 SELECT @schdQtyId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'SCHDQTY'  AND ModuleId=@moduleId    
 SELECT @warehouseId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'WAREHOUSE' AND ModuleId=@moduleId    
 SELECT @locationId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'LOCATION' AND ModuleId=@moduleId    
 SELECT @prjNumberId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'WOPRJNUMBER' AND ModuleId=@moduleId   
 SELECT @requesttpId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'REQUESTTP' AND ModuleId=@moduleId   
 SELECT @requestorId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'REQUESTOR' AND ModuleId=@moduleId    
 SELECT @glnbrId   =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'GLNBR'  AND ModuleId=@moduleId    
 select * from ImportPOSchedule  
 --Insert new field   
 INSERT INTO ImportPOSchedule (fkPOImportId,fkRowId,fkFieldDefId,ScheduleRowId,UniqDetNo,Original,Adjusted,Status,Validation,Message)   
 VALUES      (@importId,@rowId,@schdDateId,@scheduleRowId,@uniqDetNo, cast(@schdDate AS nvarchar(10)),cast(@schdDate AS nvarchar(10)),'','',''),  
        (@importId,@rowId,@origCommitId,@scheduleRowId,@uniqDetNo,cast(@origCommit AS nvarchar(10)),cast(@origCommit AS nvarchar(10)),'','',''),  
        (@importId,@rowId,@schdQtyId,@scheduleRowId,@uniqDetNo,CAST(@schdQty AS nvarchar(10)),CAST(@schdQty AS nvarchar(10)),'','',''),  
        (@importId,@rowId,@warehouseId,@scheduleRowId,@uniqDetNo,@warehouse,@warehouse,'','',''),  
        (@importId,@rowId,@locationId,@scheduleRowId,@uniqDetNo,@location,@location,'','',''),  
        (@importId,@rowId,@requesttpId,@scheduleRowId,@uniqDetNo,@requesttp,@requesttp,'','',''),  
        (@importId,@rowId,@requestorId,@scheduleRowId,@uniqDetNo,@requestor,@requestor,'','',''),  
        (@importId,@rowId,@prjNumberId,@scheduleRowId,@uniqDetNo,@prjNumber,@prjNumber,'','',''),  
        (@importId,@rowId,@glnbrId,@scheduleRowId,@uniqDetNo,@glnbr,@glnbr,'','','');  
   
 --Recheck Validations  
 EXEC ImportPOVldtnCheckValues @importId  
END  