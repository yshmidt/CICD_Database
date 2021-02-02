-- =============================================
-- Author:		Vicky Lu
-- Create date: 04/18/13 
-- Description:	This procedure will get all Invtmfhd records for passed in Uniq_key table variable
--- 12/04/14 YS  added Netable and changed 'WHERE' to use exists instead of IN
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetInvtmfgr4Uniq_key] 
	@ltUniq_key AS tUniq_key READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

-- 05/03/13 VL added Instore
SET NOCOUNT ON;
	SELECT UniqMfgrhd, Uniq_key, UniqWh, Location, QTY_OH, RESERVED, UniqSupno, W_key, Instore,Netable
		FROM Invtmfgr
		WHERE EXISTS
			(SELECT 1
				FROM @ltUniq_key t where t.Uniq_key=Invtmfgr.UNIQ_KEY)
		AND IS_DELETED = 0
END