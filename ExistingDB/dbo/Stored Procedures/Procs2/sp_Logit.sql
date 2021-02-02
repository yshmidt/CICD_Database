-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/09/20
-- Description:	Save a record into SysHis table, what program is run
-- =============================================
CREATE PROCEDURE [dbo].[sp_Logit] @lcCompName char(20), @lcProgname char(15)
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

DECLARE @lcLic_no char(10), @lcManexverno char(20)

SELECT @lcLic_no = Lic_no, @lcManexverno = ManexVerno
	FROM MICSSYS
	
BEGIN TRANSACTION
BEGIN TRY;	

	INSERT INTO SysHis(Coname,Date,Patch,Sr,Ver, UniqueRec) 
		VALUES (@lcCompName, GETDATE(),@lcProgname, @lcLic_no , @lcManexverno, dbo.fn_GenerateUniqueNumber())	

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in updating SysHis table. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	
