-- =============================================
-- Author:  Shivshankar P
-- Create date: 08/03/17
-- Description:	Insert IReserveSerial
-- =============================================
CREATE PROCEDURE  [dbo].[IReserveSerialBulkInsert]
(
@tSerailIssue tSerialsIssue2Kit READONLY
)
AS
BEGIN
	SET NOCOUNT ON;
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

	      BEGIN TRANSACTION
	        	BEGIN TRY
	       
		           	insert into iReserveSerial (iResSerUnique,invtres_no,serialuniq,ipkeyunique,kaseqnum,isDeallocate)
			        select dbo.fn_GenerateUniqueNumber(),res.FkCompIssueHeader,res.PkSerialIssued,res.IpKeyUnique,res.SerialUniq,0 from @tSerailIssue res 

	        	END TRY	
		
				BEGIN CATCH
					 IF @@TRANCOUNT <>0
						 ROLLBACK TRAN ;
						SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );

				END CATCH	

	IF @@TRANCOUNT>0
	COMMIT TRANSACTION	
END
		