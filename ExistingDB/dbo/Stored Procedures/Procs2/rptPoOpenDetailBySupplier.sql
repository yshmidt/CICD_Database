
-- =============================================
-- Author:		Debbie
-- Create date: 03/23/2012
-- Description:	This Stored Procedure was created for the Open Purchase Order Detail by Supplier
-- Reports Using Stored Procedure:  podetlsu.rpt
-- Modified:	09/24/2014 DRP:  Added @lcUniqSupno and @userId
--				Used On and Shortages used to be pulled into the reports as subreports individually.  I have created Functions (fnUsedOn and fnShortage) and implemented them into the select statement below.	
--				Added the Supplier List so that it works with the UserId.
--				replaced the Date range filter wiht the DATEDIFF
--				12/12/14 DS Added supplier status filter
--				02/26/16 VL added FC code
--				04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 09/07/17 VL added Supname and order by it
-- =============================================
CREATE PROCEDURE [dbo].[rptPoOpenDetailBySupplier]

	@lcDateStart as smalldatetime= null
	,@lcDateEnd as smalldatetime = null
	,@lcUniqSupNo as varchar(max) = 'All'   
	,@userId uniqueidentifier = null
		--,@lcSup as varchar (35) = '*'		--09/24/2014 DRP:  removed this parameter,replaced by @lcUniqSupNo
	,@supplierStatus varchar(20) = 'All'
		
AS
BEGIN


/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus;

IF @lcUniqSupNo<>'All' and @lcUniqSupNo<>'' and @lcUniqSupNo is not null
	insert into @tSupNo  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',') WHERE cast(ID as char(10)) IN (SELECT UniqSupno from @tSupplier)
ELSE
	BEGIN
		IF @lcUniqSupNo='All'
		insert into @tSupno  select UniqSupno from @tSupplier
	END				


-- 02/24/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	-- 09/07/17 VL added Supname
	select	Supname,POMAIN.PONUM,CONUM,BUYER,ITEMNO,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
			,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
			,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT,poitems.PARTMFGR, Poitems.ORD_QTY,poitems.recv_qty,poitems.REJ_QTY,poitems.ord_qty-poitems.acpt_qty as BalanceQty
			,poitems.COSTEACH,cast(STUFF((SELECT ','+convert( char(10),PS.SCHD_DATE,101) + ' ('+cast (SCHD_QTY as varchar(max))+ '/'+ cast(balance as varchar(max))+')'
											FROM POITSCHD PS 
											where PS.UNIQLNNO =Poitems.UNIQLNNO 
											ORDER BY SCHD_DATE FOR XML path('')),1,1,'') as varchar(Max)) as Schd 
			,cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,5) as numeric (20,2)) as PoBalAmt,poitems.UNIQ_KEY
			,isnull(dbo.fnUsedOn(poitems.uniq_key),'') as UsedOn 
			,isnull(dbo.fnShortage(poitems.uniq_key),'') as Shortages
		
		
	from	POMAIN
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY

		
	where	pomain.postatus = 'OPEN'
			and poitems.LCANCEL <> 1
			and POITEMS.ORD_QTY-poitems.ACPT_QTY <> 0.00
			--and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end	--09/24/2014 DRP:  removed
			and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			--and podate>=@lcDateStart AND podate<@lcDateEnd+1	--09/24/2014 DRP:  replaced with the DATEDIFF below
			and DATEDIFF(Day,podate,@lcDateStart)<=0 AND DATEDIFF(Day,podate,@lcDateEnd)>=0
			-- 09/07/17 VL added order by supname
			ORDER BY Supname
	END
ELSE
-- FC installed
	BEGIN
	-- 09/07/17 VL added Supname
	select	Supname,POMAIN.PONUM,CONUM,BUYER,ITEMNO,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
			,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
			,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT,poitems.PARTMFGR, Poitems.ORD_QTY,poitems.recv_qty,poitems.REJ_QTY,poitems.ord_qty-poitems.acpt_qty as BalanceQty
			,poitems.COSTEACH,cast(STUFF((SELECT ','+convert( char(10),PS.SCHD_DATE,101) + ' ('+cast (SCHD_QTY as varchar(max))+ '/'+ cast(balance as varchar(max))+')'
											FROM POITSCHD PS 
											where PS.UNIQLNNO =Poitems.UNIQLNNO 
											ORDER BY SCHD_DATE FOR XML path('')),1,1,'') as varchar(Max)) as Schd 
			,cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,5) as numeric (20,2)) as PoBalAmt,poitems.UNIQ_KEY
			,isnull(dbo.fnUsedOn(poitems.uniq_key),'') as UsedOn 
			,isnull(dbo.fnShortage(poitems.uniq_key),'') as Shortages
			,poitems.COSTEACHFC,cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACHfC,5) as numeric (20,2)) as PoBalAmtFC, Fcused.Symbol AS Currency
		
	from	FCUSED INNER JOIN POMAIN ON Pomain.Fcused_uniq = Fcused.Fcused_uniq
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY

		
	where	pomain.postatus = 'OPEN'
			and poitems.LCANCEL <> 1
			and POITEMS.ORD_QTY-poitems.ACPT_QTY <> 0.00
			--and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end	--09/24/2014 DRP:  removed
			and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			--and podate>=@lcDateStart AND podate<@lcDateEnd+1	--09/24/2014 DRP:  replaced with the DATEDIFF below
			and DATEDIFF(Day,podate,@lcDateStart)<=0 AND DATEDIFF(Day,podate,@lcDateEnd)>=0
	ORDER BY Currency, Supname, Ponum, itemno
	END
END--END of IF FC installed

END