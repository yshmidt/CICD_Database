-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/28/2013
-- Description:	Posted Manufacturer Variance Report by Wonum or Part_no/Rev
--- In VFP report froms MANFVAR3 and MANFVAR4. Can use the same SP and the same report, the difference is in the order
-- Modified:	09/27/2013 DRP: Needed to change the parameter names from @StartDate/@EndDate to @lcDateStart/@lcDateEnd so that they would work with the webmanex Date Range feature
--							also changed the From statement for situations where the older VFP data did not populate the cdrill properly.
--				09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF. 
--				08/09/17 YS added functional currency
-- =============================================
CREATE PROCEDURE [dbo].[rptMfgrVarPosted] 
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
	
	---08/09/17 YS check for fc installed
	IF dbo.fn_IsFCInstalled() = 0
	BEGIN
		
		SELECT DISTINCT wono,M.[datetime] as Date,ISNULL(I.part_no,space(25)) as part_no,ISNULL(I.Revision,space(8)) as revision
				,isnull(I.descript,CAST('Missing part Infotmation' as CHAR(45))) as Descript,m.ISSUECOST,m.BOMCOST,m.TOTALVAR
				,H.Trans_no,H.TRANS_DT,H.FY,H.PERIOD,H.post_date,M.UNIQMFGVAR
		
		FROm	MFGRVAR M
				LEFT OUTER JOIN INVENTOR I on M.UNIQ_KEY =I.Uniq_key
				left outer join GlTransDetails D on m.UNIQMFGVAR = RTRIM(d.cdrill)
				left outer join GLTRANS T on t.GLUNIQ_KEY = d.fk_gluniq_key
				--left outer join (select GLTRANSHEADER.* from GLTRANSHEADER where TransactionType = 'MFGRVAR') H on H.GLTRANSUNIQUE = t.Fk_GLTRansUnique 
				left outer join gltransheader H  on T.Fk_GLTRansUnique =h.GLTRANSUNIQUE and h.TransactionType ='MFGRVAR'
			
		WHERE	m.vartype = 'MFGRV'
				--and h.TransactionType = 'MFGRVAR'
				and M.IS_REL_GL = 1
				--AND CAST(M.[DATETIME] AS DATE) BETWEEN @lcDateStart AND @lcDateEnd	--09/26/2014 DRP:  Removed
				and datediff(day,[datetime],@lcDateStart)<=0 and datediff(day,[datetime],@lcDateEnd)>=0
	END	--- IF dbo.fn_IsFCInstalled() = 0
	ELSE
	BEGIN
	---08/09/17 added functional currency
		SELECT DISTINCT wono,M.[datetime] as Date,ISNULL(I.part_no,space(25)) as part_no,ISNULL(I.Revision,space(8)) as revision
				,isnull(I.descript,CAST('Missing part Infotmation' as CHAR(45))) as Descript,
				ff.Symbol as funcCurr, m.ISSUECOST,m.BOMCOST,m.TOTALVAR,
				pf.Symbol as prCurr, m.ISSUECOSTPR,m.BOMCOSTPR,m.TOTALVARPR,
				H.Trans_no,H.TRANS_DT,H.FY,H.PERIOD,H.post_date,M.UNIQMFGVAR
		FROm	MFGRVAR M
				INNER JOIN Fcused PF ON M.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON M.FuncFcused_uniq = FF.Fcused_uniq	
				LEFT OUTER JOIN INVENTOR I on M.UNIQ_KEY =I.Uniq_key
				left outer join GlTransDetails D on m.UNIQMFGVAR = RTRIM(d.cdrill)
				left outer join GLTRANS T on t.GLUNIQ_KEY = d.fk_gluniq_key
				--left outer join (select GLTRANSHEADER.* from GLTRANSHEADER where TransactionType = 'MFGRVAR') H on H.GLTRANSUNIQUE = t.Fk_GLTRansUnique 
				left outer join gltransheader H  on T.Fk_GLTRansUnique =h.GLTRANSUNIQUE and h.TransactionType ='MFGRVAR'
			
		WHERE	m.vartype = 'MFGRV'
				--and h.TransactionType = 'MFGRVAR'
				and M.IS_REL_GL = 1
				and datediff(day,[datetime],@lcDateStart)<=0 and datediff(day,[datetime],@lcDateEnd)>=0
	END --- ELSE IF dbo.fn_IsFCInstalled() = 0	
END
			