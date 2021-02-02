-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/29/2013
-- Description:	purchase Variance Detail Report by Po or Supplier
--- In VFP report froms PURVAR3 and PURVAR5. Can use the same SP and the same report, the difference is in the order
-- Modified:	09/27/2013 DRP: Needed to change the parameter names from @StartDate/@EndDate to @lcDateStart/@lcDateEnd so that they would work with the webmanex Date Range feature
--								Also changed the DateTime field name to be just Date and I also re-arranged the results putting the detailed the users would most 
--								likely want to see first and additional fields at the end . . . it looked better on the QuickViews
--				09/26/2014 DRP: the results were incorrectly duplicating when the purchase order item happen to have more than on schedule. Removed the POITSCHD table from the join and re-arranged some of the other links.
--								replaced the Date range filter wiht the DATEDIFF.  In the case where the user would only select one day . . . the procedure was not displaying any results. 
--				01/06/2017 VL:  added functional currency code, separate FC and non-FC
-- =============================================
CREATE PROCEDURE [dbo].[rptPurVarDetail] 
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
	select	pur_var.fk_UniqApHead,APMASTER.ponum, apmaster.UNIQSUPNO,Pur_var.trans_date as Date,SUPINFO.SUPNAME, apmaster.invno, Sinvoice.receiverno ,
			poitems.itemno, isnull(Inventor.part_no,poitems.part_no) as Part_no ,ISNULL(Inventor.Revision,poitems.REVISION ) as revision,isnull(inventor.descript,poitems.descript) as Descript
			,Pur_var.stdcost,Pur_var.costeach,Pur_var.acpt_qty,Pur_var.variance
			,isnull(inventor.part_class,poitems.PART_CLASS ) as part_class ,isnull(inventor.PART_TYPE ,poitems.PART_type ) as part_type , 
			Poitems.partmfgr, poitems.MFGR_PT_NO --,apmaster.terms
			, Poitems.ord_qty,Pur_var.gl_nbr_var, Pur_var.gl_nbr,poitems.uniq_key, Pur_var.var_key, Pur_var.is_rel_gl
			
	--From	PUR_VAR INNER JOIN APMASTER on pur_var.fk_UniqApHead =apmaster.UNIQAPHEAD	--09/26/2014 DRP:  Removed the entire From section and replaced it with the below
	--		inner join supinfo ON apmaster.UNIQSUPNO =supinfo.UNIQSUPNO   
	--		inner join SINVOICE on pur_var.fk_UniqApHead =sinvoice.fk_uniqaphead 
	--		inner join SINVDETL on sinvoice.SINV_UNIQ =SINVDETL.SINV_UNIQ 
	--		inner join POITSCHD on SINVDETL.UNIQDETNO =POITSCHD.UNIQDETNO 
	--		inner join POITEMS on poitems.UNIQLNNO =poitschd.UNIQLNNO   
	--		left outer join inventor on poitems.UNIQ_KEY =inventor.UNIQ_KEY 
	From	PUR_VAR INNER JOIN APMASTER on pur_var.fk_UniqApHead =apmaster.UNIQAPHEAD	--09/26/2014 DRP:  Added
			inner join supinfo ON apmaster.UNIQSUPNO =supinfo.UNIQSUPNO   
			inner join SINVDETL on pur_var.SDET_UNIQ =SINVDETL.Sdet_UNIQ 
			inner join SINVOICE on sinvdetl.SINV_UNIQ=sinvoice.SINV_UNIQ
			inner join POITEMS on poitems.UNIQLNNO =SINVDETL.UNIQLNNO   
			left outer join inventor on poitems.UNIQ_KEY =inventor.UNIQ_KEY 
	 
	 WHERE	pur_var.VARIANCE <>0.00 
			--and  cast(pur_var.Trans_date as date) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  removed
			and datediff(day,pur_Var.trans_date,@lcDateStart)<=0 and datediff(day,pur_var.trans_date,@lcDateEnd)>=0
ELSE
	select	pur_var.fk_UniqApHead,APMASTER.ponum, apmaster.UNIQSUPNO,Pur_var.trans_date as Date,SUPINFO.SUPNAME, apmaster.invno, Sinvoice.receiverno ,
			poitems.itemno, isnull(Inventor.part_no,poitems.part_no) as Part_no ,ISNULL(Inventor.Revision,poitems.REVISION ) as revision,isnull(inventor.descript,poitems.descript) as Descript
			,Pur_var.stdcost,Pur_var.costeach,Pur_var.acpt_qty,Pur_var.variance
			,isnull(inventor.part_class,poitems.PART_CLASS ) as part_class ,isnull(inventor.PART_TYPE ,poitems.PART_type ) as part_type , 
			Poitems.partmfgr, poitems.MFGR_PT_NO --,apmaster.terms
			, Poitems.ord_qty,Pur_var.gl_nbr_var, Pur_var.gl_nbr,poitems.uniq_key, Pur_var.var_key, Pur_var.is_rel_gl,
			-- 01/06/17 VL added functional currency fields
			Pur_var.stdcostPR,Pur_var.costeachPR, Pur_var.variancePR,FF.Symbol AS FSymbol, PF.Symbol AS PSymbol
			
	--From	PUR_VAR INNER JOIN APMASTER on pur_var.fk_UniqApHead =apmaster.UNIQAPHEAD	--09/26/2014 DRP:  Removed the entire From section and replaced it with the below
	--		inner join supinfo ON apmaster.UNIQSUPNO =supinfo.UNIQSUPNO   
	--		inner join SINVOICE on pur_var.fk_UniqApHead =sinvoice.fk_uniqaphead 
	--		inner join SINVDETL on sinvoice.SINV_UNIQ =SINVDETL.SINV_UNIQ 
	--		inner join POITSCHD on SINVDETL.UNIQDETNO =POITSCHD.UNIQDETNO 
	--		inner join POITEMS on poitems.UNIQLNNO =poitschd.UNIQLNNO   
	--		left outer join inventor on poitems.UNIQ_KEY =inventor.UNIQ_KEY 
	From	PUR_VAR 
			-- 01/06/17 VL added to show currency symbol
			INNER JOIN Fcused PF ON PUR_VAR.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON PUR_VAR.FuncFcused_uniq = FF.Fcused_uniq
			INNER JOIN APMASTER on pur_var.fk_UniqApHead =apmaster.UNIQAPHEAD	--09/26/2014 DRP:  Added
			inner join supinfo ON apmaster.UNIQSUPNO =supinfo.UNIQSUPNO   
			inner join SINVDETL on pur_var.SDET_UNIQ =SINVDETL.Sdet_UNIQ 
			inner join SINVOICE on sinvdetl.SINV_UNIQ=sinvoice.SINV_UNIQ
			inner join POITEMS on poitems.UNIQLNNO =SINVDETL.UNIQLNNO   
			left outer join inventor on poitems.UNIQ_KEY =inventor.UNIQ_KEY 
	 
	 WHERE	pur_var.VARIANCE <>0.00 
			--and  cast(pur_var.Trans_date as date) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  removed
			and datediff(day,pur_Var.trans_date,@lcDateStart)<=0 and datediff(day,pur_var.trans_date,@lcDateEnd)>=0

END