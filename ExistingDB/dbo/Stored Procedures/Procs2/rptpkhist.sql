


-- =============================================
-- Author:		<Yelena and Debbie> 
-- Create date: <02/01/2012>
-- Description:	<compiles details for the Shipment History Report>
-- Reports:     <used on pkhist.rpt>
-- Modified		01/15/2014 DRP:  added the @userid parameter for WebManex
--				11/03/15 DRP:  Added the @lcCurDate so I could use it later to calculate the MonthToDate,QuarterToDate and YearToDate
--							   Added the /*CUSTOMER LIST*/, made many other changes to get it to work with the QuickView and WebManex reports
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptpkhist]
--declare
@userId uniqueidentifier=null

as
begin 


/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	
		

declare @lcCurDate smalldatetime = null	
	select @lcCurDate = getdate()	--11/03/15 DRP:  Added

-- 07/16/18 VL changed custname from char(35) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
declare @Detail as table (custno char(10),custname char(50),uniq_key char(10),part_no char(35),revision char(8),descript char (45),sMonth numeric(2,0),sYear numeric(4,0),sQuarter numeric(2,0),SHIPPEDQTY numeric(9,2))
;
WITH Shipment AS
	(
	SELECT	plmain.custno,customer.custname,sodetail.uniq_key,isnull (part_no,sodet_desc)as part_no 
			,isnull(inventor.revision,'') as revision,isnull(inventor.DESCRIPT,'') as descript,DATEPART(Month,plmain.SHIPDATE) as sMonth,DATEPART(Year,plmain.SHIPDATE) as sYear,DATEPART(Quarter,plmain.SHIPDATE) as sQuarter,pldetail.SHIPPEDQTY 
	from	PLDETAIL 
			inner join PLMAIN on plmain.PACKLISTNO =PLDETAIL.PACKLISTNO 
			inner join SODETAIL on sodetail.UNIQUELN =pldetail.UNIQUELN 
			inner join CUSTOMER on plmain.CUSTNO = customer.CUSTNO 
			left outer join inventor on sodetail.UNIQ_KEY = inventor.uniq_key
	where	DATEPART(year,shipdate)= DATEPART(year,getdate()) and SHIPDATE <= GETDATE()
			and exists (select 1 from @tCustomer t inner join customer c on t.custno=c.custno where c.custno=plmain.custno)
	)

insert into @Detail
	select	custno,custname,UNIQ_KEY,part_no,revision,DESCRIPT,isnull(sMonth,0),isnull(sYear,0),isnull(sQuarter,0) ,sum(SHIPPEDQTY) as Shipped 
	from	Shipment 
	GROUP BY GROUPING SETS((custno,custname,UNIQ_KEY,part_no,revision,descript,sYear,sMonth ),(custno,custname,UNIQ_KEY,part_no,revision,descript,sYear),(custno,custname,UNIQ_KEY,part_no,revision,descript,sYear,sQuarter))    

--select * from @Detail

select	custno,custname,uniq_key,part_no,revision,descript,sum(case when sQuarter = 0 and sMonth <> 0 and sMonth =  datepart(month,@lcCurDate) then SHIPPEDQTY else 0.00 end) as MTD
		,sum(case when sMonth = 0 and sQuarter <> 0 and sQuarter = datepart(Quarter,@lccurDate) then SHIPPEDQTY else 0.00 end) as QTD
		,sum(case when sMonth = 0 and sQuarter <> 0 then shippedqty else 0.00 end) as YTD
from	@Detail
group by custno,custname,uniq_key,part_no,revision,descript

end
