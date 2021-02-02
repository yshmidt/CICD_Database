

-- =============================================
-- Author:		<Debbie>
-- Create date: <01/30/2012,>
-- Description:	<Compiles the details for the Shipping Report by Customer>
-- Used On:     <Crystal Report {PkByCust.rpt}>
-- Modified:	DRP 07/10/2012:  It was requested by a customer that we add the RMA indicator to the report for additional reference.
--				08/12/2013 DRP:  Per Request of a customer and provide PO for changes we have added the following fields to the results.(plmain.FOB,plmain,Shipcharge,sodetail.prjunique,pjctmain.prjnumber and plmain.pack_foot )
--				01/15/2014 DRP:  added the @userid parameter for WebManex
--				01/06/2015 DRP:  Changed @lcCust to @lcCustNo varchar(max).  Added the /*CUSTOMER LIST*/ in order to work with the Cloud parameters.   replaced the Date range filter wiht the DATEDIFF.
--								 Added the customerStatus filter
-- 11/19/19 VL Added Territory, request by Laritech, zendesk#5852 
-- =============================================
CREATE PROCEDURE [dbo].[rptPkByCustWM]

--declare
		@lcCustNo as varchar (max) = 'All'
		,@lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		,@customerStatus char(8)='All'
		,@userId uniqueidentifier= null
as
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerstatus ;

		IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
			insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')
					where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)
		ELSE

		IF  @lcCustNo='All'	
		BEGIN
			INSERT INTO @Customer SELECT CustNo FROM @tCustomer
		END


/*SELECT STATEMENT*/
--DRP 07/10/2012:  Added the somain.is_rma at the end of the select statement as requested by users. 
SELECT	plmain.PACKLISTNO,plmain.CUSTNO,CUSTNAME,plmain.SONO,SHIPDATE,somain.pono,plmain.SHIPVIA,plmain.WAYBILL,plmain.LINKADD,SHIPTO
		,ISNULL(cast(sodetail.line_no as CHAR (10)),cast(PLDETAIL.uniqueln as CHAR (10))) as Line_No
		,isnull(sodetail.uniq_key,space(10))as Uniq_key
		,isnull(inventor.PART_NO,SPACE(25)) as PartNO,ISNULL(inventor.revision,space(8)) as Rev,ISNULL(cast(inventor.descript as CHAR(45)),CAST(pldetail.cdescr as CHAR(45))) as Descript
		,isnull(sodetail.ORD_QTY,cast (0.00 as numeric(12,2))) as Ord_qty,pldetail.SHIPPEDQTY,case when somain.IS_RMA = 1 then 'RMA' else '' end as IsRMA
		,plmain.FOB,plmain.SHIPCHARGE,isnull(sodetail.PRJUNIQUE,'')as prjunique,isnull(PRJNUMBER,'') as prjnumber,plmain.PACK_FOOT
		-- 11/19/19 VL Added Territory, request by Laritech, zendesk#5852
		,TERRITORY
		
FROM	PLMAIN
		inner join CUSTOMER on plmain.CUSTNO = customer.CUSTno
		left outer join SOMAIN on plmain.SONO = somain.SONO
		inner join SHIPBILL on plmain.LINKADD = shipbill.LINKADD
		inner join PLDETAIL on plmain.PACKLISTNO = pldetail.PACKLISTNO
		left outer join SODETAIL on pldetail.UNIQUELN = sodetail.UNIQUELN
		left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY
		left outer join PJCTMAIN on sodetail.PRJUNIQUE = PJCTMAIN.PRJUNIQUE
		
where	plmain.PRINTED = 1
		and 1 = case when customer.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end
		and datediff(day,plmain.shipdate,@lcDateStart)<=0 and datediff(day,plmain.shipdate,@lcDateEnd)>=0


	
end		