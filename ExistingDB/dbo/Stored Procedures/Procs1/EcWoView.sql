-- =============================================
-- Author:		Vicky Lu
-- Create date: 
-- Description:	
-- Modification:
-- Modified: 09/18/17 YS added JobType to Woentry table to separate Status (OpenClos) from Type
-- =============================================
CREATE PROC [dbo].[EcWoView] @gUniqEcNo AS char(10) = ' '
AS
-- 05/29/14 VL added Woentry.Complete
-- Modified: 09/18/17 YS added JobType to Woentry table to separate Status (OpenClos) from Type
SELECT Ecwo.Wono, Ecwo.Uniqecwono, Ecwo.Change, Ecwo.Balance, Ecwo.Uniqecno, 
	Woentry.Openclos, Woentry.Due_date, Woentry.Bldqty, Ecwo.IS_SnLotIssued, Ecwo.NewWono, Woentry.Complete,Woentry.JobType
	FROM Woentry, Ecwo
	WHERE Ecwo.Wono = Woentry.Wono
	AND Ecwo.Uniqecno = @gUniqecno
	ORDER BY Ecwo.Wono




