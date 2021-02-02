-- =============================================
-- Author:		Debbie
-- Create date:	10/08/2013
-- Description:	Inventory Cost Variance Detail Report by Wonum or Part_no/Rev
--				in VFP the Inventory Cost (OTHER,USRDF,OVRHD AND LABOR) used to be included into the CONFVAR1 and CONFVAR2.  But in SQL we separated them out into their own.
-- Modified:	09/26/2014 DRP: replaced the Date range filter wiht the DATEDIFF.
-- =============================================
CREATE PROCEDURE [dbo].[rptInvtCostVarDetail] 
	 --Add the parameters for the stored procedure here
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
    where	--CAST(ConfgVar.[DATETIME] as DATE) BETWEEN @lcDateStart and @lcDateEnd	--09/26/2014 DRP: Removed
			datediff(day,confgvar.[datetime],@lcDateStart)<=0 and datediff(day,confgvar.[datetime],@lcDateEnd)>=0
			and CONFGVAR.VARTYPE <> 'CONFG' AND CONFGVAR.VARTYPE <> ''
 order by part_no,revision
		    
END