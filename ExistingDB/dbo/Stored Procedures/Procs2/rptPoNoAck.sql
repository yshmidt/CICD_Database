
-- =============================================
-- Author:		Debbie
-- Create date: 04/05/2012
-- Description:	This Stored Procedure was created for the PO's Without Supplier Acknowledgement report
-- Reports Using Stored Procedure:  ponoack.rpt
-- Modified:	09/24/2014 DRP:  Added @lcSort and @userId to work with the Quickviews
--								Declared the @Detail table . . . Added the Supplier List to properly display Suppliers based off of the UserId
--								Added section at the end that will determine how the data is sorted for the results that are displayed. 
--				12/12/14 DS Added supplier status filter
-- 07/16/18 VL changed supname from char(30) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptPoNoAck]

	@lcSort char (25) = 'Supplier'	--Supplier,Po Date or Earliest Schedule Date
	,@userId uniqueidentifier=null
	,@supplierStatus varchar(20) = 'All'
 
as
begin

-- 07/16/18 VL changed supname from char(30) to char(50)
Declare @Detail As Table (SupName char(50),Ponum char(15),conum numeric(3,0),PoStatus char(8),PoDate smalldatetime,uniqsupno char(10),FirstSchdDate smalldatetime)

/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus ;
insert into @tSupno  select UniqSupno from @tSupplier


;
with zPoNoAck as 
	(
	select	supinfo.SUPNAME,pomain.PONUM,CONUM,POSTATUS,PODATE,supinfo.UNIQSUPNO
	from	POMAIN,SUPINFO
	where	(pomain.POSTATUS='OPEN' OR POMAIN.POSTATUS = 'NEW' OR POMAIN.POSTATUS = 'EDITING')
			AND POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO
			AND POACKNDOC = ''
			and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
	)

insert into @Detail	
select		zPoNoAck.*,min(poitschd.schd_date) as FirstSchdDate
from		zPoNoAck
			left outer join poitems on zPoNoAck.PONUM = poitems.PONUM
			left outer join POITSCHD on poitems.UNIQLNNO = poitschd.UNIQLNNO
group by	zPoNoAck.PONUM,CONUM,POSTATUS,PODATE,SUPNAME,UNIQSUPNO	

if (@lcSort = 'Supplier')
	Begin
		select * from @Detail order by	Supname,ponum
	End
else if (@lcSort = 'PO Date')
	Begin
		select * from @Detail order by	PoDate,SupName,Ponum
	End
else if (@lcSort = 'Earliest Schedule Date')
	Begin
		select * from @Detail order by	FirstSchdDate,SupName,Ponum
	End

/*09/24/2014 DRP:  Removed the below section and replaced by the above*/
--;
--with zPoNoAck as 
--	(
--	select	pomain.PONUM,CONUM,POSTATUS,PODATE,supinfo.SUPNAME,supinfo.UNIQSUPNO
--	from	POMAIN,SUPINFO
--	where	(pomain.POSTATUS='OPEN' OR POMAIN.POSTATUS = 'NEW' OR POMAIN.POSTATUS = 'EDITING')
--			AND POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO
--			AND POACKNDOC = ''
--	)


--select		zPoNoAck.*,min(poitschd.schd_date) as FirstSchdDate
--from		zPoNoAck
--			left outer join poitems on zPoNoAck.PONUM = poitems.PONUM
--			left outer join POITSCHD on poitems.UNIQLNNO = poitschd.UNIQLNNO
--group by	zPoNoAck.PONUM,CONUM,POSTATUS,PODATE,SUPNAME,UNIQSUPNO
/*09/24/2014 end of removal*/
end