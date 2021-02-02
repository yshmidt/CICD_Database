-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/28/2013
-- Description:	Posted Inventory Cost Variance Report by Wonum or Part_no/Rev
--				These records where actually included in the ConfgVariance reports, but we are breaking them out into their own within SQL.
-- Modified:	09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF.
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtCostVarPosted] 

	-- Add the parameters for the stored procedure here
	@lcDateStart Date = null , 
	@lcDateEnd Date = null 
	
 , @userId uniqueidentifier=null 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @lcDateStart = CASE WHEN @lcDateStart IS NULL THEN DATEADD(Day,7,GETDATE()) ELSE @lcDateStart END, 
		   @lcDateEnd= CASE WHEN @lcDateEnd IS NULL THEN GETDATE() ELSE @lcDateEnd END ;
	
	SELECT DISTINCT	confgvar.WONO,H.TRANS_DT,ISNULL(inventor.part_no,SPACE(25)) as part_no
			,ISNULL(Inventor.Revision,space(8)) as revision,isnull(inventor.descript,CAST('Missing part Infotmation' as CHAR(45))) as Descript
			,confgvar.QTYTRANSF,CONFGVAR.STDCOST,CONFGVAR.WIPCOST,CONFGVAR.VARIANCE,TotalVar
			,Confgvar.Uniq_Key,confgvar.CNFG_GL_NB,confgvar.WIP_GL_NBR,confgvar.[datetime] as Date ,H.Trans_no,H.FY,H.PERIOD,VARTYPE

	from confgvar 
			left outer join inventor on confgvar.uniq_key = inventor.uniq_key
			left outer join GlTransDetails D on confgvar.uniqconf = rtrim(d.cdrill)
			left outer join GLTRANS T on t.GLUNIQ_KEY = d.fk_gluniq_key
			left outer join (select GLTRANSHEADER.* from GLTRANSHEADER where TransactionType = 'CONFG') H on H.GLTRANSUNIQUE = t.Fk_GLTRansUnique 
			
	WHERE	--CAST([datetime] as DATE) between @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  Removed
			datediff(day,confgvar.[datetime],@lcDateStart)<=0 and datediff(day,confgvar.[datetime],@lcDateEnd)>=0
			AND confgvar.IS_rel_gl=1
			and VARTYPE <> 'CONFG' and VARTYPE <> 'RVAR' and VARTYPE <> ''
			
		    
END