-- =============================================
-- Author:		Satish B
-- Create date: 6/22/2018
-- Description:	Update PO Upload schedule detail
-- Modified  10/12/2020 Shiv P : Change @schdQty parameter datatype to numeric(10,2) 
-- =============================================
CREATE PROCEDURE [dbo].[ImportPOScheduleUpdate]  
	-- Add the parameters for the stored procedure here
    @importId uniqueidentifier,@rowId uniqueidentifier,@scheduleRowId uniqueidentifier,@moduleId varchar(10), 
	@uniqDetNo varchar(10),@schdDate date=NULL,@origCommit date=NULL,@prjNumber varchar(20) 
	-- Modified  10/12/2020 Shiv P : Change @schdQty parameter datatype to numeric(10,2)  
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
	
 DECLARE @user varchar(10)='03user'  
	
	--Get ID values for each field type	
	SELECT @schdDateId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'SCHDDATE'	AND ModuleId=@moduleId		
	SELECT @reqDateId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'REQDATE'		AND ModuleId=@moduleId		
	SELECT @origCommitId	=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'ORIGCOMMITDT'AND ModuleId=@moduleId		
	SELECT @schdQtyId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'SCHDQTY'		AND ModuleId=@moduleId		
	SELECT @warehouseId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'WAREHOUSE'	AND ModuleId=@moduleId		
	SELECT @locationId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'LOCATION'	AND ModuleId=@moduleId		
    SELECT @prjNumberId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'WOPRJNUMBER' AND ModuleId=@moduleId  
    SELECT @requesttpId  =fieldDefId  FROM ImportFieldDefinitions  WHERE fieldName = 'REQUESTTP' AND ModuleId=@moduleId   
	SELECT @requestorId		=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'REQUESTOR'	AND ModuleId=@moduleId		
	SELECT @glnbrId			=fieldDefId		FROM ImportFieldDefinitions		WHERE fieldName = 'GLNBR'		AND ModuleId=@moduleId		


	--Update fields with new values
	UPDATE ImportPOSchedule SET adjusted = cast(@schdDate AS nvarchar(10)),[status]='',[validation]=@user,[message]=''	 	WHERE fkFieldDefId = @schdDateId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId AND adjusted<>cast(@schdDate AS nvarchar(10))
	UPDATE ImportPOSchedule SET adjusted = cast(@origCommit AS nvarchar(10)),[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @origCommitId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId AND adjusted<>cast(@origCommit AS nvarchar(10)
)
	UPDATE ImportPOSchedule SET adjusted = cast(@schdQty AS nvarchar(10)),[status]='',[validation]=@user,[message]=''		WHERE fkFieldDefId = @schdQtyId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId AND adjusted<>cast(@schdQty AS nvarchar(10))
	UPDATE ImportPOSchedule SET adjusted = @warehouse,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @warehouseId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId AND adjusted<>@warehouse 
	UPDATE ImportPOSchedule SET adjusted = @location,[status]='',[validation]=@user,[message]=''	 	WHERE fkFieldDefId = @locationId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId AND adjusted<>@location
	UPDATE ImportPOSchedule SET adjusted = @prjNumber,[status]='',[validation]=@user,[message]=''	 		WHERE fkFieldDefId = @prjNumberId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId AND adjusted<>@prjNumber
    UPDATE ImportPOSchedule SET adjusted = @requesttp,[status]='',[validation]=@user,[message]='' WHERE fkFieldDefId = @requesttpId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId --AND adjusted<>@requesttp  
	UPDATE ImportPOSchedule SET adjusted = @requestor,[status]='',[validation]=@user,[message]=''	WHERE fkFieldDefId = @requestorId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId --AND adjusted<>@requestor
	UPDATE ImportPOSchedule SET adjusted = @glnbr,[status]='',[validation]=@user,[message]=''	 	WHERE fkFieldDefId = @glnbrId AND FkRowId = @rowId AND ScheduleRowId = @scheduleRowId AND adjusted<>@glnbr

	--Recheck Validations
	EXEC ImportPOVldtnCheckValues @importId
END