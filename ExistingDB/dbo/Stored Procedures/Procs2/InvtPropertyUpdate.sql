-- =============================================        
-- Author:  Mahesh B.         
-- Create date: 03/13/2019         
-- Description: Update the all the work centers from production control       
--Modified Vijay G : 08/11/2019 Added field entry if user provide empty value in part number       
--Modified Vijay G : 08/11/2019 Added default entry of revision field      
--Modified Vijay G : 02/26/2020 Removed unwanted code because its incorrectly validate Revision field and added default entry of revision field if already not exits          
-- =============================================        
        
CREATE PROCEDURE [dbo].[InvtPropertyUpdate]        
(        
@p_invtUpdate dbo.BulkInvtUpdate READONLY        
)        
AS        
BEGIN         
SET NOCOUNT ON;         
Update ImportBulkInvtFields         
           SET Message = p.Message,        
           Status = p.Status        
       From  ImportBulkInvtFields i       
    INNER JOIN @p_invtUpdate p on  p.[RowId] = i.RowId and p.FieldDefId = i.FkFieldDefId        
      
      
--Modified Vijay G : 08/11/2019 Added field entry if user provide empty value in part number           
DECLARE @tblDetail Table([FieldDefId] [uniqueidentifier] NOT NULL,[InvtImportId] [uniqueidentifier] NOT NULL,[RowId] [uniqueidentifier] NOT NULL,      
                      [Value] [nvarchar](max) NULL,[Status] [varchar](50) NULL,[Message] [nvarchar](max) NULL)      
      
DECLARE @partFieldDefId uniqueidentifier ,@rowId uniqueidentifier, @fieldDefId uniqueidentifier,@fkInvtImportId uniqueidentifier ,@revFieldDefId uniqueidentifier     
SELECT @partFieldDefId=FieldDefId from ImportFieldDefinitions where FieldName='PART_NO' AND UploadType='BulkPartMasterPropertyUpdate'      
INSERT INTO @tblDetail ([FieldDefId],[InvtImportId] ,[RowId] ,[Value] ,[Status] ,[Message])       
SELECT [FieldDefId],[InvtImportId] ,[RowId] ,[Value] ,[Status] ,[Message] FROM  @p_invtUpdate WHERE FieldDefId=@partFieldDefId      
SELECT @revFieldDefId=FieldDefId from ImportFieldDefinitions where FieldName='REVISION' AND UploadType='BulkPartMasterPropertyUpdate'     
      
WHILE(EXISTS(SELECT 1 FROM @tblDetail) )      
BEGIN       
 SELECT TOP 1 @rowId =[RowId],@fieldDefId=FieldDefId,@fkInvtImportId=InvtImportId FROM @tblDetail      
 IF(NOT EXISTS(SELECT 1 FROM ImportBulkInvtFields imp INNER JOIN ImportFieldDefinitions i       
               ON imp.FkFieldDefId=i.FieldDefId WHERE imp.FkFieldDefId=@fieldDefId AND  imp.RowId=@rowId AND i.FieldName='PART_NO'))      
 BEGIN      
  INSERT INTO ImportBulkInvtFields(DetailId,FkFieldDefId,FkInvtImportId,RowId,Original,Adjusted,Status,Message,IsSysProperty)      
  VALUES(NEWID(),@fieldDefId,@fkInvtImportId,@rowId,'','','i05red','Part number required, please provide valid part number.',0)      
 END      
 --Modified Vijay G : 02/26/2020 Removed unwanted code because its incorrectly validate Revision field and added default entry of revision field if already not exits   
 IF(NOT EXISTS(SELECT 1 FROM ImportBulkInvtFields imp INNER JOIN ImportFieldDefinitions i       
               ON imp.FkFieldDefId=i.FieldDefId WHERE imp.FkFieldDefId=@revFieldDefId AND  imp.RowId=@rowId AND i.FieldName='REVISION'))      
 BEGIN      
  INSERT INTO ImportBulkInvtFields(DetailId,FkFieldDefId,FkInvtImportId,RowId,Original,Adjusted,Status,Message,IsSysProperty)      
  VALUES(NEWID(),@revFieldDefId,@fkInvtImportId,@rowId,'','','','',0)      
 END      
    DELETE FROM @tblDetail WHERE @rowId =[RowId] AND @fieldDefId=FieldDefId AND @fkInvtImportId=InvtImportId      
END      
    
    
----Modified Vijay G : 08/11/2019 Added default entry of revision field     
--DELETE FROM @tblDetail    
--SELECT @revFieldDefId=FieldDefId from ImportFieldDefinitions where FieldName='REVISION' AND UploadType='BulkPartMasterPropertyUpdate'     
    
--INSERT INTO @tblDetail ([FieldDefId],[InvtImportId] ,[RowId] ,[Value] ,[Status] ,[Message])       
--SELECT [FieldDefId],[InvtImportId] ,[RowId] ,[Value] ,[Status] ,[Message] FROM  @p_invtUpdate WHERE FieldDefId=@revFieldDefId      
      
--INSERT INTO ImportBulkInvtFields(DetailId,FkFieldDefId,FkInvtImportId,RowId,Original,Adjusted,Status,Message,IsSysProperty)      
--SELECT NEWID(),[FieldDefId],[InvtImportId] ,[RowId] ,'',[Value] ,[Status] ,[Message],0 FROM @tblDetail    
END      