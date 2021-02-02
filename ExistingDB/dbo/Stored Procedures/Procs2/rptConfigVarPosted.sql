-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/28/2013
-- Description:	Posted Configuration Variance Report by Wonum or Part_no/Rev
--- In VFP report froms CONFVAR3   and CONFVAR4. Can use the same SP and the same report, the difference is in the order
-- Modified:	09/27/2013 DRP: Needed to change the parameter names from @StartDate/@EndDate to @lcDateStart/@lcDateEnd so that they would work with the webmanex Date Range feature
--								Also changed the DateTime field name to be just Date and I also re-arranged the results putting the detailed the users would most 
--								likely want to see first and additional fields at the end . . . it looked better on the QuickViews
--				09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF.
--				02/06/2017	VL:	Added functional currency code and separate FC and non-FC
--				08/09/2017 YS Added PR values
-- =============================================
CREATE PROCEDURE [dbo].[rptConfigVarPosted] 
	-- Add the parameters for the stored procedure here
	@lcDateStart Date = null, 
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
	
	IF dbo.fn_IsFCInstalled() = 0
		BEGIN
		SELECT DISTINCT	confgvar.WONO,H.TRANS_DT,ISNULL(inventor.part_no,SPACE(25)) as part_no
				,ISNULL(Inventor.Revision,space(8)) as revision,isnull(inventor.descript,CAST('Missing part Infotmation' as CHAR(45))) as Descript
				,confgvar.QTYTRANSF,CONFGVAR.STDCOST,CONFGVAR.WIPCOST,CONFGVAR.VARIANCE,TotalVar
				,Confgvar.Uniq_Key,confgvar.CNFG_GL_NB,confgvar.WIP_GL_NBR,confgvar.[datetime] as Date ,H.Trans_no,H.FY,H.PERIOD
		FROM	gltransheader H INNER JOIN GlTrans T on h.GLTRANSUNIQUE =T.Fk_GLTRansUnique 
				inner join GlTransDetails D on T.GLUNIQ_KEY =D.fk_gluniq_key  
				inner join confgvar on Confgvar.UNIQCONF=RTRIM(D.CDRILL) 
				LEFT OUTER JOIN inventor on confgvar.uniq_key = inventor.uniq_key 
		WHERE	--CAST([datetime] as DATE) between @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  removed
				datediff(day,CONFGVAR.[datetime],@lcDateStart)<=0 and datediff(day,CONFGVAR.[datetime],@lcDateEnd)>=0
				AND confgvar.IS_rel_gl=1
				AND (VarType = 'CONFG' OR VarType='RVAR') 
				AND H.TransactionType = 'CONFGVAR'
		END		    
	ELSE
		BEGIN
		SELECT DISTINCT	confgvar.WONO,H.TRANS_DT,ISNULL(inventor.part_no,SPACE(25)) as part_no
				,ISNULL(Inventor.Revision,space(8)) as revision,isnull(inventor.descript,CAST('Missing part Infotmation' as CHAR(45))) as Descript
				,confgvar.QTYTRANSF,
				-- 02/06/17 VL added functional currency code
				--08/09/17 YS added PR Values
				confgvar.CNFG_GL_NB,confgvar.WIP_GL_NBR,
				FF.Symbol AS FSymbol,CONFGVAR.STDCOST,CONFGVAR.WIPCOST,CONFGVAR.VARIANCE,TotalVar,
				PF.Symbol AS PSymbol,CONFGVAR.STDCOSTPR,CONFGVAR.WIPCOSTPR,confgvar.VARIANCEPR,confgvar.TOTALVARPR
				,Confgvar.Uniq_Key,confgvar.[datetime] as Date ,H.Trans_no,H.FY,H.PERIOD
							
				--test only
				,confgvar.UNIQCONF
		FROM	gltransheader H 
				-- 02/06/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON H.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON H.FuncFcused_uniq = FF.Fcused_uniq			
				INNER JOIN GlTrans T on h.GLTRANSUNIQUE =T.Fk_GLTRansUnique 
				inner join GlTransDetails D on T.GLUNIQ_KEY =D.fk_gluniq_key  
				inner join confgvar on Confgvar.UNIQCONF=RTRIM(D.CDRILL) 
				LEFT OUTER JOIN inventor on confgvar.uniq_key = inventor.uniq_key 
		WHERE	--CAST([datetime] as DATE) between @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  removed
				datediff(day,CONFGVAR.[datetime],@lcDateStart)<=0 and datediff(day,CONFGVAR.[datetime],@lcDateEnd)>=0
				AND confgvar.IS_rel_gl=1
				AND (VarType = 'CONFG' OR VarType='RVAR') 
				AND H.TransactionType = 'CONFGVAR'

		END
END