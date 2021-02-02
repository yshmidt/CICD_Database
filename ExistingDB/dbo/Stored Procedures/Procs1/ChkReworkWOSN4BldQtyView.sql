-- =============================================
-- Author:		Vicky	
-- Create date: 01/30/2013
-- Description:	This procdure will try to get all the serial numbers for passed in WO compared to the build qty, 
--				if not match, return back those records, these records will be removed from transfer process, used in SHOPFLBC
-- 09/18/17 YS added JobType column to separate Status from Type
-- =============================================
CREATE PROCEDURE [dbo].[ChkReworkWOSN4BldQtyView]  @ltWono AS tWono READONLY
	 
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Get all Rework WO
-- 09/18/17 YS added JobType column to separate Status from Type
WITH ZRwkWo AS
(
	SELECT Wono, BldQty 
		FROM Woentry a
		WHERE Wono IN 
			(SELECT Wono 
				FROM @ltWono) 
		AND (JobType = 'Rework' 
		OR JobType = 'ReworkFirm') 
		AND SerialYes = 1
),
-- Get Serial number count for WO
ZRwkSer AS 
(
	SELECT Wono, ISNULL(COUNT(*),0) AS SerCnt 
		FROM InvtSer 
		WHERE Wono <> ''
		AND Wono IN 
			(SELECT Wono 
				FROM ZRwkWo) 
		GROUP BY Wono
)

SELECT ZRwkWo.Wono, ZRwkWo.BldQty, ISNULL(ZRwkSer.SerCnt,0) AS SerCnt2 
	FROM ZRwkWo LEFT OUTER JOIN ZRwkSer
	ON ZRwkWo.Wono = ZRwkSer.Wono 
	WHERE ZRwkWo.BldQty <> ISNULL(ZRwkSer.SerCnt,0)
	
		
END