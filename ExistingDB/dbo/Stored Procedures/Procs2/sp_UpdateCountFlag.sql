-- =============================================
-- Author:		Vicky Lu
-- Create date: 2012/02/08
-- Description:	Update Invtmfgr.CountFlag based on !Ccrecord.Is_Updated, called in Cycle form ScanABC method
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdateCountFlag]
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

UPDATE Invtmfgr
	SET COUNTFLAG = 'C' 
	WHERE W_KEY IN 
		(SELECT W_KEY 
			FROM CCRECORD
			WHERE IS_UPDATED = 0)

END



