
-- =============================================
-- Author:		Debbie
-- Create date: 03/30/2012
-- Description:	This Stored Procedure was created for the Closed Purchase Order Detail by Supplier
-- Reports Using Stored Procedure:  poclsupp.rpt
-- Modified:	09/24/2014 DRP:	replaced the Date range filter wiht the DATEDIFF
--				12/12/14 DS Added supplier status filter
--				02/23/16 VL Added FC code
--				04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/24/17 VL added functional currency code
-- 06/03/20 VL changed the column name from RecvTot to Recv_Tot, so the quickview grid doesn't showt he date format for value 0
-- =============================================
CREATE PROCEDURE [dbo].[rptPoClosedDetailBySupplier]

	@lcDateStart as smalldatetime= null
	,@lcDateEnd as smalldatetime = null
	,@lcUniqSupNo as varchar(max) = 'All' 
	--,@lcSup as varchar (35) = ''		--09/24/2014 replaced by @lcUniqSupNo
	, @userId uniqueidentifier= null
	,@supplierStatus varchar(20) = 'All'
AS
BEGIN

/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
declare @tSupNo as table (Uniqsupno char (10))

INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, @supplierStatus ;

IF @lcUniqSupNo<>'All' and @lcUniqSupNo<>'' and @lcUniqSupNo is not null
	insert into @tSupNo  select * from  dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',') WHERE cast(ID as char(10)) IN (SELECT UniqSupno from @tSupplier)
ELSE
	BEGIN
		IF @lcUniqSupNo='All'
		insert into @tSupno  select UniqSupno from @tSupplier
	END				


-- 02/23/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN

	select	supinfo.supname,POMAIN.PONUM,conum,BUYER,ITEMNO,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO
			,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class
			,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT
			,poitems.ORD_QTY,poitems.recv_qty,poitems.COSTEACH,poitems.recv_qty*poitems.COSTEACH as PoAmt
			,ISNULL(R.Cost,CAST(0.0 as numeric(12,5))) as RecvCost
			,pomain.POTAX
			,ISNULL(R.Tax ,CAST(0.0 as numeric(12,5))) as RecvTax
			,ISNULL(R.Cost,CAST(0.0 as numeric(12,5)))+ISNULL(R.Tax ,CAST(0.0 as numeric(12,5))) as Rcvd_Tot --(RecvCost+RecvTax)
			,ISNULL(R.Cost,CAST(0.0 as numeric(12,5)))-(poitems.recv_qty*poitems.COSTEACH ) as OrdVar --(RecvCost-PoAmt)
			,ISNULL(R.Tax ,CAST(0.0 as numeric(12,5)))-pomain.POTAX as TaxVar --(RecvTax-POTAX})
	
	from	POMAIN
			inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
			OUTER APPLY (SELECT SUM(costeach*acpt_qty) as Cost,SUM((costeach*acpt_qty*tax_pct)/100) as Tax 
				FROM SinvDetl INNER JOIN SINVOICE on SinvDetl.SINV_UNIQ =Sinvoice.SINV_UNIQ WHERE SINVDETL.UNIQLNNO = poitems.uniqlnno) R

	where	pomain.postatus = 'CLOSED'
			and poitems.LCANCEL <> 1
			and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			--and podate>=@lcDateStart AND podate<@lcDateEnd+1	--09/24/2014 replaced with the DATEDIFF below
			and DATEDIFF(Day,podate,@lcDateStart)<=0 AND DATEDIFF(Day,podate,@lcDateEnd)>=0

	order by supname,ponum,itemno
	END
ELSE
-- FC installed
	BEGIN
	select	supinfo.supname,POMAIN.PONUM,conum,BUYER,ITEMNO,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO
			,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class
			,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT
			,poitems.ORD_QTY,poitems.recv_qty,poitems.COSTEACH,poitems.recv_qty*poitems.COSTEACH as PoAmt
			,ISNULL(R.Cost,CAST(0.0 as numeric(12,5))) as RecvCost
			,pomain.POTAX
			,ISNULL(R.Tax ,CAST(0.0 as numeric(12,5))) as RecvTax
			-- 06/03/20 VL changed the column name from RecvTot to Recv_Tot, so the quickview grid doesn't showt he date format for value 0
			,ISNULL(R.Cost,CAST(0.0 as numeric(12,5)))+ISNULL(R.Tax ,CAST(0.0 as numeric(12,5))) as Rcvd_Tot --(RecvCost+RecvTax)
			,ISNULL(R.Cost,CAST(0.0 as numeric(12,5)))-(poitems.recv_qty*poitems.COSTEACH ) as OrdVar --(RecvCost-PoAmt)
			,ISNULL(R.Tax ,CAST(0.0 as numeric(12,5)))-pomain.POTAX as TaxVar --(RecvTax-POTAX})
			,poitems.COSTEACHFC,poitems.recv_qty*poitems.COSTEACHFC as PoAmtFC
			,ISNULL(R.CostFC,CAST(0.0 as numeric(12,5))) as RecvCostFC
			,pomain.POTAXFC
			,ISNULL(R.TaxFC ,CAST(0.0 as numeric(12,5))) as RecvTaxFC
			-- 06/03/20 VL changed the column name from RecvTot to Recv_Tot, so the quickview grid doesn't showt he date format for value 0
			,ISNULL(R.CostFC,CAST(0.0 as numeric(12,5)))+ISNULL(R.TaxFC ,CAST(0.0 as numeric(12,5))) as Rcvd_TotFC --(RecvCostFC+RecvTaxFC)
			,ISNULL(R.CostFC,CAST(0.0 as numeric(12,5)))-(poitems.recv_qty*poitems.COSTEACHFC ) as OrdVarFC --(RecvCostFC-PoAmtFC)
			,ISNULL(R.TaxFC ,CAST(0.0 as numeric(12,5)))-pomain.POTAXFC as TaxVarFC --(RecvTaxFC-POTAXFC})
			-- 01/24/17 VL added functional currency code
			--,Fcused.Symbol AS Currency
			,poitems.COSTEACHPR,poitems.recv_qty*poitems.COSTEACHPR as PoAmtPR
			,ISNULL(R.CostPR,CAST(0.0 as numeric(12,5))) as RecvCostPR
			,pomain.POTAXPR
			,ISNULL(R.TaxPR ,CAST(0.0 as numeric(12,5))) as RecvTaxPR
			-- 06/03/20 VL changed the column name from RecvTot to Recv_Tot, so the quickview grid doesn't showt he date format for value 0
			,ISNULL(R.CostPR,CAST(0.0 as numeric(12,5)))+ISNULL(R.TaxPR ,CAST(0.0 as numeric(12,5))) as Rcvd_TotPR --(RecvCostPR+RecvTaxPR)
			,ISNULL(R.CostPR,CAST(0.0 as numeric(12,5)))-(poitems.recv_qty*poitems.COSTEACHPR ) as OrdVarPR --(RecvCostPR-PoAmtPR)
			,ISNULL(R.TaxPR ,CAST(0.0 as numeric(12,5)))-pomain.POTAXPR as TaxVarPR --(RecvTaxPR-POTAXPR})
			,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol 
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
			and 1= case WHEN supinfo.UNIQSUPNO IN (SELECT Uniqsupno FROM @tSupNo) THEN 1 ELSE 0  END
			--and podate>=@lcDateStart AND podate<@lcDateEnd+1	--09/24/2014 replaced with the DATEDIFF below
			and DATEDIFF(Day,podate,@lcDateStart)<=0 AND DATEDIFF(Day,podate,@lcDateEnd)>=0

	order by TSymbol, supname,ponum,itemno
	END
END-- IF FC Installed

--/*09/24/2014 DRP:  Removed the below and replaced with above*/
----10/04/2013 DRP:  added code to handle Wo List
--					declare @Sup table(Sup char(35))
--					if @lcSup is not null and @lcSup <> ''
--						insert into @Sup select * from dbo.[fn_simpleVarcharlistToTable](@lcSup,',')

--select	POMAIN.PONUM, PODATE, POSTATUS, CONUM, pomain.TERMS,pomain.FOB,pomain.SHIPVIA,POMAIN.UNIQSUPNO,SUPINFO.SUPNAME
--		,poitems.uniqlnno,POITEMS.ITEMNO,POITEMS.UNIQ_KEY,case when poitems.uniq_key = '' then cast ('' as char(8))else I1.PART_CLASS end as Part_class
--		,case when poitems.uniq_key = '' then cast ('' as char(8)) else I1.part_type end as PART_TYPE,CASE WHEN POITEMS.UNIQ_KEY = '' THEN POITEMS.PART_NO ELSE I1.PART_NO END AS PART_NO
--		,case when poitems.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as revision,case when poitems.UNIQ_KEY = '' then poitems.DESCRIPT else I1.DESCRIPT end as DESCRIPT
--		,pomain.BUYER,poitems.uniqmfgrhd,poitems.PARTMFGR,poitems.MFGR_PT_NO,poitems.ORD_QTY,poitems.recv_qty,poitems.acpt_qty,poitems.REJ_QTY,poitems.ord_qty-poitems.acpt_qty as BalanceQty
--		,poitems.COSTEACH,poitems.INSPECTIONOTE,pomain.POTAX
--		,ISNULL(R.Cost,CAST(0.0 as numeric(12,5))) as RecvCost,ISNULL(R.Tax ,CAST(0.0 as numeric(12,5))) as RecvTax
		
--from	POMAIN
--		inner join SUPINFO on pomain.UNIQSUPNO = supinfo.UNIQSUPNO
--		INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
--		left outer join INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
--		OUTER APPLY (SELECT SUM(costeach*acpt_qty) as Cost,SUM((costeach*acpt_qty*tax_pct)/100) as Tax 
--			FROM SinvDetl INNER JOIN SINVOICE on SinvDetl.SINV_UNIQ =Sinvoice.SINV_UNIQ WHERE SINVDETL.UNIQLNNO = poitems.uniqlnno) R

		
--where	pomain.postatus = 'CLOSED'
--		and poitems.LCANCEL <> 1
--		and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
--		and podate>=@lcDateStart AND podate<@lcDateEnd+1

--		and 1 = case when SUPNAME like case when @lcSup ='*' then '%' else @lcSup+'%' end then 1
--											when @lcSup is null or @lcSup = '' then 1 else 0 end
/*09/24/2014 End Removal*/
END