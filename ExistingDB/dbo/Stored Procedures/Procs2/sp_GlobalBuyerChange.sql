-- =============================================
-- Author:		Vicky Lu
-- Create date: 2014/03/07
-- Description: Globally change buyer from 'FROM' to 'TO'
-- =============================================

CREATE PROCEDURE [dbo].[sp_GlobalBuyerChange] @lcFrom char(3) = ' ', @lcTo char(3) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;		
	UPDATE INVENTOR
		SET BUYER_TYPE = @lcTo
		WHERE BUYER_TYPE = @lcFrom

	UPDATE POMAIN
		SET BUYER = @lcTo
		WHERE BUYER = @lcFrom
		AND (PoStatus <> 'CLOSED' AND PoStatus <> 'CANCEL')

	UPDATE PARTTYPE
		SET BUYER_TYPE = @lcTo
		WHERE BUYER_TYPE = @lcFrom
		
	
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in globally changing buyers. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END