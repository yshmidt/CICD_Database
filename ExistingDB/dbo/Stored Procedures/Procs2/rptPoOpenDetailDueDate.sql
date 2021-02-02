
-- =============================================
-- Author:		Debbie
-- Create date: 03/29/2012
-- Description:	This Stored Procedure was created for the Open Purchase Order Detail by Due Date
-- Reports Using Stored Procedure:  podetldu.rpt
-- Modified:	09/23/2014 DRP:  Added the userId and sort order
--								 Since we are getting away from the report forms where possible and the CR are no longer working.  I did a lot of modifications to the below to work with QuickViews. 
--								 Removed some un-needed fields from the @Detail table and added an id field to later be used with Running Total. 	
--			03/26/2015 DRP:  Per User Request I added the poitschd.Req_Date field to the results. 
--			10/19/15 DRP:  Per user request added the Buyer Initals back into the final results. 	 
--			02/25/16 VL:   Added FC Code
--			04/08/16 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 07/16/18 VL changed supname from char(30) to char(50)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================
CREATE PROCEDURE [dbo].[rptPoOpenDetailDueDate]
--declare
@userId uniqueidentifier= null
		
AS
BEGIN


-- 02/25/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	-- 07/16/18 VL changed supname from char(30) to char(50)
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	declare @Detail table	(Schd_date smalldatetime,Req_Date smalldatetime,Part_Class char(8),Part_Type char(8),DESCRIPT char(45),PARTMFGR char(8),MFGR_PT_NO char(30),PART_NO char(35),Revision char(8)
							,PONUM char(15),CONUM numeric(3,0),SUPNAME char(50),ITEMNO char(3),Schd_Qty numeric (10,2),SchdBal numeric(10,2),COSTEACH numeric(10,2),SchdBalAmt numeric(10,2)
							,id int not null identity(1,1) primary key,BUYER CHAR(3))


	insert into @Detail	
	select	POITSCHD.SCHD_DATE,POITSCHD.REQ_DATE,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class
			,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
			,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT
			,poitems.PARTMFGR,poitems.MFGR_PT_NO,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO
			,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
			,POMAIN.PONUM,CONUM,SUPINFO.SUPNAME,POITEMS.ITEMNO,POITSCHD.SCHD_QTY,POITSCHD.BALANCE as SchdBal,poitems.COSTEACH
			,isnull(CAST(round(poitschd.balance * poitems.COSTEACH,5) as numeric(20,2)),0.00) as SchdBalAmt	,POMAIN.BUYER
	from	POMAIN
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
			left outer join POITSCHD on poitems.UNIQLNNO = POITSCHD.UNIQLNNO
	where	pomain.postatus ='OPEN'
			and poitems.LCANCEL <> 1
			and POITEMS.ORD_QTY-poitems.ACPT_QTY <> 0.00
	order by SCHD_DATE,PART_CLASS,PART_TYPE,PART_NO,revision,PARTMFGR,PONUM,ITEMNO	


	/*SELECT STATEMENT INCLUDING RUNNING BALANCE*/
	SELECT  d.Schd_date,d.Req_Date as Required_Date,d.Part_Class,d.Part_Type,d.DESCRIPT,d.PARTMFGR,d.MFGR_PT_NO,d.PART_NO,d.Revision,d.PONUM,d.CONUM,d.SUPNAME,d.ITEMNO,D.Buyer as buyer_f
			,d.Schd_Qty,d.SchdBal,d.COSTEACH,d.SchdBalAmt,  (SELECT SUM(b.SchdBalAmt)FROM @Detail b WHERE b.id <= a.id) as RunningBal
	FROM   @Detail a inner join @Detail D on a.id = D.id
	ORDER BY a.id

	END
ELSE
-- FC Installed
	BEGIN
	-- 07/16/18 VL changed supname from char(30) to char(50)
	-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
	declare @DetailFC table	(Schd_date smalldatetime,Req_Date smalldatetime,Part_Class char(8),Part_Type char(8),DESCRIPT char(45),PARTMFGR char(8),MFGR_PT_NO char(30),PART_NO char(35),Revision char(8)
							,PONUM char(15),CONUM numeric(3,0),SUPNAME char(50),ITEMNO char(3),Schd_Qty numeric (10,2),SchdBal numeric(10,2),COSTEACH numeric(10,2),SchdBalAmt numeric(10,2)
							,id int not null identity(1,1) primary key,BUYER CHAR(3),COSTEACHFC numeric(10,2),SchdBalAmtFC numeric(10,2), Currency char(3))


	insert into @DetailFC	
	select	POITSCHD.SCHD_DATE,POITSCHD.REQ_DATE,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class
			,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
			,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT
			,poitems.PARTMFGR,poitems.MFGR_PT_NO,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO
			,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
			,POMAIN.PONUM,CONUM,SUPINFO.SUPNAME,POITEMS.ITEMNO,POITSCHD.SCHD_QTY,POITSCHD.BALANCE as SchdBal,poitems.COSTEACH
			,isnull(CAST(round(poitschd.balance * poitems.COSTEACH,5) as numeric(20,2)),0.00) as SchdBalAmt	,POMAIN.BUYER
			,poitems.COSTEACHFC,isnull(CAST(round(poitschd.balance * poitems.COSTEACHFC,5) as numeric(20,2)),0.00) as SchdBalAmtFC, Fcused.Symbol AS Currency
	from	Fcused INNER JOIN POMAIN ON Pomain.Fcused_uniq = Fcused.Fcused_uniq
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
			left outer join POITSCHD on poitems.UNIQLNNO = POITSCHD.UNIQLNNO
	where	pomain.postatus ='OPEN'
			and poitems.LCANCEL <> 1
			and POITEMS.ORD_QTY-poitems.ACPT_QTY <> 0.00
	order by Currency, SCHD_DATE,PART_CLASS,PART_TYPE,PART_NO,revision,PARTMFGR,PONUM,ITEMNO	


	/*SELECT STATEMENT INCLUDING RUNNING BALANCE*/
	SELECT  d.Schd_date,d.Req_Date as Required_Date,d.Part_Class,d.Part_Type,d.DESCRIPT,d.PARTMFGR,d.MFGR_PT_NO,d.PART_NO,d.Revision,d.PONUM,d.CONUM,d.SUPNAME,d.ITEMNO,D.Buyer as buyer_f
			,d.Schd_Qty,d.SchdBal,d.COSTEACH,d.SchdBalAmt,  (SELECT SUM(b.SchdBalAmt)FROM @Detail b WHERE b.id <= a.id) as RunningBal
			,d.COSTEACHFC,d.SchdBalAmtFC,  (SELECT SUM(b.SchdBalAmtFC)FROM @DetailFC b WHERE b.id <= a.id) as RunningBalFC, d.Currency
	FROM   @DetailFC a inner join @DetailFC D on a.id = D.id
	ORDER BY a.id
	END
END-- IF FC installed

/*09/23/2014 DRP*/  --BELOW WAS REPLACED WITH THE ABOVE
--declare @Detail table(PONUM char(15),PODATE smalldatetime,POSTATUS char(8),CONUM numeric(3,0),TERMS char(15),FOB char(15),SHIPVIA char(15),UNIQSUPNO char(10),SUPNAME char(30)
--		,ITEMNO char(3),UNIQ_KEY char(10),Part_Class char(8),Part_Type char(8),PART_NO char(25),Revision char(8),DESCRIPT char(45),BUYER char(3),uniqmfgrhd char(10)
--		,PARTMFGR char(8),MFGR_PT_NO char(30),ORD_QTY numeric(10,2),recv_qty numeric(10,2),acpt_qty numeric(10,2),REJ_QTY numeric(10,2),BalanceQty numeric(10,2)
--		,COSTEACH numeric(10,2),PoBalAmt numeric(20,2),Schd_date smalldatetime,Schd_Qty numeric (10,2),SchdBal numeric(10,2),SchdBalAmt numeric(10,2))
		
	
--select	POMAIN.PONUM, PODATE, POSTATUS, CONUM,POMAIN.UNIQSUPNO,SUPINFO.SUPNAME,POITEMS.ITEMNO,POITEMS.UNIQ_KEY
--		,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class
--		,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
--		,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO
--		,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
--		,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT,pomain.BUYER
--		,poitems.uniqmfgrhd,poitems.PARTMFGR, poitems.MFGR_PT_NO,poitems.ORD_QTY,poitems.recv_qty,poitems.acpt_qty,poitems.REJ_QTY
--		,poitems.ord_qty-poitems.acpt_qty as BalanceQty,poitems.COSTEACH
--		,cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,5) as numeric (20,2)) as PoBalAmt
--		,POITSCHD.SCHD_DATE,POITSCHD.SCHD_QTY,POITSCHD.BALANCE as SchdBal,CAST(round(poitschd.balance * poitems.COSTEACH,5) as numeric(20,2)) as SchdBalAmt 
		
--from	POMAIN
--		inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
--		INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
--		left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
--		left outer join POITSCHD on poitems.UNIQLNNO = POITSCHD.UNIQLNNO

--where	pomain.postatus ='OPEN'
--		and poitems.LCANCEL <> 1
--		and POITEMS.ORD_QTY-poitems.ACPT_QTY <> 0.00

--order by SCHD_DATE,PART_NO,revision,PONUM,ITEMNO		
/* END 09/24/2014 REMOVAL*/

		
END