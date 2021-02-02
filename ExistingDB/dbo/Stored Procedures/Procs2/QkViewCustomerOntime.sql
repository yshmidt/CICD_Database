-- =============================================
-- Author:		David Sharp
-- Create date: 6/14/2013
-- Description:	gets customer ontime information
-- 09/23/13 DS Refined the process for determining the last shipment or due date so as not to repeat the same shipments/due dates
-- 09/26/13 DS Added on-time percentage and Summary row 
-- 11/11/13 DS Added column for Sales Type and other column adjustments for presentation.
-- 11/12/13 DS Added @appliedUniqLn to ensure a shipment is not counted more than once.
-- 01/03/14 DS revised handling for when a line is fully shipped
-- 01/22/14 DS added handling for when the due qty is 0 from the start
-- 01/23/14 DS skip due date rows where nothing is scheduled
-- 01/24/14 DS MAJOR overhaul.  Totally new approach.  It now has a result for ALL shipments in the date range even if the SO line item has no schdule
-- 01/27/14 DS Switched to FAST FORWARD and using a Temp Table
-- 05/11/17 DRP:  Added <<where sp.RECORDTYPE = 'P'>> because in the situation where there were extra pricing lines it would duplicate the Shipqty and get incorrect totals.
--  The date range that was in place was not working properly  <<WHERE m.SHIPDATE BETWEEN @dateStart AND @dateEnd>> as been replaced with <<where datediff(day,m.Shipdate,@dateStart)<=0 and datediff(day,m.Shipdate,@dateEnd)>=0>>
--  also needed to add the /*CUSTOMER LIST*/ to the procedure. 
-- 11/27/17 YS drop temp table at the beginning and the end of the SP. 
-- 02/27/18 YS rewrote the SP to use windowes rollup functions. The old code was working too slow
--- 02/28/18 YS change part of CTE to use table variables
-- 09/14/18 VL Changed pctOnTime from numeric(5,2) to numeric(6,2) to avoid arithmetic overflow error.  Also added CASE WHEN for pctOnTime if percent exceeds 100, use 100
-- 10/03/18 Satyawan H. changed size of all numeric of #OnTime to numeric(20,7) 
-- 10/04/18 Satyawan H. changed Letter case of 'shipmentCnt' to 'shipMentCnt' in all over the SP 
-- 05/23/19 VL the "shipdate" from plmain and "dueDate" from Due_dts.Shipdate caused confusion for cusotmers, so I named it "PkShipDate" and "SoShipDate"
-- 05/24/19 VL Added Due_dts.Due_date, API used this field to compare with commitdate in their internal program. Zendesk#5388
-- 12/24/19 VL added date range critria so the PK oustside of range are not included
-- =============================================
CREATE PROCEDURE [dbo].[QkViewCustomerOntime] 
	-- Add the parameters for the stored procedure here
--declare
	@dateStart date =  null, 
	@dateEnd date = null,
	@type varchar(20)='detail',
	@userId uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

 
/*CUSTOMER LIST*/	--05/11/17 DRP:  added		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer


    -- Insert statements for procedure here
	--11/27/17 YS added check if object exists and drop
	if OBJECT_ID('tempdb..#OnTime') is not null
		drop table #OnTime;

	if OBJECT_ID('tempdb..#OnTime') is not null
		drop table #OnTime;
	if OBJECT_ID('tempdb..#SummaryInfo') is not null
		drop table #SummaryInfo;

	--CREATE TABLE #OnTime (
	--CustName nvarchar(35) NULL,
	--SONO nvarchar(10) NULL,
	--packlistno nvarchar(10) NULL,
	--Uniqueln nvarchar(10) NULL,
	--Uniq_key char(10) null,
	--shipDate smalldatetime null,
	--SchdDate smalldatetime null,
	--SchdQty numeric(9,2) null,
	--Act_shp_qt numeric(9,2) null,
	--QtyApplied numeric(9,2) null,
	--BalanceQty numeric(9,2) null,
	--DUEDT_UNIQ varchar(10) null,
	--commitDate smalldatetime null,
	--daysLate int null,
	--SALETYPEID nvarchar(20) null,
	--QtyOnTime numeric(9,2) null,
	--QtyLate numeric(9,2) null,
	--pctLate numeric(5,2) NULL ,
	---- 09/14/18 VL Changed pctOnTime from numeric(5,2) to numeric(6,2) to avoid arithmetic overflow error
	----pctOnTime numeric(5,2) NULL ,
	--pctOnTime numeric(6,2) NULL ,
	--shipMentCnt int null,
	--ontimebool int null,
	--nRecord int null,
	--nSort int null,
	--)

	-- 10/03/18 Satyawan H. changed size of all numeric of #OnTime to numeric(20,7) 
	CREATE TABLE #OnTime ( 
	CustName nvarchar(35) NULL,
	SONO nvarchar(10) NULL,
	packlistno nvarchar(10) NULL,
	Uniqueln nvarchar(10) NULL,
	Uniq_key char(10) null,
	shipDate smalldatetime null,
	SchdDate smalldatetime null,
	SchdQty numeric(20,7) null,
	Act_shp_qt numeric(20,7) null,
	QtyApplied numeric(20, 7) null,
	BalanceQty numeric(20, 7) null,
	DUEDT_UNIQ varchar(10) null,
	commitDate smalldatetime null,
	-- 05/24/19 VL added Due_date
	Due_date smalldatetime null,
	daysLate int null,
	SALETYPEID nvarchar(20) null,
	QtyOnTime numeric(20, 7) null,
	QtyLate numeric(20, 7) null,
	pctLate numeric(20,7) NULL ,
	pctOnTime numeric(20,7) NULL ,
	shipMentCnt int null,
	ontimebool int null,
	nRecord int null,
	nSort int null,
	)


	
	---use shipped date as a base to our date range
	--- 02/28/18 YS use table variable
	declare @SalesLines Table (uniqueln char(10),sono char(10))
	--;with 
	--SalesLines as    
	--(
	INSERT INTO @SalesLines
			select UNIQUELN,sono
			from plmain  inner join PLDETAIL on plmain.PACKLISTNO=pldetail.PACKLISTNO
			where convert(date,SHIPDATE) between @dateStart and @dateEnd
			and plmain.sono<>''
			and exists (select 1 from @tCustomer where [@tCustomer].custno=plmain.CUSTNO)
			-- test 
			--and (sono like '%20022326' 
			--OR sono like '%20022332') 
			----or sono like '%20022334') 
			
	--),
	--- 02/28/18 YS use table variable
	declare @plShip TABLE (sono char(10),SHIPDATE smalldatetime, UNIQUELN char(10),PACKLISTNO char(10),SHIPPEDQTY numeric (9,2),
		 RunningShippedQty numeric (15,2),custno char(10),CUSTNAME varchar(50))
	--plShip
	--as
	--(
	insert into @plShip
		select plmain.sono,plmain.SHIPDATE, pldetail.UNIQUELN,pldetail.PACKLISTNO,pldetail.SHIPPEDQTY,
		SUM(SHIPPEDQTY) OVER( partition by sono,uniqueln ORDER BY ShipDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS RunningShippedQty,
		plmain.custno,customer.CUSTNAME
		from pldetail inner join plmain on pldetail.packlistno=plmain.packlistno
		inner join @tCustomer customer on plmain.CUSTNO=customer.CUSTNO
		where  exists (select 1 from @SalesLines  SalesLines where SalesLines.sono=PLMAIN.sono and SalesLines.UNIQUELN=PLDETAIL.UNIQUELN)
		---02/27/18 YS filter out 0 shipped qty
		and pldetail.SHIPPEDQTY<>0.00
	--),
	--- 02/28/18 YS use table variable
	-- 05/24/19 VL added Due_date
	declare @sDue Table 
	(
		SchdDate smalldatetime,UNIQUELN char(10),ACT_SHP_QT numeric(9,2),SchdQty numeric(9,2),duedt_uniq char(10),commitDate smalldatetime, Due_date smalldatetime,
		RunningDueShippedQty numeric(15,2)
	)
	--SDue as
	--(
	insert into @sDue
	-- 05/24/19 VL added Due_date
		select due_dts.SHIP_DTS as SchdDate,due_dts.UNIQUELN,due_dts.ACT_SHP_QT ,DUE_DTS.ACT_SHP_QT+DUE_DTS.Qty as SchdQty,duedt_uniq,due_dts.COMMIT_DTS as commitDate, due_dts.DUE_DTS AS Due_date,
		SUM(ACT_SHP_QT) OVER(partition by sono,uniqueln ORDER BY SHIP_DTS ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS RunningDueShippedQty
		from due_dts  
		where  ACT_SHP_QT<>0 and 
		exists (select 1 from @SalesLines SalesLines where SalesLines.uniqueln=DUE_DTS.UNIQUELN and SalesLines.SONO=DUE_DTS.SONO)
	--),
	;with
	actionrows AS 
	(
	-- 05/24/19 VL added Due_date
	SELECT t.sono,t.custno,t.custname, t.packlistno,t.uniqueln,t.shipDate, g.SchdDate, t.ShippedQty AS TransQty, g.Act_shp_qt, g.SchdQty,g.DUEDT_UNIQ ,g.commitDate,g.Due_date,
          t.RunningShippedQty AS TransTotQty, g.RunningDueShippedQty AS TotDueShippedQty,
          LAG(t.RunningShippedQty, 1, 0) OVER(partition by t.uniqueln ORDER BY t.ShipDate, g.SchdDate) AS PrevTransQty,
          LAG(g.RunningDueShippedQty, 1, 0) OVER(partition by t.uniqueln ORDER BY t.ShipDate, g.SchdDate) AS PrevDueSchippedQty,
		  LEAD(g.RunningDueShippedQty,1,0) OVER (partition BY t.uniqueln ORDER BY  t.ShipDate, g.SchdDate) AS nextRunningDueShippedQty,
		  ROW_NUMBER() OVER (Partition by t.Packlistno,t.UniqueLn order by g.SchdDate) as n
	FROM   @plShip t
	CROSS JOIN @SDue g 
	WHERE t.uniqueln=g.uniqueln and  
	t.RunningShippedQty - t.ShippedQty < g.RunningDueShippedQty
    AND  g.RunningDueShippedQty-g.Act_shp_qt < t.RunningShippedQty
	)
--- test
--select * from actionrows
	,Distribute
	as
	(
	-- 05/24/19 VL added Due_date
	select sono,custno,custname, packlistno,uniqueln,shipDate, SchdDate, TransQty, Act_shp_qt, SchdQty,DUEDT_UNIQ ,commitDate, Due_date,
          TransTotQty, TotDueShippedQty,
		  PrevTransQty,PrevDueSchippedQty,nextRunningDueShippedQty,
		  CASE WHEN PrevTransQty<PrevDueSchippedQty
				THEN CASE WHEN TransQty<PrevDueSchippedQty-PrevTransQty THEN TransQty
			     ELSE PrevDueSchippedQty-PrevTransQty
			 END
			 WHEN  PrevTransQty	>PrevDueSchippedQty
			 THEN CASE WHEN Act_shp_qt<PrevTransQty-PrevDueSchippedQty and nextRunningDueShippedQty>0
						THEN Act_shp_qt
						ELSE PrevTransQty-PrevDueSchippedQty
			END
			ELSE CASE WHEN TransQty<Act_shp_qt
					THEN TransQty
					WHEN nextRunningDueShippedQty=0 and PrevDueSchippedQty=0
					THEN TransQty ELSE Act_shp_qt END
			END as QtyApplied
		from actionrows 
	)
--- test only
---select * from Distribute
--select * from plship where UNIQUELN not in (select UNIQUELN from Distribute)
	,onTimeFinal
	as
	(
	-- 05/24/19 VL added Due_date
	SELECT custname, Distribute.sono,packlistno,Distribute.uniqueln,shipDate,SchdDate,
		SchdQty,Act_shp_qt,QtyApplied,
		0.00 as BalanceQty,
		DUEDT_UNIQ,commitDate,DUE_Date,
		datediff(day,SchdDate,SHIPDATE) as daysLate,SALETYPEID,
		QtyOnTime = CASE WHEN datediff(day,SchdDate,SHIPDATE)<=0 THEN QtyApplied ELSE 0 END,
		QtyLate=CASE WHEN datediff(day,SchdDate,SHIPDATE)>0 THEN QtyApplied ELSE 0 END,
		pctLate= 100*((CASE WHEN SchdQty =0 THEN QtyApplied
						WHEN datediff(day,SchdDate,SHIPDATE)>0 THEN QtyApplied
						ELSE 0.00 END)/SchdQty),
		--convert(numeric(5,2),0.00) as pctOnTime,
		-- 09/14/18 VL added CASE WHEN for pctOnTime if percent exceeds 100, use 100
		--pctOnTime= 100*((CASE WHEN SchdQty =0 THEN QtyApplied
		--				WHEN datediff(day,SchdDate,SHIPDATE)<=0 THEN QtyApplied
		--				ELSE 0.00 END)/SchdQty),
		pctOnTime= CASE WHEN (100*((CASE WHEN SchdQty =0 THEN QtyApplied
						WHEN datediff(day,SchdDate,SHIPDATE)<=0 THEN QtyApplied
						ELSE 0.00 END)/SchdQty))<=100
						THEN 
						(100*((CASE WHEN SchdQty =0 THEN QtyApplied
						WHEN datediff(day,SchdDate,SHIPDATE)<=0 THEN QtyApplied
						ELSE 0.00 END)/SchdQty))
						ELSE 100 END,
		--count(*) over (partition by DUEDT_UNIQ) as shipMentCnt,
		1 as shipMentCnt,
		CASE WHEN datediff(day,SchdDate,SHIPDATE)<=0 THEN 1 ELSE 0 END ontimebool,
		ROW_NUMBER() OVER (partition by DUEDT_UNIQ order by schdDate) as nRecord
	FROM Distribute INNER JOIN SOPRICES sp ON Distribute.UNIQUELN=sp.UNIQUELN and sp.RECORDTYPE='P'	
		-- 12/24/19 VL added date range critria so the PK oustside of range are not included
		WHERE CONVERT(date,SHIPDATE) between @dateStart and @dateEnd
	UNION
	-- 05/24/19 VL added Due_date
	SELECT CustName,plShip.Sono,Packlistno,plShip.UNIQUELN,ShipDate,ShipDate as SchdDate,SHIPPEDQTY as SchdQty,
		SHIPPEDQTY as Act_shp_qt,SHIPPEDQTY as QtyApplied,0.00 as BalanceQty,
		null as duedt_uniq,
		null as commitDate, null AS Due_date,
		0 as daysLate ,SALETYPEID,SHIPPEDQTY as QtyOnTime,0 as QtyLate,
		0.00 as pctLate,100.00 as pctOnTime,
		1 as shipMentCnt,1 as onTimeBool,
		1 as nRecord
	FROM @plShip plShip INNER JOIN SOPRICES sp ON plship.UNIQUELN=sp.UNIQUELN and sp.RECORDTYPE='P'	
	where not exists (select 1 from Distribute where Distribute.UNIQUELN=plShip.UNIQUELN)
		-- 12/24/19 VL added date range critria so the PK oustside of range are not included
		AND CONVERT(date,SHIPDATE) between @dateStart and @dateEnd
	) 
	INSERT INTO #ontime 
		(CustName ,
		 SONO ,
		 packlistno ,
		 Uniqueln ,
		 Uniq_key,
		 shipDate,
		 SchdDate ,
		 SchdQty,
		 Act_shp_qt ,
		 QtyApplied ,
		 BalanceQty,
		 DUEDT_UNIQ ,
		 commitDate ,
		 -- 05/24/19 VL added Due_date
		 Due_date,
		 daysLate ,
		 SALETYPEID ,
		 QtyOnTime ,
		 QtyLate ,
		 pctLate ,
		 pctOnTime ,
		 shipMentCnt ,
		 ontimebool ,
		 nRecord ,
		 nSort) 
	select CustName ,
		 t.SONO ,
		 packlistno ,
		 t.Uniqueln ,
		 sodetail.Uniq_key,
		 shipDate,
		 SchdDate ,
		 SchdQty,
		 Act_shp_qt ,
		 QtyApplied ,
		 BalanceQty,
		 DUEDT_UNIQ ,
		 commitDate ,
		 Due_date,
		 daysLate ,
		 SALETYPEID ,
		 QtyOnTime ,
		 QtyLate ,
		 pctLate ,
		 pctOnTime ,
		 shipMentCnt ,
		 ontimebool ,
		 nRecord ,
		 row_number() over (order by shipDate) as nSort 
	from  ontimeFinal T left outer join sodetail on t.UNIQUELN=sodetail.UNIQUELN

	--- get summary info using ROLLUP
	SELECT custname,sono, uniqueln,
		sum(QtyLate) sum_Qtylate,sum(QtyOntIme) as sum_QtyOnTime,
		SUM(case when nrecord=1 then SchdQty else 0 end) sum_schd,sum(qtyapplied) as sum_appl,
		SUM(case when nrecord=1 then SchdQty else 0 end)-sum(qtyapplied) as BalanceQty,
		sum(qtyapplied*daysLate)/sum(qtyapplied) as weightedDays,
		COUNT(*) as shipMentCnt,sum(ontimeBool) as ontimebool,
		row_number() OVER (partition by custname order by sono) as norder
		INTO #SummaryInfo
	FROM #OnTime
	GROUP BY custname,sono,Uniqueln
	WITH ROLLUP

---test
--select * from #SummaryInfo
--select * from #OnTime

	--- add totals from summary to display at the top of the result
	--- remove summary by customer and sales order for now
	
	INSERT INTO #OnTime (custname,pctLate,pctOnTime,shipMentCnt,ontimebool,qtyLate,qtyOntime,
	schdQty,QtyApplied,BalanceQty)
	-- if custname is null this is Total for all the records
	SELECT ISNULL(CustName,'Total') as custName,
	----- if sono is null but custname is not - this is total for the customer
	--CASE WHEN Custname is null then ''
	--	WHEN SONO IS NULL THEN 'Cust Total' ELSE SONO END as SONO,
	----- if sono is not null nut uniqln is null - total for the sales order
	--CASE WHEN SONO is null then '' when uniqueln is null then 'SO Total' else '' end as Uniqueln,
	sum_Qtylate/sum_schd*100 as PctLate,sum_QtyOnTime/sum_schd*100 as PctOnTime,shipMentCnt,ontimebool,
	sum_Qtylate,sum_QtyOnTime,
	sum_schd,sum_appl,sum_schd-sum_appl
	from #SummaryInfo as SummaryInfo where 
	--sono is null or 
	custname is null 
	--or UNIQUELN is null
	
	IF @type = 'detail' 

		-- 05/23/19 VL the "shipdate" from plmain and "dueDate" from Due_dts.Shipdate caused confusion for cusotmers, so I named it "PkShipDate" and "SoShipDate"
		--select custname,sono,packlistno,i.part_no,i.revision,shipdate,commitdate,schdDate as dueDate,schdQty as dueQty,QtyApplied as ShipQty,
		-- 05/24/19 VL added Due_date as SoDue_date
		select custname,sono,packlistno,i.part_no,i.revision,shipdate AS PKShipDate,commitdate,due_date AS SODue_date,schdDate as SOShipDate,schdQty as dueQty,QtyApplied as ShipQty,
			case when custname ='total' then BalanceQty
			when nRecord is not null and
			nRecord=1 then schdQty-QtyApplied
			else schdQty-(qtyapplied+ LAG(QtyApplied,1,0) OVER (partition BY duedt_uniq ORDER BY  ShipDate, SchdDate)) end AS Balance,
			--LEAD(QtyApplied,1,0) OVER (partition BY duedt_uniq ORDER BY  ShipDate, SchdDate) AS nextQtyApplied,
			--LAG(QtyApplied,1,0) OVER (partition BY duedt_uniq ORDER BY  ShipDate, SchdDate) AS priorQtyApplied,
			QtyOnTime,QtyLate,pctOnTime as pctQtyOnTime,pctLate as PctQtyLate,
			pctOntime=convert(numeric(15,2),ontimeBool)/convert(numeric(15,2),shipMentCnt)*100,
			daysLate,t.SALETYPEID,shipMentCnt,ontimebool,Uniqueln,DUEDT_UNIQ,t.uniq_key,nsort,nrecord
			from #OnTime T LEFT OUTER JOIN Inventor I on t.Uniq_key=i.UNIQ_KEY
			order by nsort

	IF @type = 'bySO' 
		select CustName,Sono,Sum_schd as DueTotalQty,sum_appl as TotalShipped,
		sum_QtyOnTime as TotalQtyOnTime, sum_Qtylate as TotalQtyLate,weightedDays,
		shipMentCnt,ontimebool as onTimeCnt
		from #SummaryInfo where sono  is not null and uniqueln is null order by sono

	IF @type = 'byCustomer' 	
		select CustName,Sum_schd as DueTotalQty,sum_appl as TotalShipped,
		sum_QtyOnTime as TotalQtyOnTime, sum_Qtylate as TotalQtyLate,weightedDays,
		shipMentCnt,ontimebool as onTimeCnt
		from #SummaryInfo where custname  is not null and sono is null order by sono

		---cleanup 
	if OBJECT_ID('tempdb..#OnTime') is not null
		drop table #OnTime;
			if OBJECT_ID('tempdb..#SummaryInfo') is not null
		drop table #SummaryInfo;
END