CREATE PROCEDURE [dbo].[sp_UpdOneInvMatlType] @cUniq_key AS char(10) = '', @cUserId AS char(8) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @ReturnMatlType char(10), @lcNewUniqNbr char(10),@lcOldMatlType char(10);

EXEC sp_GetOneInvMatlType @cUniq_key, @ReturnMatlType OUTPUT

BEGIN TRY
	BEGIN TRANSACTION
		/* Get Old Matltype for updating UpdMatpLog purpose */
		SELECT @lcOldMatlType = MatlType
			FROM Inventor
			WHERE Uniq_key = @cUniq_key
		/* Update Inventor */
		UPDATE Inventor 
			SET MatlType=@ReturnMatlType, 
				MtChgDt=GETDATE(),
				MtChgInit=@cUserID
			WHERE Uniq_key = @cUniq_key

		/* Update UpdMtpLog */
		--05/27/10 YS move code to Inventor_update trigger
		--EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
		--INSERT INTO UpdMatTpLog (UqMttpLog, Uniq_key, FromMatlType, ToMatlType, MtChgDt, MtChgInit)
		--	VALUES (@lcNewUniqNbr, @cUniq_key, @lcOldMatlType, @ReturnMatlType, GETDATE(), @cUserID)

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION
END CATCH	
END	