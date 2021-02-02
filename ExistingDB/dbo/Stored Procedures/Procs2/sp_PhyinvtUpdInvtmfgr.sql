-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/05/09
-- Description:	Update Invtmfgr from Phyinvt
-- =============================================
CREATE PROCEDURE [dbo].[sp_PhyinvtUpdInvtmfgr] @lcUniqPiHead char(10) = ' ', @lcUpdType char(1) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
BEGIN TRY;

UPDATE INVTMFGR 
	SET CountFlag = CASE WHEN @lcUpdType = 'P' THEN 'P' ELSE ' ' END 
	FROM Invtmfgr, PhyInvt
	WHERE Invtmfgr.W_key = PhyInvt.W_key
	AND PhyInvt.UNIQPIHEAD = @lcUniqPiHead

END TRY

BEGIN CATCH
	RAISERROR('Error occurred in updating physical inventory records. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;
END	









