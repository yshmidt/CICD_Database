
	--/****** Object:  StoredProcedure [dbo].[rptApCheckCashDisbForecast]    Script Date: 12/21/2015 13:33:14 ******/
	--SET ANSI_NULLS ON
	--GO
	--SET QUOTED_IDENTIFIER ON
	--GO

	-- =============================================
	-- Author:			Debbie 
	-- Create date:		12/21/2015
	-- Description:		Created for the Cach Disbursement Forecast
	-- Reports:			ckrep3.rpt 
	-- Modified:	
	-- 03/21/2016	VL:	Added FC code
	-- 04/08/2016	VL: Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
	-- 02/03/2017	VL: added functional currency fields
	-- =============================================
	CREATE PROCEDURE  [dbo].[rptApCheckCashDisbForecast]

--declare
	@lcDateStart as smalldatetime= null
	,@lcDateEnd as smalldatetime = null
	,@userId uniqueidentifier = null

as
begin

/*SUPPLIER LIST*/	
	-- get list of approved suppliers for this user
	DECLARE @tSupplier tSupplier
	INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';
	--select * from @tSupplier


/*RECORD SELECT SECTION*/
-- 03/21/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	   
	SELECT	cast(A.DUE_DATE as date) as DUE_DATE,S.SUPNAME,A.INVNO,A.INVDATE,A.INVAMOUNT,A.INVAMOUNT - (A.APPMTS +A.DISC_TKN) AS BALAMT,A.UNIQAPHEAD,E.BATCH_DATE,isnull(E.APRPAY,0.00) AS SchdAmt
	FROM	APMASTER A
			INNER JOIN SUPINFO S ON A.UNIQSUPNO = S.UNIQSUPNO
			left outer join (select fk_uniqaphead,Batch_date,is_closed,APRPAY,DATEPAID from	apbatdet D inner join apbatch B on D.batchuniq = B.BATCHUNIQ where IS_CLOSED = 0) E on a.UNIQAPHEAD = E.FK_UNIQAPHEAD
	WHERE	A.INVAMOUNT - (A.APPMTS +A.DISC_TKN) <> 0
			AND A.APSTATUS <> 'Deleted'
			and DATEDIFF(day, @lcDateStart,A.DUE_DATE) >=0 AND DATEDIFF(day,A.DUE_DATE,@lcDateEnd )>=0
			and exists (select 1 from @tSupplier t inner join supinfo s on t.uniqsupno=s.UNIQSUPNO where s.UNIQSUPNO=a.UNIQSUPNO)
	order by DUE_DATE,SUPNAME,invno

	END
ELSE
-- FC installed
	BEGIN
	
	SELECT	cast(A.DUE_DATE as date) as DUE_DATE,S.SUPNAME,A.INVNO,A.INVDATE,A.INVAMOUNT,A.INVAMOUNT - (A.APPMTS +A.DISC_TKN) AS BALAMT,A.UNIQAPHEAD,E.BATCH_DATE,isnull(E.APRPAY,0.00) AS SchdAmt
			,A.INVAMOUNTFC,A.INVAMOUNTFC - (A.APPMTSFC +A.DISC_TKNFC) AS BALAMTFC,isnull(E.APRPAYFC,0.00) AS SchdAmtFC
			-- 02/03/17 VL comment out Currency and added functional currency fields
			--, Fcused.Symbol AS Currency
			,A.INVAMOUNTPR,A.INVAMOUNTPR - (A.APPMTSPR +A.DISC_TKNPR) AS BALAMTPR,isnull(E.APRPAYPR,0.00) AS SchdAmtPR
			,TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	FROM	APMASTER A 
			-- 02/03/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON A.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON A.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON A.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN SUPINFO S ON A.UNIQSUPNO = S.UNIQSUPNO
			left outer join (select fk_uniqaphead,Batch_date,is_closed,APRPAY,DATEPAID,APRPAYFC,APRPAYPR from apbatdet D inner join apbatch B on D.batchuniq = B.BATCHUNIQ where IS_CLOSED = 0) E on a.UNIQAPHEAD = E.FK_UNIQAPHEAD
	WHERE	A.INVAMOUNT - (A.APPMTS +A.DISC_TKN) <> 0
			AND A.APSTATUS <> 'Deleted'
			and DATEDIFF(day, @lcDateStart,A.DUE_DATE) >=0 AND DATEDIFF(day,A.DUE_DATE,@lcDateEnd )>=0
			and exists (select 1 from @tSupplier t inner join supinfo s on t.uniqsupno=s.UNIQSUPNO where s.UNIQSUPNO=a.UNIQSUPNO)
	order by DUE_DATE,SUPNAME,invno

	END
END-- IF FC installed
end