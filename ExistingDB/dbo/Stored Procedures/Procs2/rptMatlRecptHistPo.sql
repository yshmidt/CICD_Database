
-- =============================================
-- Author:		<Debbie>
-- Create date: <11/14/2011>
-- Description:	<Compiles the Material Receipt History Report for PO>
-- Used On:     <Crystal Report {porechpo.rpt} 
-- Modified:	07/22/2014 DRP:  Upon request for xls export that we not repeat the Recvqty and Rejqty values.  So I added the Row Over Partition for those two fields. 
--								 Also added the PORECDTL.UNIQRECDTL field so I could use that within the Row Over Partition. 
--								 Noticed that the @userId was not in this procedure and added it.
--				11/04/15 DRP:  needed to add the /*SUPPLIER LIST*/  
--				01/25/17 VL:   Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptMatlRecptHistPo]
--declare
		@lcPoNum as varchar (max) = 'All'
		,@lcSupLeadZero as char(3) = ''
		,@lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		,@userId uniqueidentifier= null

AS
begin 

/*SUPPLIER LIST*/	
-- get list of approved suppliers for this user
DECLARE @tSupplier tSupplier
INSERT INTO @tSupplier EXEC [aspmnxSP_GetSuppliers4User] @userid, NULL, 'All';
--select * from @tSupplier



-- 01/25/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
	select	t1.PONUM,t1.CONUM,SUPNAME,t1.UNIQSUPNO,t1.ITEMNO,t1.poittype,t1.UNIQLNNO,t1.PORECPKNO,t1.Part_no,t1.Rev,t1.Descript
			,t1.part_class,t1.part_type,t1.UNIQMFGRHD,t1.PARTMFGR,t1.MFGR_PT_NO,t1.STDCOST,t1.RECVDATE
			--,t1.RECVQTY,t1.REJQTY --*/07/22/2014 DRP:  replaced with the two Row Over partitions below 
			-- 01/25/17 VL changed RecvQty to ReceivedQty, RejQty to FailedQty
			,CASE WHEN ROW_NUMBER() OVER(Partition by uniqrecdtl Order by Recvdate)=1 Then ReceivedQty ELSE CAST(0.00 as Numeric(20,2)) END AS RECVQTY
			,CASE WHEN ROW_NUMBER() OVER(Partition by uniqrecdtl Order by Recvdate)=1 Then FailedQty ELSE CAST(0.00 as Numeric(20,2)) END AS REJQTY
			,t1.ACCPTQTY,t1.RECEIVERNO,t1.UNIQDETNO,t1.LOC_UNIQ,t1.UNIQWH,t1.LOCATION,t1.Req_Alloc,t1.WAREHOUSE
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then UnitPrice ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPrice
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then ExtAccptAmt ELSE CAST(0.00 as Numeric(20,2)) END AS ExtAccptAmt
			,t1.lot_uniq,t1.Lotcode,t1.EXPDATE,t1.InternalLotCode,t1.LOTQTY,t1.REJLOTQTY,t1.SerialNo,t1.SERIALREJ


	from(
	-- 01/25/17 VL changed RecvQty to ReceivedQty, RejQty to FailedQty
	SELECT	POMAIN.PONUM,CONUM,SUPNAME,POMAIN.UNIQSUPNO,POITEMS.ITEMNO,poitems.POITTYPE,PORECDTL.UNIQLNNO,PORECDTL.PORECPKNO
			,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class
			,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type
			,PORECDTL.UNIQMFGRHD,porecdtl.PARTMFGR,porecdtl.MFGR_PT_NO,inventor.STDCOST,RECVDATE,ReceivedQty,PORECDTL.FailedQty
			,PORECLOC.ACCPTQTY,PORECDTL.RECEIVERNO,PORECLOC.UNIQDETNO,PORECLOC.LOC_UNIQ,PORECLOC.UNIQWH,PORECLOC.LOCATION
			,CASE WHEN POITTYPE <> 'Invt Part' and REQUESTTP <> 'MRO' then CAST('Requestor: ' + rtrim(POITSCHD.REQUESTor) + ' / '+REQUESTTP+': '+WOPRJNUMBER as CHAR(80)) else 
				case when POITTYPE <> 'Invt Part' and REQUESTTP = 'MRO' then CAST('Requestor: ' + POITSCHD.REQUESTOR AS CHAR (80)) ELSE
					case when POITTYPE = 'Invt Part' and REQUESTTP = 'Prj Alloc' then CAST ('Allocated to Project:  '+WOPRJNUMBER as CHAR(80)) else 
						CASE WHEN POITTYPE = 'Invt PArt' and requesttp = 'Wo Alloc' then CAST('Allocated to Work Order:  ' + woprjnumber as CHAR (80))
							else CAST ('' as CHAR(80))end end end END as Req_Alloc 	
			,WAREHOUS.WAREHOUSE,poitems.COSTEACH as UnitPrice,ROUND(porecloc.ACCPTQTY*poitems.COSTEACH,5)as ExtAccptAmt	
			,l.LOT_UNIQ,l.LOTCODE,l.EXPDATE,l.reference as InternalLotCode,l.LOTQTY,l.REJLOTQTY
			,case when @lcSupLeadZero = 'Yes' then cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) else s.serialno end as SerialNo
			,s.SERIALREJ,PORECDTL.UNIQRECDTL
	

	FROM	POMAIN
			INNER JOIN SUPINFO ON POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			LEFT OUTER JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY
			inner join PORECDTL on poitems.UNIQLNNO = PORECDTL.UNIQLNNO
			inner JOIN PORECLOC ON PORECDTL.UNIQRECDTL = PORECLOC.FK_UNIQRECDTL
			LEFT OUTER JOIN POITSCHD ON PORECLOC.UNIQDETNO = POITSCHD.UNIQDETNO
			left outer join WAREHOUS on PORECLOC.UNIQWH = warehous.UNIQWH
			LEFT OUTER JOIN PORECLOT L ON Porecloc.LOC_UNIQ =l.LOC_UNIQ  
			LEFT OUTER JOIN PORECSER S ON PorecLoc.LOC_UNIQ =S.LOC_UNIQ AND ISNULL(l.Lot_uniq,CAST(' ' as CHAR(10))) =S.LOT_UNIQ 
		
	WHERE	RECVDATE>=@lcdatestart and RECVDATE<@lcdateend+1
			and exists (select 1 from @tSupplier t inner join supinfo s on t.uniqsupno=s.UNIQSUPNO where s.UNIQSUPNO=pomain.UNIQSUPNO)
			and 1 = case when @lcPoNum = 'All' then 1 when dbo.padl(@lcPoNum,15,'0') = pomain.ponum then 1 else 0 end

	) t1
	END
ELSE
	BEGIN
	select	t1.PONUM,t1.CONUM,SUPNAME,t1.UNIQSUPNO,t1.ITEMNO,t1.poittype,t1.UNIQLNNO,t1.PORECPKNO,t1.Part_no,t1.Rev,t1.Descript
			,t1.part_class,t1.part_type,t1.UNIQMFGRHD,t1.PARTMFGR,t1.MFGR_PT_NO,t1.STDCOST,t1.RECVDATE
			--,t1.RECVQTY,t1.REJQTY --*/07/22/2014 DRP:  replaced with the two Row Over partitions below 
			-- 01/25/17 VL changed RecvQty to ReceivedQty, RejQty to FailedQty
			,CASE WHEN ROW_NUMBER() OVER(Partition by uniqrecdtl Order by Recvdate)=1 Then ReceivedQty ELSE CAST(0.00 as Numeric(20,2)) END AS RECVQTY
			,CASE WHEN ROW_NUMBER() OVER(Partition by uniqrecdtl Order by Recvdate)=1 Then FailedQty ELSE CAST(0.00 as Numeric(20,2)) END AS REJQTY
			,t1.ACCPTQTY,t1.RECEIVERNO,t1.UNIQDETNO,t1.LOC_UNIQ,t1.UNIQWH,t1.LOCATION,t1.Req_Alloc,t1.WAREHOUSE
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then UnitPrice ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPrice
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then ExtAccptAmt ELSE CAST(0.00 as Numeric(20,2)) END AS ExtAccptAmt
			,t1.lot_uniq,t1.Lotcode,t1.EXPDATE,t1.InternalLotCode,t1.LOTQTY,t1.REJLOTQTY,t1.SerialNo,t1.SERIALREJ
			-- 01/25/17 VL added functional currency code
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then UnitPriceFC ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPriceFC
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then ExtAccptAmtFC ELSE CAST(0.00 as Numeric(20,2)) END AS ExtAccptAmtFC
			,t1.STDCOSTPR
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then UnitPricePR ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPricePR
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then ExtAccptAmtPR ELSE CAST(0.00 as Numeric(20,2)) END AS ExtAccptAmtPR
			,TSymbol, PSymbol, FSymbol

	from(
	-- 01/25/17 VL changed RecvQty to ReceivedQty, RejQty to FailedQTy
	SELECT	POMAIN.PONUM,CONUM,SUPNAME,POMAIN.UNIQSUPNO,POITEMS.ITEMNO,poitems.POITTYPE,PORECDTL.UNIQLNNO,PORECDTL.PORECPKNO
			,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class
			,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type
			,PORECDTL.UNIQMFGRHD,porecdtl.PARTMFGR,porecdtl.MFGR_PT_NO,inventor.STDCOST,RECVDATE,ReceivedQty,PORECDTL.FailedQty
			,PORECLOC.ACCPTQTY,PORECDTL.RECEIVERNO,PORECLOC.UNIQDETNO,PORECLOC.LOC_UNIQ,PORECLOC.UNIQWH,PORECLOC.LOCATION
			,CASE WHEN POITTYPE <> 'Invt Part' and REQUESTTP <> 'MRO' then CAST('Requestor: ' + rtrim(POITSCHD.REQUESTor) + ' / '+REQUESTTP+': '+WOPRJNUMBER as CHAR(80)) else 
				case when POITTYPE <> 'Invt Part' and REQUESTTP = 'MRO' then CAST('Requestor: ' + POITSCHD.REQUESTOR AS CHAR (80)) ELSE
					case when POITTYPE = 'Invt Part' and REQUESTTP = 'Prj Alloc' then CAST ('Allocated to Project:  '+WOPRJNUMBER as CHAR(80)) else 
						CASE WHEN POITTYPE = 'Invt PArt' and requesttp = 'Wo Alloc' then CAST('Allocated to Work Order:  ' + woprjnumber as CHAR (80))
							else CAST ('' as CHAR(80))end end end END as Req_Alloc 	
			,WAREHOUS.WAREHOUSE,poitems.COSTEACH as UnitPrice,ROUND(porecloc.ACCPTQTY*poitems.COSTEACH,5)as ExtAccptAmt	
			,l.LOT_UNIQ,l.LOTCODE,l.EXPDATE,l.reference as InternalLotCode,l.LOTQTY,l.REJLOTQTY
			,case when @lcSupLeadZero = 'Yes' then cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) else s.serialno end as SerialNo
			,s.SERIALREJ,PORECDTL.UNIQRECDTL
			-- 01/25/17 VL added functional currency code
			,poitems.COSTEACHFC as UnitPriceFC,ROUND(porecloc.ACCPTQTY*poitems.COSTEACHFC,5)as ExtAccptAmtFC
			,inventor.STDCOSTPR
			,poitems.COSTEACHPR as UnitPricePR,ROUND(porecloc.ACCPTQTY*poitems.COSTEACHPR,5)as ExtAccptAmtPR	
			,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol  
	FROM	POMAIN
			-- 01/25/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON POMAIN.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON POMAIN.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON POMAIN.Fcused_uniq = TF.Fcused_uniq			
			INNER JOIN SUPINFO ON POMAIN.UNIQSUPNO = SUPINFO.UNIQSUPNO
			INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
			LEFT OUTER JOIN INVENTOR ON POITEMS.UNIQ_KEY = INVENTOR.UNIQ_KEY
			inner join PORECDTL on poitems.UNIQLNNO = PORECDTL.UNIQLNNO
			inner JOIN PORECLOC ON PORECDTL.UNIQRECDTL = PORECLOC.FK_UNIQRECDTL
			LEFT OUTER JOIN POITSCHD ON PORECLOC.UNIQDETNO = POITSCHD.UNIQDETNO
			left outer join WAREHOUS on PORECLOC.UNIQWH = warehous.UNIQWH
			LEFT OUTER JOIN PORECLOT L ON Porecloc.LOC_UNIQ =l.LOC_UNIQ  
			LEFT OUTER JOIN PORECSER S ON PorecLoc.LOC_UNIQ =S.LOC_UNIQ AND ISNULL(l.Lot_uniq,CAST(' ' as CHAR(10))) =S.LOT_UNIQ 
		
	WHERE	RECVDATE>=@lcdatestart and RECVDATE<@lcdateend+1
			and exists (select 1 from @tSupplier t inner join supinfo s on t.uniqsupno=s.UNIQSUPNO where s.UNIQSUPNO=pomain.UNIQSUPNO)
			and 1 = case when @lcPoNum = 'All' then 1 when dbo.padl(@lcPoNum,15,'0') = pomain.ponum then 1 else 0 end

	) t1

	END
end