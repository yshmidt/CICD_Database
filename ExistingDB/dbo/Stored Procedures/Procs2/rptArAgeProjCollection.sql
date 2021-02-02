-- =============================================
-- Author:		Debbie
-- Create date: 10/10/2014
-- Description:	Used on cashrep2   "AR Projected Cash Collection Report"
-- Modified:	At this point in time was created for QuickView only. 
--				01/06/2015 DRP:  Added @customerStatus Filter 
--				03/02/2016 VL:	 Added FC code
--				04/08/2016 VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/11/2017 VL:	 added one more parameter for fn_CalculateFCRateVariance() which is the rate ratio calculated based on functional currency or presentation currency
--				01/13/2017 VL:	 added functional currency fields
-- =============================================
CREATE PROCEDURE [dbo].[rptArAgeProjCollection]


--declare
@lcDateStart as smalldatetime = null
,@lcDateEnd as smalldatetime = null
,@lcCustNo varchar(max) = 'All'
,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
,@userId uniqueidentifier = null


as 
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		
		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END


-- 03/02/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN

	declare @Detail as table (Due_Date date,CustName char(35),InvNo char(10),InvDate  Date,BalAmt numeric(12,2))

	declare @GrpTotal as table(Due_Date date,GroupTotal numeric(12,2),id int not null identity(1,1) primary key)

	/*SELECT STATEMENT*/

		/*compile detail information and assign a primary key to later be used for the Running Total value*/
		insert into @Detail 
		select	cast(DUE_DATE as DATE)as Due_Date,CustName,InvNo,cast(InvDate as date) as InvDate,ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS as BalAmt
		from	ACCTSREC
				inner join CUSTOMER on ACCTSREC.CUSTNO = customer.CUSTNO
		where	ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS <> 0.00
				and ACCTSREC.lPrepay <> 1	
				and 1 = case when ACCTSREC.CUSTNO in (select CUSTNO from @customer) then 1 else 0 end
				and datediff(day,acctsrec.due_date,@lcDateStart)<=0 and datediff(day,acctsrec.due_date,@lcDateEnd)>=0	
		order by DUE_DATE,INVNO

		/*calculate the Group Total per Due Date*/
		insert into @GrpTotal
		select	Due_Date,SUM(BalAmt) as GroupTotal
		from	@Detail
		group by Due_Date
	
		/*calculate the GroupTotal and RunningBal per Due Date*/
		select	d1.Due_Date,d1.CustName,d1.InvNo,d1.InvDate,d1.BalAmt
				,CASE WHEN ROW_NUMBER() OVER(Partition by B1.Due_Date Order by B1.Due_Date)=1 Then B1.GroupTotal ELSE CAST(0.00 as Numeric(20,2)) END AS GroupTotal
				,case when ROW_NUMBER() over(partition by d1.due_Date order by d1.due_date) = 1 then B1.RunningBal else CAST (0.00 as numeric(12,0)) end as RunningBal
		from (select d.Due_Date,d.GroupTotal,(select SUM(b.GroupTotal) from @GrpTotal b where b.id <= a.id) as RunningBal
				from @GrpTotal a inner join @GrpTotal d on a.id = d.id) B1
				inner join @Detail D1 on B1.Due_Date = D1.Due_Date	
	END
ELSE
-- FC installed
	BEGIN
	-- 01/13/17 VL added functional currency fields
	declare @DetailFC as table (Due_Date date,CustName char(35),InvNo char(10),InvDate  Date,BalAmt numeric(12,2),BalAmtFC numeric(12,2), BalAmtPR numeric(12,2), TSymbol char(3), PSymbol char(3),FSymbol char(3))
	-- 01/13/17 VL added functional currency fields
	declare @GrpTotalFC as table(Due_Date date,GroupTotal numeric(12,2),GroupTotalFC numeric(12,2),GroupTotalPR numeric(12,2), TSymbol char(3), PSymbol char(3),FSymbol char(3), id int not null identity(1,1) primary key)

	/*SELECT STATEMENT*/

		/*compile detail information and assign a primary key to later be used for the Running Total value*/
		--03/03/2016 VL update InvTotal and Balamt with latest rate (even it's not showing in report now)
		-- 01/13/17 VL added functional currency fields
		insert into @DetailFC 
		select	cast(DUE_DATE as DATE)as Due_Date,CustName,InvNo,cast(InvDate as date) as InvDate
			,CAST(((ACCTSREC.INVTOTAL-ACCTSREC.ARCREDITS)*dbo.fn_CalculateFCRateVariance(Fchist_key,'F')) as numeric(20,2)) AS BalAmt
			,ACCTSREC.INVTOTALFC-ACCTSREC.ARCREDITSFC as BalAmtFC
			-- 01/13/17 VL added functional currency fields
			,CAST(((ACCTSREC.INVTOTALPR-ACCTSREC.ARCREDITSPR)*dbo.fn_CalculateFCRateVariance(Fchist_key,'P')) as numeric(20,2)) AS BalAmtPR
			,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			--Fcused.Symbol AS Currency
		from	ACCTSREC
			-- 01/13/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON ACCTSREC.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON ACCTSREC.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON ACCTSREC.Fcused_uniq = TF.Fcused_uniq	
				inner join CUSTOMER on ACCTSREC.CUSTNO = customer.CUSTNO
		where	ACCTSREC.INVTOTALFC-ACCTSREC.ARCREDITSFC <> 0.00
				and ACCTSREC.lPrepay <> 1	
				and 1 = case when ACCTSREC.CUSTNO in (select CUSTNO from @customer) then 1 else 0 end
				and datediff(day,acctsrec.due_date,@lcDateStart)<=0 and datediff(day,acctsrec.due_date,@lcDateEnd)>=0	
		order by TF.Symbol,DUE_DATE,INVNO

		/*calculate the Group Total per Due Date*/
		-- 01/13/17 VL added functional currency fields
		insert into @GrpTotalFC
		select	Due_Date,SUM(BalAmt) as GroupTotal, SUM(BalAmtFC) as GroupTotalFC, SUM(BalAmtPR) as GroupTotalPR, TSymbol,PSymbol,FSymbol
		from	@DetailFC
		group by TSymbol,PSymbol,FSymbol,Due_Date
	
		/*calculate the GroupTotal and RunningBal per Due Date*/
		-- 01/13/17 VL added functional currency fields
		select	d1.Due_Date,d1.CustName,d1.InvNo,d1.InvDate,d1.BalAmt
				,CASE WHEN ROW_NUMBER() OVER(Partition by B1.TSymbol,B1.Due_Date Order by B1.TSymbol,B1.Due_Date)=1 Then B1.GroupTotal ELSE CAST(0.00 as Numeric(20,2)) END AS GroupTotal
				,case when ROW_NUMBER() over(partition by d1.TSymbol,d1.due_Date order by d1.TSymbol,d1.due_date) = 1 then B1.RunningBal else CAST (0.00 as numeric(12,0)) end as RunningBal
				,d1.BalAmtFC
				,CASE WHEN ROW_NUMBER() OVER(Partition by B1.TSymbol,B1.Due_Date Order by B1.TSymbol,B1.Due_Date)=1 Then B1.GroupTotalFC ELSE CAST(0.00 as Numeric(20,2)) END AS GroupTotalFC
				,case when ROW_NUMBER() over(partition by d1.TSymbol,d1.due_Date order by d1.TSymbol,d1.due_date) = 1 then B1.RunningBalFC else CAST (0.00 as numeric(12,0)) end as RunningBalFC
				,d1.BalAmtPR
				,CASE WHEN ROW_NUMBER() OVER(Partition by B1.TSymbol,B1.Due_Date Order by B1.TSymbol,B1.Due_Date)=1 Then B1.GroupTotalPR ELSE CAST(0.00 as Numeric(20,2)) END AS GroupTotalPR
				,case when ROW_NUMBER() over(partition by d1.TSymbol,d1.due_Date order by d1.TSymbol,d1.due_date) = 1 then B1.RunningBalPR else CAST (0.00 as numeric(12,0)) end as RunningBalPR
		-- 01/03/17 VL re-write this part to include presentation currency fields
		--		,d1.Currency
		--from (select d.Due_Date,d.GroupTotal,(select SUM(b.GroupTotal) from @GrpTotalFC b where b.id <= a.id and b.currency = a.currency) as RunningBal
		--		,d.GroupTotalFC,(select SUM(b.GroupTotalFC) from @GrpTotalFC b where b.id <= a.id and b.currency = a.currency) as RunningBalFC, d.Currency
		--		from @GrpTotalFC a inner join @GrpTotalFC d on a.id = d.id) B1
		--		inner join @DetailFC D1 on (B1.Due_Date = D1.Due_Date AND B1.Currency = D1.Currency	)
		--ORDER BY Currency, Due_date
				,d1.TSymbol,d1.PSymbol,d1.FSymbol
		from (select d.Due_Date,d.GroupTotal,(select SUM(b.GroupTotal) from @GrpTotalFC b where b.id <= a.id and b.TSymbol = a.TSymbol) as RunningBal
				,d.GroupTotalFC,(select SUM(b.GroupTotalFC) from @GrpTotalFC b where b.id <= a.id and b.TSymbol = a.TSymbol) as RunningBalFC
				,d.GroupTotalPR,(select SUM(b.GroupTotalPR) from @GrpTotalFC b where b.id <= a.id and b.PSymbol = a.PSymbol) as RunningBalPR 
				,d.TSymbol,d.PSymbol,d.FSymbol
				from @GrpTotalFC a inner join @GrpTotalFC d on a.id = d.id) B1
				inner join @DetailFC D1 on (B1.Due_Date = D1.Due_Date AND B1.TSymbol = D1.TSymbol	)
		ORDER BY TSymbol, Due_date
	END
END -- if FC installed

end