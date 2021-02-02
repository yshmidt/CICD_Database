
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/08/09>
-- Description:	<SP to maintain Fy/period data for the GLTRANS table>
-- Need to run it only if changes were made to the beginning and end dates of the Fiscal periods
-- Can take a long time to run.
-- =============================================
CREATE PROCEDURE [dbo].[sp_MaintainFyPeriod4GlTrans] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- get beginning and end dates for the FY/Periods into zFyPeriods CTE and use this information to update FY/Period and 	fk_FyDtlUniq in the GLTrans table
	WITH ZFyPeriods
	AS
	(select F1.fiscalyr,D1.fk_fy_uniq,D1.FyDtlUniq,D1.period,D1.enddate,
		CASE WHEN D1.Period=1 THEN F1.dBeginDate ELSE (SELECT DATEADD(day,1,D2.Enddate) FROM GlFyrsDetl D2 where D2.fk_fy_uniq=D1.fk_fy_uniq and D2.Period=D1.Period-1) END as BeginDate 
	FROM GlFyrsDetl D1, GlFiscalYrs F1 where F1.Fy_uniq=D1.fk_FY_Uniq )
	UPDATE GlTransHeader SET Fy=ZFyPeriods.FiscalYr,Period=ZFyPeriods.Period,Fk_FyDtlUniq=ZFyPeriods.FyDtlUniq 
		FROM ZFyPeriods where GlTransHeader.Trans_dt BETWEEN ZFyPeriods.BeginDate AND ZFyPeriods.EndDate

	/* when I wanted to check if all transaction are related to the correct FY/Period here the code to use
		WITH ZFyPeriods
		AS
		(select F1.fiscalyr,D1.fk_fy_uniq,D1.FyDtlUniq,D1.period,D1.enddate,
		CASE WHEN D1.Period=1 THEN F1.dBeginDate ELSE (SELECT DATEADD(day,1,D2.Enddate) 
		FROM GlFyrsDetl D2 where D2.fk_fy_uniq=D1.fk_fy_uniq and D2.Period=D1.Period-1) END as BeginDate 
		FROM GlFyrsDetl D1, GlFiscalYrs F1 where F1.Fy_uniq=D1.fk_FY_Uniq ),
		ZNeedUpd 
		AS 
		(SELECT GlTransHeader.Fy,GltransHeader.Period,GltransHeader.Trans_dt,ZFyPeriods.BeginDate,ZFyPeriods.EndDate 
			from GltransHeader,ZFyPeriods where ZFyPeriods.FyDtlUniq=Gltrans.Fk_FyDtlUniq and 
			Trans_dt NOT BETWEEN  ZFyPeriods.BeginDate and ZFyPeriods.EndDate)
		SELECT * from ZNeedUpd
*/
END
