-- =============================================
-- Author:Satish B
-- Create date: 10/04/2018
-- Description : Insert into WFInstanceA and WFRequestA table for history
-- exec GenerateWFHistory 'T00000000001869'
-- =============================================
CREATE PROCEDURE GenerateWFHistory
	 @recordId char(15) = ''
 AS
 BEGIN
	SET NOCOUNT ON	 
	DECLARE @isFailed bit=0	
	BEGIN TRANSACTION
		BEGIN TRY
				-- Insert records into WFRequestA table
				MERGE INTO WFRequestA AS c
				USING WFRequest AS ct
					ON c.RecordId=ct.RecordId 
				WHEN NOT MATCHED AND ct.RecordId=@recordId THEN 
					  INSERT ([WFRequestAId]
							   ,[WFRequestId]
							   ,[ModuleId]
							   ,[RequestDate]
							   ,[RequestorId]
							   ,[WFComplete]
							   ,[RecordId])
					  VALUES (dbo.fn_GenerateUniqueNumber()
							   ,ct.WFRequestId
							   ,ct.ModuleId
							   ,ct.RequestDate
							   ,ct.RequestorId  
							   ,ct.WFComplete
							   ,ct.RecordId);

				-- Insert records into WFInstanceA table
				MERGE INTO WFInstanceA AS ia
				USING WFInstance AS i
					ON ia.WFInstanceId=i.WFInstanceId 
				WHEN NOT MATCHED AND i.WFRequestId IN (SELECT WFRequestId FROM WFRequest WHERE RecordId=@recordId) THEN
					  INSERT ([WFInstanceAId]
							   ,[WFInstanceId]
							   ,[WFRequestId]
							   ,[IsApproved]
							   ,[Comments]
							   ,[ActionDate]
							   ,[Approver]
							   ,[RejectToStep]
							   ,[WFConfigId])
					  VALUES (dbo.fn_GenerateUniqueNumber()
							   ,i.WFInstanceId
							   ,i.WFRequestId
							   ,i.IsApproved
							   ,i.Comments
							   ,i.ActionDate
							   ,i.Approver
							   ,i.RejectToStep
							   ,i.WFConfigId);

			  -- Delete record from WFInstance table
				DELETE FROM WFInstance WHERE WFRequestId IN (SELECT WFRequestId FROM WFRequest WHERE RecordId=@recordId)
	
			  -- Delete record from WFRequest table
				DELETE FROM WFRequest WHERE RecordId= @recordId
		END TRY
		BEGIN CATCH
			SET @isFailed=1;
			IF @@TRANCOUNT>0
				ROLLBACK
		END CATCH
			IF  @isFailed=1
				BEGIN
					RAISERROR('Error occurred while moving data from work flow tables to work flow history tables.',11,1)
					RETURN -1
				END
	COMMIT
 END



