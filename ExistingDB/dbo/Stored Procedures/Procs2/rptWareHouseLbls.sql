-- =============================================
-- Author:		Shivshankar p
-- Create date: 06/08/2018
-- Description:	Print Warehouse Label
-- [rptWareHouseLbls] 'A12:R1:S2:B14','LF1JA8EBYR'
-- 04/25/2019 Rajendra K : Added new variable @warehouse 
-- 04/25/2019 Rajendra K : Added IF ELSE statement and #temp table if wh/loc not exists in invtmfgr table to get WH/LOC
-- 08/06/2019 Rajendra : Changed location datatype from VARCHAR to NVARCHAR
--08/08/19 YS Location is 200 characters in all the tables
-- =============================================
CREATE PROCEDURE [dbo].[rptWareHouseLbls]   
@location NVARCHAR(200) ='',-- 08/06/2019 Rajendra : Changed location datatype from VARCHAR to NVARCHAR
@uniqWh CHAR (10) =''

 AS 
   BEGIN
   SET NOCOUNT ON;  -- 04/25/2019 Rajendra K : Added new variable @warehouse 
   DECLARE @warehouse nvarchar(20);
   IF OBJECT_ID(N'tempdb..#TempD') IS NOT NULL
     DROP TABLE #Temp ; 

	   SET @location =  ISNULL(@location,'')
	-- 04/25/2019 Rajendra K : Added IF ELSE statement and #temp table if wh/loc not exists in invtmfgr table to get WH/LOC
	SELECT DISTINCT INVTMFGR.UNIQWH,location,  WAREHOUS.WAREHOUSE + '/' + LOCATION AS WHLocation INTO #Temp FROM WAREHOUS JOIN INVTMFGR ON WAREHOUS.UNIQWH  = INVTMFGR.UNIQWH   
	   WHERE  WAREHOUS.UNIQWH =  @uniqWh  AND  (( @location = '' AND  INVTMFGR.LOCATION = INVTMFGR.LOCATION) OR ( @location <> ''
	          AND INVTMFGR.LOCATION=@location))
	-- 04/25/2019 Rajendra K : Added IF ELSE statement and #temp table if wh/loc not exists in invtmfgr table to get WH/LOC
	IF EXISTS(SELECT 1 FROM  #Temp)
	BEGIN
		SELECT * FROM #Temp
	END
	ELSE
	BEGIN
		SET @warehouse = (SELECT RTRIM(WAREHOUSE) from WAREHOUS where UNIQWH = @uniqWh);
		SELECT @warehouse AS UNIQWH,@location AS location,@warehouse+ '/' + @location AS WHLocation;
	END
END