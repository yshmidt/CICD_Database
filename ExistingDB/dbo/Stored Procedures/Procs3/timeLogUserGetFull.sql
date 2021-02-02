-- =============================================
-- Author:		David Sharp
-- Create date: 6/22/2012
-- Description:	get the all current information for selected user
-- 8/11/2015 Avinash : Added ReworkFirm and Firm Plann
-- 08/11/2015 YS we need to alow for other status. The only status we should not allow is closed or cancelled
-- 04/26/2016 Anuj Removed "and OpenClos<>'Closed'" as user needs to lock closed work orders in timelog
-- 12/16/2015 Raviraj P  : Select the respected number of dept  and order by number
-- =============================================
CREATE PROCEDURE [dbo].[timeLogUserGetFull]
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier,
	@noDays int=14,
	@openClose varchar(15)='Standard'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--Get current time records
	EXEC timeLogUserCurrentGet @userId
	--Get last @noDays of recent records
	EXEC timeLogUserRecentGet @userId,@noDays
	
	--Get the available WC
	--Raviraj P 12/16/2015 : Select the respected number of dept
	SELECT 	CONCAT(NUMBER,'-',DEPT_ID) As NumberDeptId,NUMBER, --12/16/2015 Raviraj P  : Select the respected number of dept and order by number
	DEPT_ID FROM DEPTS  ORDER BY NUMBER
	--Get the time types
	SELECT TMLOG_NO timeType,TMLOG_DESC descript,NUMBER,TMLOGTPUK timeTypeId fROM TMLOGTP
	--Get open WO
	SELECT WONO FROM WOENTRY WHERE
	--Avinash 8/11/2015 : It takes standard wo only
	-- OPENCLOS=@openClose
	--Avinash 8/11/2015 : Added ReworkFirm and Firm Plann so it will get the wo of status Standard,ReworkFirm and Firm Plann 
	--OPENCLOS='Standard' OR OPENCLOS='ReworkFirm' OR OPENCLOS='Firm Plann' 
	-- 08/11/2015 YS we need to alow for other statuses. The only status we should not allow is closed or cancel
	-- 04/26/2016 Anuj Removed "and OpenClos<>'Closed'" as user needs to lock closed work orders in timelog
	OpenCLos<>'Cancel'    
END