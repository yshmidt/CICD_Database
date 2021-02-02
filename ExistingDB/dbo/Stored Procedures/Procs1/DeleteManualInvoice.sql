-- =============================================
-- Author: Nitesh B
-- Create date: 01/02/2020
-- Description:	This procedure will Used for delete manual invoice forever
-- =============================================
CREATE PROCEDURE [dbo].[DeleteManualInvoice]
	-- Add the parameters for the stored procedure here
	@lcinvoiceNo nvarchar(10),
	@lcPacklistno nvarchar(10)
AS
BEGIN                   
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- get ready to handle any errors
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	
	BEGIN TRY
	BEGIN TRANSACTION
	
	DELETE FROM wmNoteRelationship WHERE FkNoteId = (SELECT NoteID FROM wmNotes WHERE RecordId = @lcinvoiceNo);
	DELETE FROM wmNotes WHERE RecordId = @lcinvoiceNo;

	DELETE FROM PLPRICESTAX WHERE PACKLISTNO IN (SELECT PACKLISTNO FROM PLMAIN WHERE INVOICENO = @lcinvoiceNo AND PACKLISTNO = @lcPacklistno)
    DELETE FROM PLPRICES WHERE PACKLISTNO IN (SELECT PACKLISTNO FROM PLMAIN WHERE INVOICENO = @lcinvoiceNo AND PACKLISTNO = @lcPacklistno)
    DELETE FROM PLDETAIL WHERE PACKLISTNO IN (SELECT PACKLISTNO FROM PLMAIN WHERE INVOICENO = @lcinvoiceNo AND PACKLISTNO = @lcPacklistno)
    DELETE FROM PLMAIN WHERE INVOICENO = @lcinvoiceNo AND PACKLISTNO = @lcPacklistno
	
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
			SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

	END CATCH	
	IF @@TRANCOUNT>0
		COMMIT 
END