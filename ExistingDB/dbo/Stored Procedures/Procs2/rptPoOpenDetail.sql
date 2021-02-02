
-- =============================================
-- Author:		Debbie
-- Create date: 03/26/2012
-- Description:	This Stored Procedure was created for the Open Purchase Order Detail by Part Number
-- Reports Using Stored Procedure:  podetlpt.rpt, podetlpw.rpt,posumm.rpt
-- Modified:	09/24/2014 DRP:  Added all four parameters to be used with Cloud Manex . . . added the Supplier List to only display Suppliers that are approved for the user.
--								removed some unused fields from the @Detail table and selection		
--								created three different section that will display different results based off of the @lcRptType selection 		
--								replaced the Date range filter wiht the DATEDIFF
----			11/20/2014 DRP:  Changed <<COSTEACH numeric(10,2)>> to <<COSTEACH numeric(10,5)>> had to also change the mnxJqGridDefaults to show 5 decimal places
--				12/12/14 DS Added supplier status filter
--				10/28/15 DRP:  needed to change "COSTEACH numeric(10,5)" to be "COSTEACH numeric(15,7)" to avoid truncation error
--				02/25/16 VL:   Added FC code
--				04/08/16 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				02/20/17 DRP: added Supid, Uniqsupno per user reques
-- 07/16/18 VL changed supname from char(30) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptPoOpenDetail]

	@lcRptType as char(30) = 'Summary'	--by Part Number,by Part Number w/Where Used, Summary
	,@lcDateStart as smalldatetime = null
	,@lcDateEnd as smalldatetime = null
	,@userId uniqueidentifier = null
	,@supplierStatus varchar(20) = 'All'
	
AS
BEGIN

/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus ;

insert into @tSupno  select UniqSupno from @tSupplier
				

-- 02/24/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	-- 07/16/18 VL changed supname from char(30) to char(50)
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	declare @Detail table(PONUM char(15),PODATE smalldatetime,POSTATUS char(8),POTotal numeric (10,2),CONUM numeric(3,0),CoDate smalldatetime,TERMS char(15),FOB char(15)
			,UNIQSUPNO char(10),SUPNAME char(50),ITEMNO char(3),UNIQ_KEY char(10),Part_Class char(8),Part_Type char(8),PART_NO char(35),Revision char(8),DESCRIPT char(45)
			,BUYER char(3),PARTMFGR char(8),ORD_QTY numeric(10,2),recv_qty numeric(10,2),acpt_qty numeric(10,2),REJ_QTY numeric(10,2),BalanceQty numeric(10,2)
			,COSTEACH numeric(15,7),PoBalAmt numeric(20,2),Schd text,supid char(10))	--02/20/17 DRP:  added supid

	insert into @Detail		
	-- this section will just gather open poitem records with balance.  	
	select	POMAIN.PONUM, PODATE, POSTATUS,pomain.POTOTAL,CONUM,pomain.VERDATE,pomain.terms,pomain.fob,POMAIN.UNIQSUPNO,SUPINFO.SUPNAME,POITEMS.ITEMNO,POITEMS.UNIQ_KEY
			,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
			,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
			,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT,pomain.BUYER,poitems.PARTMFGR,poitems.ORD_QTY,poitems.recv_qty,poitems.acpt_qty,poitems.REJ_QTY
			,poitems.ord_qty-poitems.acpt_qty as BalanceQty,poitems.COSTEACH,cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,5) as numeric (20,2)) as PoBalAmt
			,cast(STUFF((SELECT ','+convert( char(10),PS.SCHD_DATE,101) + ' ('+cast (SCHD_QTY as varchar(max))+ '/'+ cast(balance as varchar(max))+')'
									FROM POITSCHD PS 
									where PS.UNIQLNNO =Poitems.UNIQLNNO 
									ORDER BY SCHD_DATE FOR XML path('')),1,1,'') as varchar(Max)) as Schd 
			,supinfo.supid	--02/20/17 DRP:  added
		
	from	POMAIN
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
	
	where	pomain.postatus = 'OPEN'
			and poitems.LCANCEL <> 1
			and POITEMS.ORD_QTY-poitems.ACPT_QTY <> 0.00


	if (@lcRptType = 'by Part Number')
		Begin
			select	part_no,Revision,Part_Class,Part_Type,DESCRIPT,PARTMFGR,PONUM,CONUM,ITEMNO,SUPNAME,ORD_QTY,recv_qty,REJ_QTY,BalanceQty,COSTEACH,PoBalAmt,Schd 
					,supid,uniqsupno	--02/20/17 DRP:  added 
			from	@Detail
			where	1= case WHEN UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			order by PART_NO,Revision,PONUM
		End 

	else if (@lcRptType = 'by Part Number w/Where Used')
		Begin
			select	part_no,Revision,Part_Class,Part_Type,DESCRIPT,PARTMFGR,PONUM,CONUM,ITEMNO,SUPNAME,ORD_QTY,recv_qty,REJ_QTY,BalanceQty,COSTEACH,PoBalAmt,Schd 
					,supid,uniqsupno	--02/20/17 DRP:  added 
					,isnull(dbo.fnUsedOn(uniq_key),'') as UsedOn 
					,isnull(dbo.fnShortage(uniq_key),'') as Shortages
			from	@Detail
			where	1= case WHEN UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			order by PART_NO,Revision,PONUM
		End
	
	else if (@lcRptType = 'Summary')
		Begin
			Select	Supname,PONUM,PODATE,POTotal,SUM(PoBalAmt) PoBalAmt ,TERMS,BUYER,CONUM,CoDate
					,supid,uniqsupno	--02/20/17 DRP:  added 
			from	@Detail
			where	--podate>=@lcDateStart AND podate<@lcDateEnd+1	--09/24/2014 replaced with the DATEDIFF below
					DATEDIFF(Day,podate,@lcDateStart)<=0 AND DATEDIFF(Day,podate,@lcDateEnd)>=0
					and 1= case WHEN UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			group by SUPNAME,PONUM,PODATE,POTotal,TERMS,BUYER,CONUM,CoDate,supid,UNIQSUPNO
		End
	END
ELSE
-- FC installed
	BEGIN
	-- 07/16/18 VL changed supname from char(30) to char(50)
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	declare @DetailFC table(PONUM char(15),PODATE smalldatetime,POSTATUS char(8),POTotal numeric (10,2),CONUM numeric(3,0),CoDate smalldatetime,TERMS char(15),FOB char(15)
			,UNIQSUPNO char(10),SUPNAME char(50),ITEMNO char(3),UNIQ_KEY char(10),Part_Class char(8),Part_Type char(8),PART_NO char(35),Revision char(8),DESCRIPT char(45)
			,BUYER char(3),PARTMFGR char(8),ORD_QTY numeric(10,2),recv_qty numeric(10,2),acpt_qty numeric(10,2),REJ_QTY numeric(10,2),BalanceQty numeric(10,2)
			,COSTEACH numeric(15,7),PoBalAmt numeric(20,2),Schd text
			,POTotalFC numeric (10,2),COSTEACHFC numeric(15,7),PoBalAmtFC numeric(20,2), Currency char(3),supid char(10))	--02/20/17 DRP:  added supid

	insert into @DetailFC		
	-- this section will just gather open poitem records with balance.  	
	select	POMAIN.PONUM, PODATE, POSTATUS,pomain.POTOTAL,CONUM,pomain.VERDATE,pomain.terms,pomain.fob,POMAIN.UNIQSUPNO,SUPINFO.SUPNAME,POITEMS.ITEMNO,POITEMS.UNIQ_KEY
			,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
			,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
			,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT,pomain.BUYER,poitems.PARTMFGR,poitems.ORD_QTY,poitems.recv_qty,poitems.acpt_qty,poitems.REJ_QTY
			,poitems.ord_qty-poitems.acpt_qty as BalanceQty,poitems.COSTEACH,cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,5) as numeric (20,2)) as PoBalAmt
			,cast(STUFF((SELECT ','+convert( char(10),PS.SCHD_DATE,101) + ' ('+cast (SCHD_QTY as varchar(max))+ '/'+ cast(balance as varchar(max))+')'
									FROM POITSCHD PS 
									where PS.UNIQLNNO =Poitems.UNIQLNNO 
									ORDER BY SCHD_DATE FOR XML path('')),1,1,'') as varchar(Max)) as Schd
			,pomain.POTOTALFC, poitems.COSTEACHFC, cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACHFC,5) as numeric (20,2)) as PoBalAmtFC
			,Fcused.Symbol AS Currency,supid	--02/2017 DRP:  added supid
		
	from	FCUSED INNER JOIN POMAIN ON Pomain.Fcused_uniq = Fcused.Fcused_uniq
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems.UNIQ_KEY = I1.UNIQ_KEY
	
	where	pomain.postatus = 'OPEN'
			and poitems.LCANCEL <> 1
			and POITEMS.ORD_QTY-poitems.ACPT_QTY <> 0.00


	if (@lcRptType = 'by Part Number')
		Begin
			select	part_no,Revision,Part_Class,Part_Type,DESCRIPT,PARTMFGR,PONUM,CONUM,ITEMNO,SUPNAME,ORD_QTY,recv_qty,REJ_QTY,BalanceQty,COSTEACH,PoBalAmt,Schd, COSTEACHFC,PoBalAmtFC, Currency 
					,supid,UNIQSUPNO	--02/2017 DRP:  added
			from	@DetailFC
			where	1= case WHEN UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			order by Currency, PART_NO,Revision,PONUM
		End 

	else if (@lcRptType = 'by Part Number w/Where Used')
		Begin
			select	part_no,Revision,Part_Class,Part_Type,DESCRIPT,PARTMFGR,PONUM,CONUM,ITEMNO,SUPNAME,ORD_QTY,recv_qty,REJ_QTY,BalanceQty,COSTEACH,PoBalAmt,Schd, COSTEACHFC,PoBalAmtFC, Currency 
					,supid,UNIQSUPNO	--02/2017 DRP:  added
					,isnull(dbo.fnUsedOn(uniq_key),'') as UsedOn 
					,isnull(dbo.fnShortage(uniq_key),'') as Shortages
			from	@DetailFC
			where	1= case WHEN UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			order by Currency, PART_NO,Revision,PONUM
		End
	
	else if (@lcRptType = 'Summary')
		Begin
			Select	Supname,PONUM,PODATE,POTotal,SUM(PoBalAmt) PoBalAmt ,TERMS,BUYER,CONUM,CoDate, POTotalFC,SUM(PoBalAmtFC) PoBalAmtFC, Currency
					,supid,UNIQSUPNO	--02/2017 DRP:  added
			from	@DetailFC
			where	--podate>=@lcDateStart AND podate<@lcDateEnd+1	--09/24/2014 replaced with the DATEDIFF below
					DATEDIFF(Day,podate,@lcDateStart)<=0 AND DATEDIFF(Day,podate,@lcDateEnd)>=0
					and 1= case WHEN UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			group by Currency, SUPNAME,PONUM,PODATE,POTotal,TERMS,BUYER,CONUM,CoDate,POTotalFC,supid,UNIQSUPNO
		End
	END
END--END of IF FC installed


/*09/24/2014 DRP:  replaced the below with the above changes to work with the WebMAnex*/
--declare @Detail table(PONUM char(15),PODATE smalldatetime,POSTATUS char(8),POTotal numeric (10,2),CONUM numeric(3,0),CoDate smalldatetime,TERMS char(15),FOB char(15),SHIPVIA char(15),UNIQSUPNO char(10),SUPNAME char(30)
--		,ITEMNO char(3),UNIQ_KEY char(10),Part_Class char(8),Part_Type char(8),PART_NO char(25),Revision char(8),DESCRIPT char(45),BUYER char(3),uniqmfgrhd char(10)
--		,PARTMFGR char(8),MFGR_PT_NO char(30),ORD_QTY numeric(10,2),recv_qty numeric(10,2),acpt_qty numeric(10,2),REJ_QTY numeric(10,2),BalanceQty numeric(10,2)
--		,COSTEACH numeric(10,2),PoBalAmt numeric(20,2),Schd text,INSPECTIONOTE text)
		
---- this section will just gather open poitem records with balance.  The Used In BOM and Shortages had to be added as subreports via Crystal.	
--select	POMAIN.PONUM, PODATE, POSTATUS,pomain.POTOTAL,CONUM,pomain.VERDATE,pomain.terms,pomain.shipvia,POMAIN.UNIQSUPNO,SUPINFO.SUPNAME,POITEMS.ITEMNO,POITEMS.UNIQ_KEY
--		,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class
--		,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
--		,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO
--		,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
--		,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT,pomain.BUYER
--		,poitems.uniqmfgrhd,poitems.PARTMFGR, poitems.MFGR_PT_NO,poitems.ORD_QTY,poitems.recv_qty,poitems.acpt_qty,poitems.REJ_QTY
--		,poitems.ord_qty-poitems.acpt_qty as BalanceQty,poitems.COSTEACH
--		,cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,5) as numeric (20,2)) as PoBalAmt
--				,cast(STUFF((SELECT ','+convert( char(10),PS.SCHD_DATE,101) + ' ('+cast (SCHD_QTY as varchar(max))+ '/'+ cast(balance as varchar(max))+')'
--										FROM POITSCHD PS 
--										where PS.UNIQLNNO =Poitems.UNIQLNNO 
--										ORDER BY SCHD_DATE FOR XML path('')),1,1,'') as varchar(Max)) as Schd 
--		,poitems.INSPECTIONOTE
		
--from	POMAIN
--		inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
--		INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
--		left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY

		
--where	pomain.postatus = 'OPEN'
--		and poitems.LCANCEL <> 1
		--and POITEMS.ORD_QTY-poitems.ACPT_QTY <> 0.00
/*09/24/2014 End*/		
END