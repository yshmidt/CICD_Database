-- =============================================          
-- Author:  David Sharp          
-- Create date: 4/18/2012          
-- Description: update import detail row          
--    03/10/15 DS Added make buy field to the options.          
--    09/02/15 DS Removed the part_source value from the selected part. It wasn't needed.          
-- Modified: 01/08/2017: Vijay G: To update the value of Use Customer Prefix value          
-- 03/27/2018: Vijay G: Passed the rowId parameter to SP importBOMVldtnCheckValues to update record using rowId          
-- 10/15/18 YS part_no is 35 characters not 23          
-- 12/12/2018 Sachin B Add fkImportId in And Condition and LTRIM and RTRIM        
-- 01/26/2019 Sachin B Fix the Issue While Adding Manual Item All Ffields are become green and Add Parameter @AddRow bit =0 for Fix      
-- 01/30/2019 Sachin B Fix the Customer Prefix Update Issue      
-- 05/15/2019 Vijay G Added two parameter as sid and serial to save updated records     
-- 06/07/2019 Vijay G Insert SID ,Serial Data for the Existing templates    
-- 01/16/2020 Vijay G Replace name of columns/variable sid with mtc   
-- 01/04/2021 Sachin B Add Location Parameter in SP for the Update Location  
-- importBOMRowUpdate 'b7b3a04b-6858-4f0b-a735-50fcb3e7c6cd','22410d13-122e-e911-b7c5-c91fb2497b65',1,'Y','BUY','null','CAP-SMT','1005','2','323-502','','CAPACITOR, 0.3pF, ±0.1pF, Hi Q, 01005,MUR','EACH','SJSTKM','0','STAG','GJM0225C1CR30WB01D','1','','','BPPIYH7LHD','1','0','0','1'      
-- =============================================          
CREATE PROCEDURE [dbo].[importBOMRowUpdate]          
 -- Add the parameters for the stored procedure here          
 @importId uniqueidentifier,@rowId uniqueidentifier,@itemno varchar(4),@used varchar(1),@partSource varchar(10),@make_buy varchar(1),@partClass varchar(10),@partType varchar(10),          
 --10/15/18 YS part_no is 35 characters not 23          
 @qty varchar(10),@custPartNo varchar(35),@crev varchar(8),@descript varchar(45),@u_of_m varchar(10),@warehouse varchar(10),@standardCost varchar(10),          
--10/15/18 YS part_no is 35 characters not 23          
 @wc varchar(10),@partno varchar(35),@rev varchar(8),@uniq_key varchar(10)='',@bomNote varchar(MAX),@invNote varchar(MAX),@useCustPFX bit       
 -- 01/26/2019 Sachin B Fix the Issue While Adding Manual Item All Ffields are become green and Add Parameter @AddRow bit =0 for Fix      
 ,@AddRow bit =0       
 -- 05/15/2019 Vijay G Added two parameter as sid and serial to save updated records 
 -- 01/04/2021 Sachin B Add Location Parameter in SP for the Update Location       
 ,@sid bit = 0, @serial bit = 0,@location varchar(200) = ''       
AS          
BEGIN          
 -- SET NOCOUNT ON added to prevent extra result sets from           
 -- interfering with SELECT statements.          
 SET NOCOUNT ON;          
          
    -- Insert statements for procedure here          
    DECLARE @itemId uniqueidentifier,@usedId uniqueidentifier,@sourceId uniqueidentifier,@make_buyId uniqueidentifier,@classId uniqueidentifier,@typeId uniqueidentifier,@qtyId uniqueidentifier,          
   @cPartId uniqueidentifier,@cRevId uniqueidentifier,@descId uniqueidentifier,@uomId uniqueidentifier,@warehouseId uniqueidentifier,          
   @stdCstId uniqueidentifier,@wcId uniqueidentifier,@pnId uniqueidentifier,@revId uniqueidentifier,@bnNote uniqueidentifier,@inNote uniqueidentifier,@sidFid uniqueidentifier,
   @serialFid uniqueidentifier,@locationFid UNIQUEIDENTIFIER          
           
 DECLARE @white varchar(10)='i00white',@lock varchar(10)='i00lock',@green varchar(10)='i01green',@fade varchar(10)='i02fade',          
   @none varchar(10)='00none',@sys varchar(10)='01system',@user varchar(10)='03user'          
      
 --Get ID values for each field type           
 SELECT @itemId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'itemno'          
 SELECT @usedId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'used'          
 SELECT @sourceId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'partSource'          
 SELECT @make_buyId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'make_buy'          
 SELECT @classId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'partClass'          
 SELECT @typeId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'partType'          
 SELECT @qtyId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'qty'          
 SELECT @cPartId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'custPartNo'          
SELECT @cRevId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'crev'          
 SELECT @descId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'descript'          
 SELECT @uomId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'u_of_m'          
 SELECT @warehouseId=fieldDefId FROM importBOMFieldDefinitions WHERE fieldName = 'warehouse'          
 SELECT @stdCstId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'standardCost'          
 SELECT @wcId=fieldDefId  FROM importBOMFieldDefinitions  WHERE fieldName = 'workCenter'          
 SELECT @pnId=fieldDefId  FROM importBOMFieldDefinitions  WHERE fieldName = 'partNo'          
 SELECT @revId=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'rev'          
 SELECT @bnNote=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'bomNote'          
 SELECT @inNote=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'invNote'          
 -- 05/15/2019 Vijay G Added two parameter as sid and serial to save updated records          
 --01/16/2020 Vijay G Replace name of columns/variable sid with mtc          
 SELECT @sidFid=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'mtc'          
 SELECT @serialFid=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'serial'      
 -- 01/04/2021 Sachin B Add Location Parameter in SP for the Update Location  
 SELECT @locationFid=fieldDefId FROM importBOMFieldDefinitions  WHERE fieldName = 'location'    
           
 --If the uniq_key was passed, lock all protected cells, otherwise unlock them          
 IF @uniq_key <> ''          
 BEGIN          
  UPDATE importBOMFields          
   SET lock = 1, [status]=@lock,[validation]=@sys,[message]='Set by existing internal part number'          
   WHERE fkImportId=@importId AND rowId=@rowId AND fkFieldDefId IN (SELECT fieldDefId FROM importBOMFieldDefinitions WHERE existLock = 1)          
  -- 09/02/15 DS Removed the part_source value from the selected part. It wasn't needed.          
  SELECT @partClass=PART_CLASS,@partType=PART_TYPE,@descript=DESCRIPT,@u_of_m=U_OF_MEAS FROM [dbo].[INVENTOR] WHERE UNIQ_KEY = @uniq_key          
 END          
 ELSE          
  UPDATE importBOMFields          
   SET lock = 0, [status]=@fade,[validation]=@none,[message]=''          
   WHERE fkImportId=@importId AND rowId=@rowId AND fkFieldDefId IN (SELECT fieldDefId FROM importBOMFieldDefinitions WHERE existLock = 1)          
             
 --Update fields with new values          
 -- Clean the make_buy item          
 SET @make_buy = CASE WHEN @make_buy='T' OR @make_buy='1' OR @make_buy='Y' THEN '1' ELSE '0' END          
         
 -- 12/12/2018 Sachin B Add fkImportId in And Condition and LTRIM and RTRIM       
 -- 01/26/2019 Sachin B Fix the Issue While Adding Manual Item All Ffields are become green and Add Parameter @AddRow bit =0 for Fix        
 UPDATE importBOMFields SET adjusted = @itemno,original = CASE WHEN @AddRow =1 THEN @itemno ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''        
 WHERE fkImportId=@importId AND fkFieldDefId = @itemId AND rowId = @rowId AND adjusted<>@itemno          
       
 UPDATE importBOMFields SET adjusted = @used,original = CASE WHEN @AddRow =1 THEN @used ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''         
 WHERE fkImportId=@importId AND  fkFieldDefId = @usedId AND rowId = @rowId AND adjusted<>@used          
      
 UPDATE importBOMFields SET adjusted = @partSource,original = CASE WHEN @AddRow =1 THEN @partSource ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''       
 WHERE fkImportId=@importId AND fkFieldDefId = @sourceId AND rowId = @rowId AND adjusted<>@partSource          
      
 UPDATE importBOMFields SET adjusted = @make_buy,original = CASE WHEN @AddRow =1 THEN @make_buy ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''       
 WHERE fkImportId=@importId AND fkFieldDefId = @make_buyId AND rowId = @rowId AND adjusted<>@make_buy       
          
 UPDATE importBOMFields SET adjusted = @partClass,original = CASE WHEN @AddRow =1 THEN @partClass ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''       
 WHERE fkImportId=@importId AND fkFieldDefId = @classId AND rowId = @rowId AND adjusted<>@partClass        
         
 UPDATE importBOMFields SET adjusted = @partType,original = CASE WHEN @AddRow =1 THEN @partType ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''        
 WHERE fkImportId=@importId AND fkFieldDefId = @typeId AND rowId = @rowId AND adjusted<>@partType          
      
 UPDATE importBOMFields SET adjusted = @qty,original = CASE WHEN @AddRow =1 THEN @qty ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''         
 WHERE fkImportId=@importId AND fkFieldDefId = @qtyId AND rowId = @rowId AND RTRIM(LTRIM(ISNULL(adjusted,'')))<>RTRIM(LTRIM(ISNULL(@qty,'')))          
      
 UPDATE importBOMFields SET adjusted = @custPartNo,original = CASE WHEN @AddRow =1 THEN @custPartNo ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''       
 WHERE fkImportId=@importId AND fkFieldDefId = @cPartId AND rowId = @rowId AND adjusted<>@custPartNo          
      
UPDATE importBOMFields SET adjusted = @crev,original = CASE WHEN @AddRow =1 THEN @crev ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
[validation]=@user,[message]=''         
WHERE fkImportId=@importId AND fkFieldDefId = @cRevId AND rowId = @rowId AND adjusted<>@crev         
        
UPDATE importBOMFields SET adjusted = LTRIM(@descript),original = CASE WHEN @AddRow =1 THEN LTRIM(@descript) ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
[validation]=@user,[message]=''       
WHERE fkImportId=@importId AND fkFieldDefId = @descId AND rowId = @rowId AND adjusted<>@descript          
      
UPDATE importBOMFields SET adjusted = @u_of_m,original = CASE WHEN @AddRow =1 THEN @u_of_m ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
[validation]=@user,[message]=''       
WHERE fkImportId=@importId AND fkFieldDefId = @uomId AND rowId = @rowId AND RTRIM(LTRIM(ISNULL(adjusted,'')))<>RTRIM(LTRIM(ISNULL(@u_of_m,'')))       
           
UPDATE importBOMFields SET adjusted = @warehouse,original = CASE WHEN @AddRow =1 THEN @warehouse ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
[validation]=@user,[message]=''       
WHERE fkImportId=@importId AND fkFieldDefId = @warehouseId AND rowId = @rowId AND adjusted<>@warehouse        
        
UPDATE importBOMFields SET adjusted = @standardCost,original = CASE WHEN @AddRow =1 THEN @standardCost ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
[validation]=@user,[message]=''       
WHERE fkImportId=@importId AND fkFieldDefId = @stdCstId AND rowId = @rowId AND RTRIM(LTRIM(ISNULL(adjusted,'')))<>RTRIM(LTRIM(ISNULL(@standardCost,'')))        
        
UPDATE importBOMFields SET adjusted = @wc,original = CASE WHEN @AddRow =1 THEN @wc ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
[validation]=@user,[message]=''         
WHERE fkImportId=@importId AND fkFieldDefId = @wcId AND rowId = @rowId AND adjusted<>@wc         
        
UPDATE importBOMFields SET adjusted = @bomNote,original = CASE WHEN @AddRow =1 THEN @bomNote ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
[validation]=@user,[message]=''        
WHERE fkImportId=@importId AND fkFieldDefId = @bnNote AND rowId = @rowId AND adjusted<>@bomNote         
        
UPDATE importBOMFields SET adjusted = @invNote,original = CASE WHEN @AddRow =1 THEN @invNote ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
[validation]=@user,[message]=''        
WHERE fkImportId=@importId AND fkFieldDefId = @inNote AND rowId = @rowId AND adjusted<>@invNote     
    
DECLARE @UniqKeyData CHAR(10)= (SELECT TOP 1 uniq_key FROM  importBOMFields WHERE fkImportId=@importId AND rowId = @rowId)       
         
-- 05/15/2019 Vijay G Added two parameter as sid and serial to save updated records      
-- 06/07/2019 Vijay G Insert SID ,Serial Data for the Existing templates    
IF EXISTS(SELECT * from importBOMFields WHERE fkImportId=@importId AND fkFieldDefId = @sidFid AND rowId = @rowId)    
 BEGIN    
  UPDATE importBOMFields SET adjusted = @sid,original = CASE WHEN @AddRow =1 THEN @sid ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
  [validation]=@user,[message]=''        
  WHERE fkImportId=@importId AND fkFieldDefId = @sidFid AND rowId = @rowId      
 END     
ELSE     
    BEGIN    
   INSERT INTO importBOMFields(detailId,fkImportId,rowId,fkFieldDefId,uniq_key,lock,original,adjusted,[status],[validation],[message],UseCustPFX)    
   VALUES(NEWID(),@importId,@rowId,@sidFid,@UniqKeyData,0,@sid,@sid,'i02fade','00none','',0)    
 END    
      
      
-- 05/15/2019 Vijay G Added two parameter as sid and serial to save updated records     
-- 06/07/2019 Vijay G Insert SID ,Serial Data for the Existing templates     
IF EXISTS(SELECT * from importBOMFields WHERE fkImportId=@importId AND fkFieldDefId = @serialFid AND rowId = @rowId)    
	BEGIN    
		UPDATE importBOMFields SET adjusted = @serial,original = CASE WHEN @AddRow =1 THEN @serial ELSE original END,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
		[validation]=@user,[message]=''        
		WHERE fkImportId=@importId AND fkFieldDefId = @serialFid AND rowId = @rowId       
	END    
ELSE    
	BEGIN    
		INSERT INTO importBOMFields(detailId,fkImportId,rowId,fkFieldDefId,uniq_key,lock,original,adjusted,[status],[validation],[message],UseCustPFX)    
		VALUES(NEWID(),@importId,@rowId,@serialFid,@UniqKeyData,0,@serial,@serial,'i02fade','00none','',0)    
	END   
-- 01/04/2021 Sachin B Add Location Parameter in SP for the Update Location  	
IF EXISTS(SELECT * from importBOMFields WHERE fkImportId=@importId AND fkFieldDefId = @locationFid AND rowId = @rowId)    
	BEGIN    
		UPDATE importBOMFields SET adjusted = @location,
		original = CASE WHEN @AddRow =1 THEN @location ELSE original END,
		[status] = CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
		[validation]=@user,[message]=''        
		WHERE fkImportId=@importId AND fkFieldDefId = @locationFid AND rowId = @rowId       
	END    
ELSE    
	BEGIN    
		INSERT INTO importBOMFields(detailId,fkImportId,rowId,fkFieldDefId,uniq_key,lock,original,adjusted,[status],[validation],[message],UseCustPFX)    
		VALUES(NEWID(),@importId,@rowId,@locationFid,@UniqKeyData,0,@location,@location,'i02fade','00none','',0)    
	END 	 
      
--01/08/2017: Vijay G: To update the value of Use Customer Prefix value        
-- 01/30/2019 Sachin B Fix the Customer Prefix Update Issue       
UPDATE importBOMFields SET UseCustPFX = @useCustPFX      
WHERE fkImportId = @importId AND rowId = @rowId AND UseCustPFX<>@useCustPFX          
           
 DECLARE @tempUniq varchar(10)          
 SELECt @tempUniq = uniq_key FROM importBOMFields WHERE fkFieldDefId=@pnId AND rowId=@rowId          
 IF @tempUniq<>@uniq_key          
 BEGIN          
  -- 12/12/2018 Sachin B Add fkImportId in And Condition and LTRIM and RTRIM        
  UPDATE importBOMFields SET adjusted = @partno,original = CASE WHEN @AddRow =1 THEN @partno ELSE original END, uniq_key=@uniq_key,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
  [validation]=@user,[message]=''       
  WHERE fkImportId=@importId AND fkFieldDefId = @pnId AND rowId = @rowId       
           
 UPDATE importBOMFields SET adjusted = @rev,original = CASE WHEN @AddRow =1 THEN @rev ELSE original END, uniq_key=@uniq_key,[status]=CASE WHEN @AddRow =0 THEN @green ELSE '' END,      
 [validation]=@user,[message]=''       
 WHERE fkImportId=@importId AND fkFieldDefId = @revId AND rowId = @rowId         
        
 END          
 ELSE          
 BEGIN          
  UPDATE importBOMFields SET adjusted = @partno, uniq_key=@uniq_key WHERE fkFieldDefId = @pnId AND rowId = @rowId          
  UPDATE importBOMFields SET adjusted = @rev, uniq_key=@uniq_key  WHERE fkFieldDefId = @revId AND rowId = @rowId          
 END          
             
 UPDATE importBOMFields SET uniq_key=@uniq_key WHERE rowId=@rowId AND fkImportId=@importId          
 -- 03/27/2018: Vijay G: Passed the rowId parameter to SP importBOMVldtnCheckValues to update record using rowId          
 EXEC importBOMVldtnCheckValues @importId,@rowId          
END 