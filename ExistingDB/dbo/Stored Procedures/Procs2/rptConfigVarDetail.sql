-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/27/2013
-- Description:	Configuration Variance Detail Report by Wonum or Part_no/Rev
---				In VFP report froms CONFVAR1   and CONFVAR2. Can use the same SP and the same report, the difference is in the order
-- Modified:	09/27/2013 DRP: Needed to change the parameter names from @StartDate to @lcDateStart so that they would work with the webmanex Date Range feature
--								Also changed the DateTime field name to be just Date . . . it looked better on the QuickViews
--				10/08/2013 DRP: added the Vartype = '' or vartype = 'CONFG' in the where section below.  Just to make sure that for older records from vfp are included into this report
--							older records might have a blank vartype.
--				09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF.
--				02/06/2017	VL: Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptConfigVarDetail] 
	 --Add the parameters for the stored procedure here
	@lcDateStart Date = null 
	,@lcDateEnd Date = null 
	,@userId uniqueidentifier=null 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @lcDateStart = CASE WHEN @lcDateStart IS NULL THEN DATEADD(Day,7,GETDATE()) ELSE @lcDateStart END, 
		   @lcDateEnd= CASE WHEN @lcDateEnd IS NULL THEN GETDATE() ELSE @lcDateEnd END ;
	
	-- 02/06/17 VL separate FC and non-FC
	IF dbo.fn_IsFCInstalled() = 0
		BEGIN
		select	ConfgVar.UNIQCONF,Confgvar.WONO,Confgvar.[DATETIME] as Date,ISNULL(inventor.part_no,SPACE(25)) as part_no
				,ISNULL(inventor.revision,SPACE(8)) as revision,isnull(inventor.descript,CAST('Missing Inventory Information' as varchar(45))) as Descript
				,ConfgVar.UNIQ_KEY,confgvar.QTYTRANSF,confgvar.STDCOST ,WipCost,Variance,ROUND(confGvar.TotalVar,2) AS TotalVar,Confgvar.IS_REL_GL 
				,Confgvar.Vartype,ConfgVar.CNFG_GL_NB,confgvar.WIP_GL_NBR
				,CASE WHEN SIGN(Confgvar.StdCost-ConfgVar.WIPCOST)=SIGN(ConfgVar.Variance) THEN (confgvar.STDCOST*confgvar.QTYTRANSF-confgvar.TOTALVAR)/confgvar.QTYTRANSF 
					ELSE (confgvar.STDCOST*confgvar.QTYTRANSF+confgvar.TOTALVAR)/confgvar.QTYTRANSF END AS WipCostR 
				,CASE WHEN SIGN(ConfgVar.StdCost-ConfgVar.WipCost)=SIGN(ConfgVar.variance) 
					THEN confgvar.STDCOST -((Confgvar.STDCOST *CONFGVAR.QTYTRANSF -confgvar.TOTALVAR)/confgvar.QTYTRANSF) 
						ELSE ((confGvar.StdCost*confGvar.QtyTransf+confGvar.TotalVar)/confGvar.QtyTransf)-confGvar.StdCost END as VarianceR
				,confgvar.INVTXFER_N,confgvar.TRANSFTBLE,confgvar.CNFGGLLINK 
		from	CONFGVAR LEFT OUTER JOIN INVENTOR on Confgvar.UNIQ_KEY =Inventor.UNIQ_KEY 
		where	--CAST(ConfgVar.[DATETIME] as DATE) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  Removed
				datediff(day,CONFGVAR.[datetime],@lcDateStart)<=0 and datediff(day,CONFGVAR.[datetime],@lcDateEnd)>=0
				and (Confgvar.VARTYPE = '' or CONFGVAR.VARTYPE = 'CONFG') 
		 order by part_no,revision
		 END
	ELSE
		BEGIN
		select	ConfgVar.UNIQCONF,Confgvar.WONO,Confgvar.[DATETIME] as Date,ISNULL(inventor.part_no,SPACE(25)) as part_no
				,ISNULL(inventor.revision,SPACE(8)) as revision,isnull(inventor.descript,CAST('Missing Inventory Information' as varchar(45))) as Descript
				,ConfgVar.UNIQ_KEY,confgvar.QTYTRANSF,confgvar.STDCOST ,WipCost,Variance,ROUND(confGvar.TotalVar,2) AS TotalVar,Confgvar.IS_REL_GL 
				,Confgvar.Vartype,ConfgVar.CNFG_GL_NB,confgvar.WIP_GL_NBR
				,CASE WHEN SIGN(Confgvar.StdCost-ConfgVar.WIPCOST)=SIGN(ConfgVar.Variance) THEN (confgvar.STDCOST*confgvar.QTYTRANSF-confgvar.TOTALVAR)/confgvar.QTYTRANSF 
					ELSE (confgvar.STDCOST*confgvar.QTYTRANSF+confgvar.TOTALVAR)/confgvar.QTYTRANSF END AS WipCostR 
				,CASE WHEN SIGN(ConfgVar.StdCost-ConfgVar.WipCost)=SIGN(ConfgVar.variance) 
					THEN confgvar.STDCOST -((Confgvar.STDCOST *CONFGVAR.QTYTRANSF -confgvar.TOTALVAR)/confgvar.QTYTRANSF) 
						ELSE ((confGvar.StdCost*confGvar.QtyTransf+confGvar.TotalVar)/confGvar.QtyTransf)-confGvar.StdCost END as VarianceR
				,confgvar.INVTXFER_N,confgvar.TRANSFTBLE,confgvar.CNFGGLLINK,
				-- 02/06/17 VL added functional currency code
				confgvar.STDCOSTPR ,WipCostPR,VariancePR,ROUND(confGvar.TotalVarPR,2) AS TotalVarPR 
				,CASE WHEN SIGN(Confgvar.StdCostPR-ConfgVar.WIPCOSTPR)=SIGN(ConfgVar.VariancePR) THEN (confgvar.STDCOSTPR*confgvar.QTYTRANSF-confgvar.TOTALVARPR)/confgvar.QTYTRANSF 
					ELSE (confgvar.STDCOSTPR*confgvar.QTYTRANSF+confgvar.TOTALVARPR)/confgvar.QTYTRANSF END AS WipCostRPR
				,CASE WHEN SIGN(ConfgVar.StdCostPR-ConfgVar.WipCostPR)=SIGN(ConfgVar.variancePR) 
					THEN confgvar.STDCOSTPR -((Confgvar.STDCOSTPR *CONFGVAR.QTYTRANSF -confgvar.TOTALVARPR)/confgvar.QTYTRANSF) 
						ELSE ((confGvar.StdCostPR*confGvar.QtyTransf+confGvar.TotalVarPR)/confGvar.QtyTransf)-confGvar.StdCostPR END as VarianceRPR
				,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
		from	CONFGVAR 
				-- 02/03/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON CONFGVAR.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON CONFGVAR.FuncFcused_uniq = FF.Fcused_uniq			
				LEFT OUTER JOIN INVENTOR on Confgvar.UNIQ_KEY =Inventor.UNIQ_KEY 
		where	--CAST(ConfgVar.[DATETIME] as DATE) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP:  Removed
				datediff(day,CONFGVAR.[datetime],@lcDateStart)<=0 and datediff(day,CONFGVAR.[datetime],@lcDateEnd)>=0
				and (Confgvar.VARTYPE = '' or CONFGVAR.VARTYPE = 'CONFG') 
		order by part_no,revision
		END
		    
END