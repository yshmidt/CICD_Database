CREATE PROCEDURE [dbo].[sp_UpdOneWOChkLst] @gWono AS char(10) = '', @lcShopfl_chk AS char(25), @cUserId AS char(8) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

/* This stored procedure is created to update one Wono WO chklist, now is used in RMA receiver for RMA Wonos*/

DECLARE @ZxxUseWoChk bit;
SELECT @ZxxUseWoChk = XxUseWochk FROM ShopfSet 

BEGIN TRY
	BEGIN TRANSACTION
		BEGIN
		UPDATE JbShpChk 
			SET ChkFlag = 1, ChkInit = @cUserId, ChkDate = GETDATE()
			WHERE Wono = @gWono
			AND Shopfl_chk = @lcShopfl_chk
			AND ChkFlag = 0
		END

		IF @ZxxUseWoChk = 1
		BEGIN
			SELECT DISTINCT Wono 
				FROM Jbshpchk
				WHERE ChkFlag = 0 
				AND Wono = @gWono
			
			-- All are checked for this Wono, Update Woentry.Kit
			IF @@ROWCOUNT = 0
			BEGIN
				UPDATE Woentry 
				SET Kit = 1,
					ReleDate = GETDATE() 
					WHERE Wono = @gWono
					AND KIT = 0
			END
			
		END				

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH	
END	








