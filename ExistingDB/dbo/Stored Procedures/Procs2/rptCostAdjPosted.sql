-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/29/2013
-- Description:	Posted Cost Adjustment
--- In VFP report froms INVCADJ1   
-- Modified:	09/27/2013 DRP: Needed to change the parameter names from @StartDate/@EndDate to @lcDateStart/@lcDateEnd so that they would work with the webmanex Date Range feature
--								Also changed the DateTime field name to be just Date and I also re-arranged the results putting the detailed the users would most 
--								likely want to see first and additional fields at the end . . . it looked better on the QuickViews
--				09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF. 
--				08/09/17 YS added functional currency. Added new column isErAdj - for the adjustment created by exchange rate changes for the standard cost
--				08/15/17 YS added qty_oh column (request from penang)
-- =============================================
CREATE PROCEDURE [dbo].[rptCostAdjPosted] 
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
	--08/15/17 YS added qty_oh column (request from penang)
		SELECT distinct isnull(warehous.WAREHOUSE,'') as Warehouse,h.Trans_dt,Isnull(Inventor.part_no,space(25)) as Part_no ,ISNULL(Inventor.Revision,space(8)) as revision,
			isnull(inventor.descript,space(45)) as Descript, 
			updtstd.qty_oh,UPDTSTD.rolltype,UPDTSTD.OLDMATLCST,UPDTSTD.NEWMATLCST,UPDTSTD.CHANGEAMT,UPDTSTD.WH_GL_NBR,H.Trans_no,H.TRANS_DT,H.FY,H.PERIOD,H.post_date
		FROM gltransheader H INNER JOIN GlTrans T on h.GLTRANSUNIQUE =T.Fk_GLTRansUnique 
			inner join GlTransDetails D on T.GLUNIQ_KEY =D.fk_gluniq_key  
			INNER JOIN updtstd on updtstd.UNIQ_UPDT = RTRIM(d.cdrill)
			LEFT OUTER JOIN Inventor on UpdtStd.Uniq_key=Inventor.Uniq_key
			left outer join WAREHOUS on UPDTSTD.UniqWh = warehous.UNIQWH
			WHERE --CAST(UpdtDate as date) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  REmoved
				datediff(day,UpdtDate,@lcDateStart)<=0 and datediff(day,UpdtDate,@lcDateEnd)>=0
				AND H.TransactionType = 'COSTADJ' order by trans_no
	END --- IF dbo.fn_IsFCInstalled() = 0 
	ELSE --- IF dbo.fn_IsFCInstalled() = 0
	BEGIN
		--				08/09/17 YS added functional currency
		--08/15/17 YS added qty_oh column (request from penang)
		SELECT distinct isnull(warehous.WAREHOUSE,'') as Warehouse,h.Trans_dt,Isnull(Inventor.part_no,space(25)) as Part_no ,ISNULL(Inventor.Revision,space(8)) as revision,
				isnull(inventor.descript,space(45)) as Descript 
				,UPDTSTD.rolltype,UPDTSTD.WH_GL_NBR,is_ErAdj,updtstd.Qty_oh,
				ff.Symbol as funcCurr,UPDTSTD.OLDMATLCST,UPDTSTD.NEWMATLCST,UPDTSTD.CHANGEAMT,
				pf.Symbol as prCurr,UPDTSTD.OLDMATLCSTPR,UPDTSTD.NEWMATLCSTPR,UPDTSTD.CHANGEAMTPR,
				H.Trans_no,H.FY,H.PERIOD,H.post_date
			FROM gltransheader H INNER JOIN GlTrans T on h.GLTRANSUNIQUE =T.Fk_GLTRansUnique 
			inner join GlTransDetails D on T.GLUNIQ_KEY =D.fk_gluniq_key  
			INNER JOIN updtstd on updtstd.UNIQ_UPDT = RTRIM(d.cdrill)
			INNER JOIN Fcused PF ON H.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON H.FuncFcused_uniq = FF.Fcused_uniq	
			LEFT OUTER JOIN Inventor on UpdtStd.Uniq_key=Inventor.Uniq_key
			left outer join WAREHOUS on UPDTSTD.UniqWh = warehous.UNIQWH
			WHERE --CAST(UpdtDate as date) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  REmoved
				datediff(day,UpdtDate,@lcDateStart)<=0 and datediff(day,UpdtDate,@lcDateEnd)>=0
				AND H.TransactionType = 'COSTADJ' order by trans_no


	END --- else IF dbo.fn_IsFCInstalled() = 0   
END