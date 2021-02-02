
-- =============================================
-- Author:			Debbie
-- Create date:		11/21/2013
-- Description:		Created for the AP Offset report
-- Reports Using:   apoffset.rpt 
-- Modifications:	
-- 02/07/17 VL	Separate FC and non-FC, also added functional currency code
-- =============================================
CREATE procedure [dbo].[rptApOffset]
	 @lcDateStart smalldatetime = null
	,@lcDateEnd smalldatetime = null
	, @userId uniqueidentifier=null 
as
begin

IF dbo.fn_IsFCInstalled() = 0
	select	SUPINFO.SUPNAME,a.DATE,SUPINFO.SUPID,a.INVNO,a.REF_NO,a.AMOUNT,a.OFFNOTE,a.CGROUP,apmaster.REASON
	from	APOFFSET A,SUPINFO,apmaster
	where	a.UNIQSUPNO = SUPINFO.UNIQSUPNO
			and apmaster.UNIQAPHEAD = A.UNIQAPHEAD
			and cast(a.DATE as Date) between  @lcDateStart AND @lcDateEnd
	order by SUPNAME,DATE,UNIQ_SAVE,CGROUP
ELSE
	select	SUPINFO.SUPNAME,a.DATE,SUPINFO.SUPID,a.INVNO,a.REF_NO,a.AMOUNT,a.OFFNOTE,a.CGROUP,apmaster.REASON, a.AMOUNTFC, a.AMOUNTPR, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	APOFFSET A
	-- 02/03/17 VL changed criteria to get 3 currencies
	INNER JOIN Fcused PF ON A.PrFcused_uniq = PF.Fcused_uniq
	INNER JOIN Fcused FF ON A.FuncFcused_uniq = FF.Fcused_uniq			
	INNER JOIN Fcused TF ON A.Fcused_uniq = TF.Fcused_uniq			
	INNER JOIN SUPINFO ON a.UNIQSUPNO = SUPINFO.UNIQSUPNO
	INNER JOIN apmaster ON apmaster.UNIQAPHEAD = A.UNIQAPHEAD
	where cast(a.DATE as Date) between  @lcDateStart AND @lcDateEnd
	order by SUPNAME,DATE,UNIQ_SAVE,CGROUP

end