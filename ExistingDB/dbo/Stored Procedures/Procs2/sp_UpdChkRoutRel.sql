CREATE PROCEDURE [dbo].[sp_UpdChkRoutRel] @gUniq_key AS char(10) = '', @cUserId AS char(8) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

/* This stored procedure is created to update WO chklist when user check traveler released checkbox and if 
 the WO release check list is used */

DECLARE @ZWo4Uniq_key TABLE (Wono char(10));
INSERT @ZWo4Uniq_key
	SELECT Wono
		FROM Woentry
		WHERE Uniq_key = @gUniq_key AND (OpenClos <> 'Cancel' AND OpenClos <> 'Closed' AND OpenClos <> 'ARCHIVED')

DECLARE @ZxxUseWoChk bit;
SELECT @ZxxUseWoChk = XxUseWochk FROM ShopfSet 

DECLARE @ZUpdWo TABLE (Wono char(10));

BEGIN TRY
	BEGIN TRANSACTION
		BEGIN
		UPDATE JbShpChk 
			SET ChkFlag = 1, ChkInit = @cUserId, ChkDate = GETDATE()
			WHERE Wono IN 
				(SELECT Wono FROM @ZWo4Uniq_key)
			AND Shopfl_chk = 'TRAVELER RELEASED'
			AND ChkFlag = 0
		END

		IF @ZxxUseWoChk = 1
		BEGIN
			-- Get all WO that has all checklist is checked for the uniq_key
			INSERT @ZUpdWo
			SELECT Wono 
				FROM @ZWo4Uniq_key
				WHERE Wono NOT IN
					(SELECT DISTINCT Wono 
						FROM Jbshpchk
						WHERE ChkFlag = 0 
						AND Wono IN 
							(SELECT Wono
								FROM @ZWo4Uniq_key))

			-- Update the Woentry
			UPDATE Woentry 
				SET Kit = 1,
					ReleDate = GETDATE() 
				WHERE Wono IN 
					(SELECT Wono 
						FROM @ZUpdWo) 
				AND Kit = 0
		END				

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH	
END	