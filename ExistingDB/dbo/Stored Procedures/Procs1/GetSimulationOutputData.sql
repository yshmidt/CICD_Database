-- =============================================
-- Author:		Rajendra K	
-- Create date: <07/26/2018>
-- Description:Get simulation data
-- EXEC GetSimulationOutputData '0000000371',''  
-- 06/16/2019 Rajendra K : Added Variable @lKitIgnoreScrap,@WOBldQty,@lKitIgnoreScrap
-- 06/17/2019 Rajendra K : Changes Parameter of function [fn_PhantomSubSelect]
-- =============================================
CREATE PROCEDURE GetSimulationOutputData
(
@wono CHAR(10)='',
@uniqKey  CHAR(10)=''	
)
AS
BEGIN
DECLARE @WODue_date smalldatetime, @WOBldQty numeric(7,0),@lKitIgnoreScrap bit; -- 06/16/2019 Rajendra K : Added Variable @lKitIgnoreScrap,@WOBldQty,@lKitIgnoreScrap
	IF((@uniqKey IS NULL OR @uniqKey=''))
	BEGIN
	 SET @uniqKey = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @wono)
	END

SELECT @WODue_date = Due_date, @WOBldQty = BldQty FROM WOENTRY WHERE WONO = @wono -- 06/16/2019 Rajendra K : Added Variable @lKitIgnoreScrap,@WOBldQty,@lKitIgnoreScrap
SELECT @lKitIgnoreScrap = ISNULL(w.settingValue,m.settingValue) FROM MnxSettingsManagement m LEFT JOIN wmSettingsManagement w -- 05/24/19 Rajendra K Changed setting name  
                                            ON m.settingId=w.settingId WHERE settingName='ExcludeScrapInKitting' AND settingModule='ICMWOSetup'
	SELECT DEPT_ID AS WorkCenter
		  ,Uniq_Key AS UniqKey
		  ,RTRIM(PART_NO) + (CASE WHEN REVISION IS NULL OR REVISION = '' THEN REVISION ELSE '/'+ REVISION END) AS PART_NO
	      ,(CASE WHEN PART_CLASS IS NULL OR  PART_CLASS = '' THEN PART_CLASS ELSE PART_CLASS +'/ ' END ) + 
		  (CASE WHEN PART_TYPE IS NULL OR PART_TYPE ='' THEN PART_TYPE ELSE PART_TYPE + '/ '+DESCRIPT END) AS DESCRIPT
		  ,ReqQty
    ,ReqQty AS Shortage--CASE WHEN (ReqQty-Qty) > 0 THEN ReqQty-Qty ELSE 0 END AS Shortage  
		  ,0.0 AS TotalShortage
	-- 06/16/2019 Rajendra K : Changes Parameter of function [fn_PhantomSubSelect]
 FROM  --[dbo].[fn_phantomSubSelect](@uniqKey , @WOBldQty, 'T', @WODue_date, 'F', 'All', 'T', 0, @lKitIgnoreScrap, 0)  
 [dbo].[fn_PhantomSubSelect] (@uniqKey, @WOBldQty, 'T', @WODue_date, 'F', 'T', 'F', @lKitIgnoreScrap,0,0);  
END