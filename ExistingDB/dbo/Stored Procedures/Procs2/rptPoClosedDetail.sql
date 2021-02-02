
-- =============================================
-- Author:		Debbie
-- Create date: 04/03/2012
-- Description:	This Stored Procedure was created for the Closed Purchase Order Summary
-- Reports Using Stored Procedure:  poclsumm.rpt
-- Modified:	09/24/2014 DRP:  Added the Supplier List so that it would display only approved Suppliers per user
--								 Changed the results to work with the QuickView only. 
--								replaced the Date range filter wiht the DATEDIFF
--			12/12/14 DS Added supplier status filter
--			02/22/16 VL added FC code
--			04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--			01/24/17 VL added functional currency code
--			02/20/17 DRP:	Per request of user added SUPID and UNIQSUPNO to the results
-- =============================================
CREATE PROCEDURE [dbo].[rptPoClosedDetail]
	@lcDateStart as smalldatetime= null
	,@lcDateEnd as smalldatetime = null
	,@userId uniqueidentifier=null 
	,@supplierStatus varchar(20) = 'All'
AS
BEGIN


/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus ;
insert into @tSupno  select UniqSupno from @tSupplier

-- 02/18/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
		
	-- this section will just gather open poitem records with balance.  The Used In BOM and Shortages had to be added as subreports via Crystal.	
	select	supinfo.SUPNAME,pomain.PONUM,pomain.PODATE,pomain.CLOSDDATE,POMAIN.POTOTAL
			,ISNULL(R.Cost,CAST(0.0 as numeric(12,5)))+ISNULL(R.Tax ,CAST(0.0 as numeric(12,5))) as CloseCost --(RecvCost+RecvTax)
			,Abs(POTOTAL-(ISNULL(R.Cost,CAST(0.0 as numeric(12,5)))+ISNULL(R.Tax ,CAST(0.0 as numeric(12,5)))))as VarAmt   --(PoTotal-CloseCost)
			,BUYER,conum,VERDATE
			,supinfo.supid,supinfo.uniqsupno	--02/20/17 DRP:  added
	from	POMAIN
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
			OUTER APPLY (SELECT SUM(costeach*acpt_qty) as Cost,SUM((costeach*acpt_qty*tax_pct)/100) as Tax 
				FROM SinvDetl INNER JOIN SINVOICE on SinvDetl.SINV_UNIQ =Sinvoice.SINV_UNIQ WHERE SINVDETL.UNIQLNNO = poitems.uniqlnno) R
	where	pomain.postatus = 'CLOSED'
			and poitems.LCANCEL <> 1
			--and podate>=@lcDateStart AND podate<@lcDateEnd+1	--09/24/2014 replaced with the DATEDIFF below
			and DATEDIFF(Day,podate,@lcDateStart)<=0 AND DATEDIFF(Day,podate,@lcDateEnd)>=0
			and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
	order by SUPNAME,ponum,ITEMNO	

	END
ELSE
-- FC installed
	BEGIN
	-- this section will just gather open poitem records with balance.  The Used In BOM and Shortages had to be added as subreports via Crystal.	
	select	supinfo.SUPNAME,pomain.PONUM,pomain.PODATE,pomain.CLOSDDATE,POMAIN.POTOTAL
			,ISNULL(R.Cost,CAST(0.0 as numeric(12,5)))+ISNULL(R.Tax ,CAST(0.0 as numeric(12,5))) as CloseCost --(RecvCost+RecvTax)
			,Abs(POTOTAL-(ISNULL(R.Cost,CAST(0.0 as numeric(12,5)))+ISNULL(R.Tax ,CAST(0.0 as numeric(12,5)))))as VarAmt   --(PoTotal-CloseCost)
			,BUYER,conum,VERDATE
			,POMAIN.POTOTALFC,ISNULL(R.CostFC,CAST(0.0 as numeric(12,5)))+ISNULL(R.TaxFC ,CAST(0.0 as numeric(12,5))) as CloseCostFC --(RecvCost+RecvTax)
			,Abs(POTOTALFC-(ISNULL(R.CostFC,CAST(0.0 as numeric(12,5)))+ISNULL(R.TaxFC ,CAST(0.0 as numeric(12,5)))))as VarAmtFC   --(PoTotal-CloseCost)
			-- 01/24/17 VL added functional currency code
			--,Fcused.Symbol AS Currency
			,POMAIN.POTOTALPR,ISNULL(R.CostPR,CAST(0.0 as numeric(12,5)))+ISNULL(R.TaxPR ,CAST(0.0 as numeric(12,5))) as CloseCostPR --(RecvCost+RecvTax)
			,Abs(POTOTALPR-(ISNULL(R.CostPR,CAST(0.0 as numeric(12,5)))+ISNULL(R.TaxPR ,CAST(0.0 as numeric(12,5)))))as VarAmtPR   --(PoTotal-CloseCost)
			,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol 
			,supinfo.supid,supinfo.uniqsupno	--02/20/17 DRP:  added
	from	POMAIN 
			-- 01/24/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON POMAIN.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON POMAIN.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON POMAIN.Fcused_uniq = TF.Fcused_uniq			
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
			OUTER APPLY (SELECT SUM(costeach*acpt_qty) as Cost,SUM((costeach*acpt_qty*tax_pct)/100) as Tax 
						,SUM(costeachFC*acpt_qty) as CostFC,SUM((costeachFC*acpt_qty*tax_pct)/100) as TaxFC 
						,SUM(costeachPR*acpt_qty) as CostPR,SUM((costeachPR*acpt_qty*tax_pct)/100) as TaxPR 
				FROM SinvDetl INNER JOIN SINVOICE on SinvDetl.SINV_UNIQ =Sinvoice.SINV_UNIQ WHERE SINVDETL.UNIQLNNO = poitems.uniqlnno) R
	where	pomain.postatus = 'CLOSED'
			and poitems.LCANCEL <> 1
			--and podate>=@lcDateStart AND podate<@lcDateEnd+1	--09/24/2014 replaced with the DATEDIFF below
			and DATEDIFF(Day,podate,@lcDateStart)<=0 AND DATEDIFF(Day,podate,@lcDateEnd)>=0
			and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
	order by TSymbol,SUPNAME,ponum,ITEMNO	
	END
END -- END of IF FC installed
/*09/24/2014 DRP:  Removed the below section */
--declare @Detail table(PONUM char(15),PODATE smalldatetime,POSTATUS char(8),CLOSDDATE SMALLDATETIME,POTotal numeric (10,2),CONUM numeric(3,0),CoDate smalldatetime,TERMS char(15),FOB char(15)
--		,SHIPVIA char(15),UNIQSUPNO char(10),SUPNAME char(30),ITEMNO char(3),UNIQ_KEY char(10),Part_Class char(8),Part_Type char(8),PART_NO char(25),Revision char(8)
--		,DESCRIPT char(45),BUYER char(3),uniqmfgrhd char(10),PARTMFGR char(8),MFGR_PT_NO char(30),ORD_QTY numeric(10,2),recv_qty numeric(10,2),acpt_qty numeric(10,2)
--		,REJ_QTY numeric(10,2),BalanceQty numeric(10,2),COSTEACH numeric(10,2),PoBalAmt numeric(20,2),POTAX NUMERIC(12,5),RecvCost numeric (12,5),RecvTax numeric(12,5))
		
---- this section will just gather open poitem records with balance.  The Used In BOM and Shortages had to be added as subreports via Crystal.	
--select	POMAIN.PONUM, PODATE, POSTATUS,POMAIN.CLOSDDATE,pomain.POTOTAL,CONUM,pomain.VERDATE,pomain.terms,pomain.shipvia,POMAIN.UNIQSUPNO,SUPINFO.SUPNAME,POITEMS.ITEMNO,POITEMS.UNIQ_KEY
--		,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class
--		,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE
--		,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO
--		,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision
--		,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT,pomain.BUYER
--		,poitems.uniqmfgrhd,poitems.PARTMFGR, poitems.MFGR_PT_NO,poitems.ORD_QTY,poitems.recv_qty,poitems.acpt_qty,poitems.REJ_QTY
--		,poitems.ord_qty-poitems.acpt_qty as BalanceQty,poitems.COSTEACH
--		,cast(round((poitems.ORD_QTY-poitems.ACPT_QTY)* poitems.COSTEACH,5) as numeric (20,2)) as PoBalAmt
--		,pomain.POTAX
--		,ISNULL(R.Cost,CAST(0.0 as numeric(12,5))) as RecvCost,ISNULL(R.Tax ,CAST(0.0 as numeric(12,5))) as RecvTax
		
		
--from	POMAIN
--		inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
--		INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
--		left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
--		OUTER APPLY (SELECT SUM(costeach*acpt_qty) as Cost,SUM((costeach*acpt_qty*tax_pct)/100) as Tax 
--			FROM SinvDetl INNER JOIN SINVOICE on SinvDetl.SINV_UNIQ =Sinvoice.SINV_UNIQ WHERE SINVDETL.UNIQLNNO = poitems.uniqlnno) R

		
--where	pomain.postatus = 'CLOSED'
--		and poitems.LCANCEL <> 1
--		and podate>=@lcDateStart AND podate<@lcDateEnd+1
/*09/24/2014 DRP End Section removal*/		
		
END