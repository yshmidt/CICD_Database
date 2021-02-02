-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/05/08
-- Description:	Delete all physical inventory records for @lcUniqPiHead
-- =============================================
CREATE PROCEDURE [dbo].[sp_DeletePhyInvt] @lcUniqPiHead AS char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;

	UPDATE INVTMFGR 
		SET CountFlag = ' ' 
		FROM Invtmfgr, PhyInvt
		WHERE Invtmfgr.W_key = PhyInvt.W_key
		AND PhyInvt.UNIQPIHEAD = @lcUniqPiHead
	
	DELETE FROM PHYINVTH WHERE UNIQPIHEAD = @lcUniqPiHead
	DELETE FROM PhyInvt WHERE UNIQPIHEAD = @lcUniqPiHead
	DELETE FROM PHYHDTL WHERE UNIQPIHEAD = @lcUniqPiHead
	DELETE FROM PHYINVTSER WHERE UNIQPIHEAD = @lcUniqPiHead
END TRY

BEGIN CATCH
	RAISERROR('Error occurred in deleting unwanted physical inventory records. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END








