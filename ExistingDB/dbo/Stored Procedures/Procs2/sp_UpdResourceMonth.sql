
-- This sp will update Actcap table to make current month to 'Startmonth' field, and move resource if user has not update the resource for morn than a month
CREATE PROCEDURE [dbo].[sp_UpdResourceMonth]
AS 

-- 04/17/13 VL Added to consider if Actcap.Startmonth > current month like startmonth = 12, but current month is 4
BEGIN
SET NOCOUNT ON;

DECLARE @lnMonDiff int, @lnCnt int, @lnCnt2 int, @SQLString nvarchar(200)

-- How many month from last update
-- 04/17/13 VL changed to consider if Startmonth > current month
--SELECT @lnMonDiff = MONTH(GETDATE()) - ActCap.STARTMONTH 
-- 06/05/15 VL added = sign so if same month, @lnMonDiff = 0
SELECT @lnMonDiff = CASE WHEN MONTH(GETDATE()) - ActCap.STARTMONTH >= 0 THEN MONTH(GETDATE()) - ActCap.STARTMONTH ELSE  MONTH(GETDATE()) - ActCap.STARTMONTH + 12 END
	FROM ACTCAP 

SET @lnCnt = 1

BEGIN
IF @lnMonDiff > 0
	BEGIN
	
	WHILE 12 - @lnMonDiff > @lnCnt - 1
	BEGIN
		SET @SQLString = 'UPDATE ActCap SET Resmonth'+LTRIM(RTRIM(STR(@lnCnt)))+' = Resmonth'+LTRIM(RTRIM(STR(@lnCnt+@lnMonDiff)))
		EXECUTE sp_executesql @SQLString
		SET @lnCnt = @lnCnt + 1		
	END

	
	WHILE @lnCnt - 1 < 12
	BEGIN	
		SET @SQLString = 'UPDATE ActCap SET Resmonth'+LTRIM(RTRIM(STR(@lnCnt)))+' = 1'
		EXECUTE sp_executesql @SQLString
		SET @lnCnt = @lnCnt + 1		
	END
	
	UPDATE ACTCAP SET STARTMONTH = MONTH(GETDATE())
	END
END

END