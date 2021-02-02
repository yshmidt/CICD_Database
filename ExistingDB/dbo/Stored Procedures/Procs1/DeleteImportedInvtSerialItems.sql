--========================================================
-- Author:		ShivShankar P
-- Create date: 02/28/2018
-- Description:	This SP is Called form inventor upload module used for delete selected Imported data
-- Modified:
--========================================================
CREATE PROCEDURE [dbo].[DeleteImportedInvtSerialItems]              
(              
	@serialDetailIdList VARCHAR(MAX)           
)              
AS              
BEGIN  

SET NOCOUNT ON;                            
BEGIN TRY                  
BEGIN TRANSACTION

-- declare variable to catch an error
DECLARE @errorMessage NVARCHAR(4000), @errorSeverity INT,@errorState INT

SET @serialDetailIdList = REPLACE(REPLACE(REPLACE(@serialDetailIdList,'[',''),']',''),'"','') 
 
DECLARE @importedSerialItem table (SerialDetailId UNIQUEIDENTIFIER)

INSERT INTO @importedSerialItem (SerialDetailId)  SELECT id FROM dbo.fn_simpleVarcharlistToTable(@serialDetailIdList,',')  

DELETE FROM ImportInvtSerialFields where SerialDetailId in (SELECT SerialDetailId from @importedSerialItem)


COMMIT TRANSACTION              
              
END TRY      
      
BEGIN CATCH                          
	IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION;      
	    SELECT @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                    
END CATCH                       
END