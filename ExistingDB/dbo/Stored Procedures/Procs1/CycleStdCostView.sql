-- =============================================
-- Author:		
-- Create date: 
-- Description: Get latest stdcost for the cycle count
-- Modified:
-- 10/22/13 VL decide to pass a table variable with all the uniq_key to get stdcost
-- 05/30/17 VL added functional currency code
-- =============================================

-- Get latest stdcost for the cycle count
CREATE PROCEDURE [dbo].[CycleStdCostView]
	-- Add the parameters for the stored procedure here
	@ltPartList AS tUniq_key READONLY
AS
BEGIN

-- 10/22/13 VL decide to pass a table variable with all the uniq_key to get stdcost, PTI got a data problem that a ccrecord got incorrect stdcost, can not figure out why, but decide to find by uniq_key, not uniqccno
SET NOCOUNT ON;

-- 10/22/13 VL comment out old code that get all stdcost record by ccrecord criteria, it might not be correct because while user is still
-- in edit mode, those records might be reconciled and won't be selected in the return record set
--SELECT UniqCcno, Inventor.StdCost
--	FROM CCRECORD, INVENTOR
--	WHERE CCRECORD.Uniq_key = Inventor.UNIQ_KEY
--	AND (CCRECNCL = 0
--	AND CCINIT <> ''
--	AND (CCDATE <> ''
--	OR CCDATE IS NOT NULL))	
-- 10/22/13 VL start new code
SELECT Uniq_key, StdCost, StdCostPR 
	FROM INVENTOR 
	WHERE Uniq_key IN (SELECT Uniq_key FROM @ltPartList)
		
END	




