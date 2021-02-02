
-- =============================================
-- Author:		Vicky Lu
-- Create date: 04/09/14
-- Description:	This sp will validate the dataset passed in
--				if @lcAction = 'Check', it will check any invalid records and return problem dataset
--				if @lcAction = 'Import' it will eliminate the invalid records and import SN
-- Modification:04/16/14	VL	comment out HAVING Balance <> COUNT(*) while check if the sum of SN in invtser compared to zimport that cuased the error the program could not catch the error if SNs already have enough in invtser table
--				11/25/15	VL	added UPPER() for serialno, so the program will find the sn
-- 07/27/17 VL Rewrite the part that update @ZImport.Id_Value directly update from Dept_qty, the old code took long time
-- 07/28/17 VL Decide to separate the validation and import process into two SP: chkImportSerialno and sp_ImportSN
-- =============================================
CREATE PROCEDURE [dbo].[sp_ImportSN]

AS
BEGIN

SET NOCOUNT ON;
-- variable to hold an error information

DECLARE @ERRORNUMBER Int= 0
	,@ERRORSEVERITY int=0
	,@ERRORPROCEDURE varchar(max)=''
	,@ERRORLINE int =0
	,@ERRORMESSAGE varchar(max)=' '


BEGIN TRANSACTION
BEGIN TRY;		


--remove records from prior error log for the upload
DELETE FROM importSerialNoErrors
						
-- At this moment, ImportSerialNo.Wono, Serialno should have leading zero (updated in calling program),Uniq_key, balance are updated (from chkImportSerialno SP), and only need to update Deptkey for invtser.id_value here
	UPDATE ImportSerialNo SET Deptkey = Dept_qty.DEPTKEY
		FROM Dept_qty
		WHERE ImportSerialNo.Wono = Dept_qty.Wono
		AND SerialStrt = 1

	UPDATE ImportSerialNo SET Deptkey = Dept_qty.Deptkey
		FROM Dept_qty
		WHERE ImportSerialNo.Wono = Dept_qty.Wono
		AND ImportSerialNo.Deptkey = ''
		AND Dept_id = 'STAG'
	-- 07/27/17 VL End}		
		
	INSERT INTO INVTSER (SERIALUNIQ, SERIALNO, UNIQ_KEY, ID_KEY, ID_VALUE, SAVEDTTM, SAVEINIT, WONO)
	SELECT dbo.fn_GenerateUniqueNumber() AS Serialuiq, Serialno, Uniq_key, 'DEPTKEY' AS Id_key, Deptkey, GETDATE() AS SaveDttm, 
			'IMP' AS SaveInit, Wono
		FROM ImportSerialNo
			
	-- Now return what's inserted as output
	SELECT Wono, Serialno, Part_no, Revision
		FROM ImportSerialNo
		ORDER BY Wono, SerialNo



END TRY
BEGIN CATCH
	SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
		,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
		,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
		,@ERRORLINE = ISNULL(ERROR_LINE(),0)
		,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
	IF @@TRANCOUNT>0
		ROLLBACK TRANSACTION

	INSERT INTO importSerialNoErrors (Errorid,ErrorMessage,ErrorDate)
		VALUES 
	(ISNULL(ERROR_NUMBER(),0),
	'Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
	'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
	'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
	'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
	'Error Message: '+@ERRORMESSAGE,
	GETDATE())
	return -1
END CATCH

IF @@TRANCOUNT>0
COMMIT TRANSACTION
END