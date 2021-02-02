
-- =============================================
-- Author:		<Debbie>
-- Create date: <11/18/2011>
-- Description:	<Compiles the Material Receipt History Report for All>
-- Used On:     <Crystal Report {porechis.rpt}, {porechaw.rpt}, {porechas.rpt} 
-- Modified:	07/22/2014 DRP:  Upon request for xls export that we not repeat the Recvqty and Rejqty values.  So I added the Row Over Partition for those two fields. 
--								 Also added the PORECDTL.UNIQRECDTL field so I could use that within the Row Over Partition. 
--								 Noticed that the @userId was not in this procedure and added it. 
--			03/05/2015 DRP:  Added Uniq_key per request.  
----			07/12/16 DRP:  needed to add another case when to the Req_alloc formula <<case when POITTYPE = 'Invt Part' and POITSCHD.REQUESTTP = 'Invt Recv' then cast (rtrim(poitschd.requestor) as char (80))>
----							added the @lcSort parameter to this procedure and added the sort order to match the param selection. 
----							needed to change the fields to the new columns names ReceivedQty and FailedQty
--				01/25/2017 VL:   Added functional currency code 
--			02/20/17 DRP:  added supid,u_of_meas,Pur_uofm per user request
-- =============================================
CREATE PROCEDURE [dbo].[rptMatlRecptHistAll]

--declare
		@lcSupLeadZero as char(3) = 'yes'
		,@lcDateStart as smalldatetime= null
		,@lcDateEnd as smalldatetime = null
		,@userId uniqueidentifier= NULL
		,@lcSort as char(15) = 'Part Number'		--Part Number, Warehouse, Supplier	--07/12/16 DRP:  Added
		
		


AS
begin 

-- 01/25/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN

	select	t1.PONUM,t1.CONUM,SUPNAME,t1.UNIQSUPNO,t1.ITEMNO,t1.poittype,t1.UNIQLNNO,t1.PORECPKNO,t1.Part_no,t1.Rev,t1.Descript
			,t1.part_class,t1.part_type,t1.UNIQMFGRHD,t1.PARTMFGR,t1.MFGR_PT_NO,t1.STDCOST,t1.RECVDATE
			--,t1.RECVQTY,t1.REJQTY --*/07/22/2014 DRP:  replaced with the two Row Over partitions below 
			,CASE WHEN ROW_NUMBER() OVER(Partition by uniqrecdtl Order by Recvdate)=1 Then ReceivedQty ELSE CAST(0.00 as Numeric(20,2)) END AS RECVQTY	--07/12/16 DRP:  Changed to receivedQty
			,CASE WHEN ROW_NUMBER() OVER(Partition by uniqrecdtl Order by Recvdate)=1 Then FailedQty ELSE CAST(0.00 as Numeric(20,2)) END AS REJQTY	--07/12/16 DRP:  Changed to FailedQty
			,t1.ACCPTQTY,t1.RECEIVERNO,t1.UNIQDETNO,t1.LOC_UNIQ,t1.UNIQWH,t1.LOCATION,t1.Req_Alloc,t1.WAREHOUSE
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then UnitPrice ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPrice
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then ExtAccptAmt ELSE CAST(0.00 as Numeric(20,2)) END AS ExtAccptAmt
			,t1.lot_uniq,t1.Lotcode,t1.EXPDATE,t1.InternalLotCode,t1.LOTQTY,t1.REJLOTQTY,t1.SerialNo,t1.SERIALREJ,t1.Uniq_key
			,t1.Supid,t1.U_OF_MEAS,t1.Pur_uofm	--02/20/17 DRP:  added 


	from(
	SELECT	POMAIN.PONUM,CONUM,SUPNAME,POMAIN.UNIQSUPNO,POITEMS.ITEMNO,poitems.POITTYPE,PORECDTL.UNIQLNNO,PORECDTL.PORECPKNO
			,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class
			,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type
			,PORECDTL.UNIQMFGRHD,porecdtl.PARTMFGR,porecdtl.MFGR_PT_NO,inventor.STDCOST,RECVDATE
			,ReceivedQty,PORECDTL.FailedQty	--07/12/16 DRP: noticed it would not let me apply other changes becauses these fields changed names RECVQTY,PORECDTL.REJQTY
			,PORECLOC.ACCPTQTY,PORECDTL.RECEIVERNO,PORECLOC.UNIQDETNO,PORECLOC.LOC_UNIQ,PORECLOC.UNIQWH,PORECLOC.LOCATION
			,CASE WHEN POITTYPE <> 'Invt Part' and REQUESTTP <> 'MRO' then CAST('Requestor: ' + rtrim(POITSCHD.REQUESTor) + ' / '+REQUESTTP+': '+WOPRJNUMBER as CHAR(80)) else 
				case when POITTYPE <> 'Invt Part' and REQUESTTP = 'MRO' then CAST('Requestor: ' + POITSCHD.REQUESTOR AS CHAR (80)) ELSE
					case when POITTYPE = 'Invt Part' and REQUESTTP = 'Prj Alloc' then CAST ('Allocated to Project:  '+WOPRJNUMBER as CHAR(80)) else 
						CASE WHEN POITTYPE = 'Invt PArt' and requesttp = 'Wo Alloc' then CAST('Allocated to Work Order:  ' + woprjnumber as CHAR (80)) else
							case when POITTYPE = 'Invt Part' and POITSCHD.REQUESTTP = 'Invt Recv' then cast (rtrim(poitschd.requestor) as char (80))	--07/12/16 DRP:  added
								else CAST ('' as CHAR(80))end end end END end as Req_Alloc
			,WAREHOUS.WAREHOUSE,poitems.COSTEACH as UnitPrice,ROUND(porecloc.ACCPTQTY*poitems.COSTEACH,5)as ExtAccptAmt	
			,l.LOT_UNIQ,l.LOTCODE,l.EXPDATE,l.reference as InternalLotCode, l.LOTQTY, l.REJLOTQTY
			,case when @lcSupLeadZero = 'Yes' then cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) else s.serialno end as SerialNo
			,s.SERIALREJ,PORECDTL.UNIQRECDTL,inventor.UNIQ_KEY
			,supinfo.supid,inventor.U_OF_MEAS,inventor.PUR_UOFM	--02/20/17 DRP:  added
	

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
		


	) t1

	order by case when @lcSort = 'Warehouse' then warehouse else		--07/12/16 DRP:  order was added
			case when @lcSort = 'Supplier' then t1.SUPNAME else
			t1.Part_no end end,part_no,Rev,Descript,partmfgr,mfgr_pt_no
	END
ELSE
	BEGIN
	select	t1.PONUM,t1.CONUM,SUPNAME,t1.UNIQSUPNO,t1.ITEMNO,t1.poittype,t1.UNIQLNNO,t1.PORECPKNO,t1.Part_no,t1.Rev,t1.Descript
			,t1.part_class,t1.part_type,t1.UNIQMFGRHD,t1.PARTMFGR,t1.MFGR_PT_NO,t1.STDCOST,t1.RECVDATE
			--,t1.RECVQTY,t1.REJQTY --*/07/22/2014 DRP:  replaced with the two Row Over partitions below 
			,CASE WHEN ROW_NUMBER() OVER(Partition by uniqrecdtl Order by Recvdate)=1 Then ReceivedQty ELSE CAST(0.00 as Numeric(20,2)) END AS RECVQTY	--07/12/16 DRP:  Changed to receivedQty
			,CASE WHEN ROW_NUMBER() OVER(Partition by uniqrecdtl Order by Recvdate)=1 Then FailedQty ELSE CAST(0.00 as Numeric(20,2)) END AS REJQTY	--07/12/16 DRP:  Changed to FailedQty
			,t1.ACCPTQTY,t1.RECEIVERNO,t1.UNIQDETNO,t1.LOC_UNIQ,t1.UNIQWH,t1.LOCATION,t1.Req_Alloc,t1.WAREHOUSE
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then UnitPrice ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPrice
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then ExtAccptAmt ELSE CAST(0.00 as Numeric(20,2)) END AS ExtAccptAmt
			,t1.lot_uniq,t1.Lotcode,t1.EXPDATE,t1.InternalLotCode,t1.LOTQTY,t1.REJLOTQTY,t1.SerialNo,t1.SERIALREJ,t1.Uniq_key
			-- 01/25/17 VL added functional currency code
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then UnitPriceFC ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPriceFC
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then ExtAccptAmtFC ELSE CAST(0.00 as Numeric(20,2)) END AS ExtAccptAmtFC
			,t1.STDCOSTPR
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then UnitPricePR ELSE CAST(0.00 as Numeric(20,2)) END AS UnitPricePR
			,CASE WHEN ROW_NUMBER() OVER(Partition by loc_uniq Order by Recvdate)=1 Then ExtAccptAmtPR ELSE CAST(0.00 as Numeric(20,2)) END AS ExtAccptAmtPR
			,TSymbol, PSymbol, FSymbol
			,t1.supid,t1.U_OF_MEAS,t1.PUR_UOFM	--02/20/17 DRP:  added


	from(
	SELECT	POMAIN.PONUM,CONUM,SUPNAME,POMAIN.UNIQSUPNO,POITEMS.ITEMNO,poitems.POITTYPE,PORECDTL.UNIQLNNO,PORECDTL.PORECPKNO
			,case when poitems.POITTYPE = 'MRO' or poitems.POITTYPE ='Services' then poitems.PART_NO else Inventor.PART_NO end as Part_no
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.REVISION else inventor.REVISION end as Rev
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.DESCRIPT else inventor.DESCRIPT end as Descript
			,case when poitems.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then poitems.PART_CLASS else inventor.PART_CLASS end as Part_Class
			,case when POITEMS.POITTYPE = 'MRO' OR poitems.POITTYPE = 'Services' then POITEMs.PART_TYPE else inventor.PART_TYPE end as part_type
			,PORECDTL.UNIQMFGRHD,porecdtl.PARTMFGR,porecdtl.MFGR_PT_NO,inventor.STDCOST,RECVDATE
			,ReceivedQty,PORECDTL.FailedQty	--07/12/16 DRP: noticed it would not let me apply other changes becauses these fields changed names RECVQTY,PORECDTL.REJQTY
			,PORECLOC.ACCPTQTY,PORECDTL.RECEIVERNO,PORECLOC.UNIQDETNO,PORECLOC.LOC_UNIQ,PORECLOC.UNIQWH,PORECLOC.LOCATION
			,CASE WHEN POITTYPE <> 'Invt Part' and REQUESTTP <> 'MRO' then CAST('Requestor: ' + rtrim(POITSCHD.REQUESTor) + ' / '+REQUESTTP+': '+WOPRJNUMBER as CHAR(80)) else 
				case when POITTYPE <> 'Invt Part' and REQUESTTP = 'MRO' then CAST('Requestor: ' + POITSCHD.REQUESTOR AS CHAR (80)) ELSE
					case when POITTYPE = 'Invt Part' and REQUESTTP = 'Prj Alloc' then CAST ('Allocated to Project:  '+WOPRJNUMBER as CHAR(80)) else 
						CASE WHEN POITTYPE = 'Invt PArt' and requesttp = 'Wo Alloc' then CAST('Allocated to Work Order:  ' + woprjnumber as CHAR (80)) else
							case when POITTYPE = 'Invt Part' and POITSCHD.REQUESTTP = 'Invt Recv' then cast (rtrim(poitschd.requestor) as char (80))	--07/12/16 DRP:  added
								else CAST ('' as CHAR(80))end end end END end as Req_Alloc
			,WAREHOUS.WAREHOUSE,poitems.COSTEACH as UnitPrice,ROUND(porecloc.ACCPTQTY*poitems.COSTEACH,5)as ExtAccptAmt	
			,l.LOT_UNIQ,l.LOTCODE,l.EXPDATE,l.reference as InternalLotCode, l.LOTQTY, l.REJLOTQTY
			,case when @lcSupLeadZero = 'Yes' then cast(dbo.fremoveLeadingZeros(SERIALNO) as varchar(MAx)) else s.serialno end as SerialNo
			,s.SERIALREJ,PORECDTL.UNIQRECDTL,inventor.UNIQ_KEY
			-- 01/25/17 VL added functional currency code
			,poitems.COSTEACHFC as UnitPriceFC,ROUND(porecloc.ACCPTQTY*poitems.COSTEACHFC,5)as ExtAccptAmtFC
			,inventor.STDCOSTPR
			,poitems.COSTEACHPR as UnitPricePR,ROUND(porecloc.ACCPTQTY*poitems.COSTEACHPR,5)as ExtAccptAmtPR	
			,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol  
			,supinfo.supid,inventor.U_OF_MEAS,inventor.PUR_UOFM	--02/20/17 DRP:  added		
	

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
		


	) t1

	order by case when @lcSort = 'Warehouse' then warehouse else		--07/12/16 DRP:  order was added
			case when @lcSort = 'Supplier' then t1.SUPNAME else
			t1.Part_no end end,part_no,Rev,Descript,partmfgr,mfgr_pt_no
	END

end

		