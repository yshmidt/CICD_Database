-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/29/2013
-- Description:	Posted Purchase Variance Report 
--- In VFP report froms PURVAR4
-- Modified:	09/27/2013 DRP: Needed to change the parameter names from @StartDate/@EndDate to @lcDateStart/@lcDateEnd so that they would work with the webmanex Date Range feature
--								Also changed the DateTime field name to be just Date and I also re-arranged the results putting the detailed the users would most 
--								likely want to see first and additional fields at the end . . . it looked better on the QuickViews
--				09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF.  In the case where the user would only select one day . . . the procedure was not displaying any results.
--				07/07/16 DRP:  we had to change how the sinvoice and sinv_detl where joined.  it was causing too many records to be returned. 
--				01/06/2017 VL:  added functional currency code, separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[rptPurVarPosted] 
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

-- 01/06/17 VL added to check if FC is installed or not
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
IF @lFCInstalled = 0	

	SELECT DISTINCT APMASTER.ponum,H.TRANS_DT as Date,SUPINFO.SUPNAME,apmaster.invno,Sinvoice.receiverno,POITEMS.ITEMNO
			,isnull(Inventor.part_no,poitems.part_no) as Part_no,ISNULL(Inventor.Revision,poitems.REVISION ) as revision,isnull(inventor.descript,poitems.descript) as Descript 
			,Pur_var.stdcost,Pur_var.costeach,Pur_var.acpt_qty,Pur_var.variance,isnull(inventor.part_class,poitems.PART_CLASS ) as part_class
			,isnull(inventor.PART_TYPE ,poitems.PART_type ) as part_type,Poitems.partmfgr,poitems.MFGR_PT_NO,Poitems.ord_qty,Pur_var.gl_nbr_var
			, Pur_var.gl_nbr,poitems.uniq_key, Pur_var.var_key, Pur_var.is_rel_gl,H.FY,H.PERIOD,H.post_date,pur_var.fk_UniqApHead, apmaster.UNIQSUPNO,pur_var.trans_date,H.Trans_no
			--,apmaster.terms,    
	FRoM	Gltransheader H INNER JOIN GlTrans T on h.GLTRANSUNIQUE =T.Fk_GLTRansUnique 
			inner join GlTransDetails D on T.GLUNIQ_KEY =D.fk_gluniq_key   
			INNER JOIN PUR_VAR ON pur_var.VAR_KEY =RTRIM(d.cDrill)
			INNER JOIN APMASTER on pur_var.fk_UniqApHead =apmaster.UNIQAPHEAD 
			inner join supinfo ON apmaster.UNIQSUPNO =supinfo.UNIQSUPNO   
			inner join SINVDETL on pur_var.SDET_UNIQ =SINVDETL.Sdet_UNIQ 
			inner join SINVOICE on sinvdetl.SINV_UNIQ=sinvoice.SINV_UNIQ
			--inner join SINVOICE on pur_var.fk_UniqApHead =sinvoice.fk_uniqaphead	--07/07/16 DRP these joins were causing too many results to be returned.  Replaced with the above. 
			--inner join SINVDETL on sinvoice.SINV_UNIQ =SINVDETL.SINV_UNIQ		--07/07/16 DRP these joins were causing too many results to be returned.  Replaced with the above.
			inner join POITSCHD on SINVDETL.UNIQDETNO =POITSCHD.UNIQDETNO 
			inner join POITEMS on poitems.UNIQLNNO =poitschd.UNIQLNNO   
			left outer join inventor on poitems.UNIQ_KEY =inventor.UNIQ_KEY 
	WHERE	pur_var.IS_REL_GL = 1 
			--and pur_var.TRANS_DATE BETWEEN @lcDateStart and @lcDateEnd order by trans_no	--09/26/2014 DRP:  removed
			and datediff(day,pur_Var.trans_date,@lcDateStart)<=0 and datediff(day,pur_var.trans_date,@lcDateEnd)>=0
ELSE
	SELECT DISTINCT APMASTER.ponum,H.TRANS_DT as Date,SUPINFO.SUPNAME,apmaster.invno,Sinvoice.receiverno,POITEMS.ITEMNO
			,isnull(Inventor.part_no,poitems.part_no) as Part_no,ISNULL(Inventor.Revision,poitems.REVISION ) as revision,isnull(inventor.descript,poitems.descript) as Descript 
			,Pur_var.stdcost,Pur_var.costeach,Pur_var.acpt_qty,Pur_var.variance,isnull(inventor.part_class,poitems.PART_CLASS ) as part_class
			,isnull(inventor.PART_TYPE ,poitems.PART_type ) as part_type,Poitems.partmfgr,poitems.MFGR_PT_NO,Poitems.ord_qty,Pur_var.gl_nbr_var
			, Pur_var.gl_nbr,poitems.uniq_key, Pur_var.var_key, Pur_var.is_rel_gl,H.FY,H.PERIOD,H.post_date,pur_var.fk_UniqApHead, apmaster.UNIQSUPNO,pur_var.trans_date,H.Trans_no,
			Pur_var.stdcostPR,Pur_var.costeachPR,Pur_var.variancePR,FF.Symbol AS FSymbol, PF.Symbol AS PSymbol
			--,apmaster.terms,    
	FRoM	Gltransheader H INNER JOIN GlTrans T on h.GLTRANSUNIQUE =T.Fk_GLTRansUnique 
			inner join GlTransDetails D on T.GLUNIQ_KEY =D.fk_gluniq_key   
			INNER JOIN PUR_VAR ON pur_var.VAR_KEY =RTRIM(d.cDrill)
			-- 01/06/17 VL added to show currency symbol
			INNER JOIN Fcused PF ON PUR_VAR.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON PUR_VAR.FuncFcused_uniq = FF.Fcused_uniq
			INNER JOIN APMASTER on pur_var.fk_UniqApHead =apmaster.UNIQAPHEAD 
			inner join supinfo ON apmaster.UNIQSUPNO =supinfo.UNIQSUPNO   
			inner join SINVDETL on pur_var.SDET_UNIQ =SINVDETL.Sdet_UNIQ 
			inner join SINVOICE on sinvdetl.SINV_UNIQ=sinvoice.SINV_UNIQ
			--inner join SINVOICE on pur_var.fk_UniqApHead =sinvoice.fk_uniqaphead	--07/07/16 DRP these joins were causing too many results to be returned.  Replaced with the above. 
			--inner join SINVDETL on sinvoice.SINV_UNIQ =SINVDETL.SINV_UNIQ		--07/07/16 DRP these joins were causing too many results to be returned.  Replaced with the above.
			inner join POITSCHD on SINVDETL.UNIQDETNO =POITSCHD.UNIQDETNO 
			inner join POITEMS on poitems.UNIQLNNO =poitschd.UNIQLNNO   
			left outer join inventor on poitems.UNIQ_KEY =inventor.UNIQ_KEY 
	WHERE	pur_var.IS_REL_GL = 1 
			--and pur_var.TRANS_DATE BETWEEN @lcDateStart and @lcDateEnd order by trans_no	--09/26/2014 DRP:  removed
			and datediff(day,pur_Var.trans_date,@lcDateStart)<=0 and datediff(day,pur_var.trans_date,@lcDateEnd)>=0
END