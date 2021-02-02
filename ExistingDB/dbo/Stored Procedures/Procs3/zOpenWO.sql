-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/08/2012
-- Description:	get information for MRP replaces ZOpenWo cursor
--11/23/15 YS  add is_forecast
-- 09/19/17 YS added Jobtype to woentry to separate Job type from the Status (openclos)
-- =============================================
CREATE PROCEDURE [dbo].[zOpenWO]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
     SELECT  CAST(WoNo as CHAR(15)) as WONO,
			CAST('WO' + WoNo  as char(24)) as Ref,
			Woentry.Uniq_Key,Due_date, Balance,Due_date as ReqDate, 
				-- 09/19/17 YS added Jobtype to woentry to separate Job type from the Status (openclos)
				Due_date as IndexDt, OpenClos,JobType, KitStatus, dbo.fn_GenerateUniqueNumber() as UniqMrpAct,
				PrjUnique,cast(0 as bit) as IsFirm,
				-- 09/19/17 YS added Jobtype to woentry to separate Job type from the Status (openclos)
				--CASE WHEN CHARINDEX('Firm',OpenClos)<>0 OR KitStatus<>' ' THEN Balance 
				CASE WHEN CHARINDEX('Firm',JobType)<>0 OR KitStatus<>' ' THEN Balance 
				WHEN I.Make_buy=1 THEN Balance ELSE 0.00 END AS ReqQty,
				CAST(CASE WHEN CHARINDEX('Firm',JobType)<>0 and CHARINDEX('Rework',JobType)<>0 THEN 'ReworkFirm'
				WHEN CHARINDEX('Firm',JobType)<>0 THEN 'Firm Order' 
				WHEN KitStatus<>' '  THEN 'Kitted' ELSE ' ' END as CHAR(15)) AS Action,
				I.Make_buy,I.Phant_make,I.Mrp_code as PassLevel,I.SCRAP,
				Balance-Balance as QtyUsed,Balance-Balance as FoundQty ,
				CAST(NULL as smalldatetime) as DtTakeAct ,
				CAST(NULL as smalldatetime) as StartDate ,
				CAST(null as smalldatetime) as KitDate,
				CAST(NULL as smalldatetime) as  PullDt, 
				CAST(NULL as smalldatetime) as PushDt, 
				SPACE(10) as OrgMrpSch ,SPACE(10) as UniqMrpSch,CAST(0 as Numeric(4,0)) as Offset,CAST(0 as bit) as Tested,
				--11/23/15 YS add is_forecast
				SPACE(1) as cExtra, cast(0 as int) as is_forecast
				FROM  WoEntry INNER JOIN Inventor I ON Woentry.Uniq_key=I.Uniq_key
				WHERE UPPER(OpenClos) <> 'CLOSED' 
				AND UPPER(OpenClos) <> 'CANCEL' 
				AND UPPER(OpenClos)<>'ARCHIVED'
				AND ((UPPER(OpenClos)<>'MFG HOLD' AND UPPER(OpenClos)<>'ADMIN HOLD')
				OR (UPPER(OpenClos) IN ('MFG HOLD','ADMIN HOLD') AND  MrponHold=0)) 
				AND Balance > 0
			
END