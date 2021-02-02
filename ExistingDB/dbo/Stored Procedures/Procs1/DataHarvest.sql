-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/31/2015
-- Description:	Custom SP for Vexos - Data Warehouse for the transactions entered in Manex
-- including sales orders, work orders, RMA, RMA Receipts and DMR
--02/08/16 YS remove Invtmfhd table and use invtmpnlink and MfgrMaster
--02/03/17 YS need to change the code with the new receiving process 
-- =============================================
CREATE PROCEDURE [dbo].[DataHarvest]
	-- Add the parameters for the stored procedure here
	/*
	1. Always start from beginning of Prior FY through end of day before today. E.g. if running on oct 31, 2015 start from jan, 1 2014 and end oct, 30 2014 
	[Year] char(4),[Month] char(2),
		[Week] char(2), [Quater] char(1) may not be in the result table but created on the fly, for now will keep it in the table  
	?? Should I use part_no and revision as a separate columns in placer of SKU or combine it into SKU column	
	?? SkuType or part_class? should we add part_type?
	?? userid - initials can be repeated. use username from aspnet_users
	?? SKU for sales order says sales order class what is it
	*/
	---@InitialRun bit = 0  
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- create table variable for now
	declare @tResult Table ([Site] varchar(4),txnType varchar(50),EntryDate Date null,DateExpected Date null, dateActual Date null,[Year] char(4),[Month] char(2),
		[Week] char(2), [Quarter] char(1), CustomerVendor char(10),Name varchar(50),orderNo varchar(20),
		[Status] varchar(20) ,interCompany bit,Consigned bit,SKU varchar(50),[Description] varchar(50),
		PackingSlip varchar(20) null,Invoiceno varchar(20) null,orderQty numeric(12,2),txnQty numeric(12,2),extCostUSD numeric(15,2),
		extPriceUSD numeric(15,2),entryDateTime smalldatetime,Warehouse varchar(10),Bonded bit default 0,mfgrPartNo varchar(35),
		skuType varchar(25),userid nvarchar(100))

	-- setup start and end dates for collecting transactions
	declare @startDate as date, @endDate as date
	-- first date of the prior year
	select @startDate=dateadd(year,DATEDIFF(year,0,dateadd(year,-1,getdate())),0)
	-- date pruir to today's
	select @endDate=dateadd(day,-1,getdate())
	-- collect Sales Orders
	INSERT INTO @tResult
	select 'LG' as [Site],'Sales Order' as txnType,S.ORDERDATE as EntryDate,
		d.due_dts as DateExpected, null as dateActual,
		datepart(year,d.due_dts) as [Year],
		datepart(month,d.due_dts) as [Month],
		datepart(week,d.due_dts) as [Week],
		datepart(quarter,d.due_dts) as [Quarter],
		s.custno as CustomerVendor,c.custname as Name,
		S.sono as orderNo,sd.[Status],C.Internal as interCompany,'0' as Consigned ,
		rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,I.Descript as [Description],
		--sd.uniqueln,I.part_no,I.Revision,
		null as PackingSlip, null as Invoiceno,
		-d.qty as orderQty,0 as txnQty,
		-d.Qty*I.StdCost as extCostUSD ,
		-((CASE WHEN Sd.Ord_Qty<>0 THEN p.TotalPrice/Sd.Ord_Qty ELSE 0 END) * D.Qty ) as extPriceUSD ,
		S.ORDERDATE as entryDateTime,
		CASE WHEN sd.w_key<>' ' THEN LB.Warehouse ELSE LM.Warehouse END AS Warehouse 
		,0 as Bonded
		,CASE WHEN sd.w_key<>' ' THEN LB.MFGR_PT_NO ELSE LM.Mfgr_pt_no END as MfrPartNo,
		RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
		S.SaveInt as userid
		--,userid nvarchar(100)
		--d.due_dts,I.stdcost,p.TotalPrice,Sd.Ord_Qty, p.TotalPrice/Sd.Ord_Qty as UnitPrice,
		from Somain s inner join sodetail sd on s.sono=sd.sono
		inner join inventor i on sd.uniq_key=i.uniq_key
		inner join customer c on s.custno=c.custno
		inner join due_dts d on sd.uniqueln=d.uniqueln and d.qty>0
		cross APPLY (SELECT sp.uniqueln,SUM(case when recordtype='P' then Quantity else 1 end * Price) as TotalPrice 
						from Soprices SP where SP.Uniqueln=Sd.Uniqueln group by sp.uniqueln ) P 
		outer APPLY (select top 1 M.Mfgr_pt_no ,w.Warehouse ,LMpn.Uniq_key
			--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
			from Invtmpnlink LMpn inner join Invtmfgr L on lmpn.uniqmfgrhd=l.uniqmfgrhd 
			INNER JOIN MfgrMaster m ON lmpn.mfgrmasterid=m.mfgrmasterid
			--Invtmfhd M inner join Invtmfgr L on m.uniqmfgrhd=l.uniqmfgrhd 
			inner join warehous w on l.uniqwh=w.uniqwh
			where m.is_deleted=0 and l.is_deleted=0 and  lmpn.is_deleted=0 and sd.w_key=' '
			and w.warehouse<>'MRB' and w.warehouse<>'WO-WIP' and w.warehouse<>'WIP'
			and  lmpn.uniq_key=sd.Uniq_key
			order by lmpn.orderpref,m.mfgr_pt_no) LM
		OUTER APPLY (select  M.Mfgr_pt_no ,w.Warehouse ,lmpn.Uniq_key
		--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
			from InvtmpnLink lmpn inner join Invtmfgr L on lmpn.uniqmfgrhd=l.uniqmfgrhd 
			inner join MfgrMaster M on lmpn.mfgrmasterid=m.mfgrmasterid
			--Invtmfhd M inner join Invtmfgr L on m.uniqmfgrhd=l.uniqmfgrhd 
			inner join warehous w on l.uniqwh=w.uniqwh
			where m.is_deleted=0 and l.is_deleted=0 and lmpn.is_deleted=0 and sd.w_key<>' '
			and w.warehouse<>'MRB' and w.warehouse<>'WO-WIP' and w.warehouse<>'WIP'
			and  l.w_key=sd.w_key) LB
		where 
		--s.sono='0000030359' and 
		--sd.w_key<>'' and
		sd.Status<>'Cancel    '
		and cast(s.ORDERDATE as date) between @startDate and @enddate
		-- rmeove order by later
		--order by s.ORDERDATE,S.SONO

		-- shipping
		;with Shipments
		AS
		( 
		SELECT 'LG' as [Site],'Shipment' as txnType,
		P.ShipDate as EntryDate,
		cast(NULL as Date) as DateExpected,
		-- DateExpected ---need to find record in due_dts table  Date null, 
		P.ShipDate as dateActual,
		datepart(year,P.ShipDate) as [Year],
		datepart(month,P.ShipDate) as [Month],
		datepart(week,P.ShipDate) as [Week],
		datepart(quarter,P.ShipDate) as [Quarter],
		C.Custno as CustomerVendor,
		c.Custname as Name,
		s.Sono as orderNo,
		NULL as [Status],c.internal as interCompany,0 as Consigned,
		rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,I.Descript as [Description],
		p.packlistno as PackingSlip ,p.Invoiceno
		--orderQty -- has to come from due_dts scheduled qty
		,-pd.shippedqty as txnQty,
		-pd.shippedqty*I.stdcost as extCostUSD,
		-pr.extPriceUSD as extPriceUSD,
		p.shipdate as entryDateTime,
		W.Warehouse ,0 as Bonded,w.mfgr_pt_no as mfgrPartNo,
		RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
		p.saveinit as userid,
		--- added pd.Uniqueln to use to find schd dates, wil remove from the result
		pd.UNIQUELN 
		FROM Plmain P INNER JOIN Somain S on p.sono=s.sono
		inner join customer c on s.custno=c.custno
		inner join pldetail PD on p.packlistno=pd.packlistno
		inner join sodetail SD on PD.UniqUeLn=Sd.Uniqueln
		inner join inventor i on sd.uniq_key=I.uniq_key
		CROSS APPLY (select pr.inv_link,SUM(Quantity*Price) as extPriceUSD from Plprices PR where pr.inv_link=pd.inv_link group by pr.inv_link) PR
		cross APPLY (select w.Warehouse,m.mfgr_pt_no 
						from invt_isu I inner join Invtmfgr L on i.w_key=l.w_key
							inner join warehous w on w.uniqwh=l.uniqwh
							--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
							--inner join invtmfhd M on l.uniqmfgrhd=m.uniqmfgrhd
							inner join invtmpnlink lmpn on l.uniqmfgrhd=lmpn.uniqmfgrhd
							inner join mfgrmaster m on lmpn.mfgrmasterid=m.mfgrmasterid
							where i.uniq_key=sd.uniq_key and 
						i.issuedto='REQ PKLST-'+p.packlistno) W
		where 
		--s.sono='0000030359'and 
		cast(P.ShipDate as date) between @startdate and @endDate
		),
		-- get scheduled ship date
		plShip
		as
		(
			select Shipments.orderNo as Sono,dateActual as SHIPDATE, pldetail.UNIQUELN,pldetail.PACKLISTNO,pldetail.SHIPPEDQTY,
			SUM(SHIPPEDQTY) OVER( partition by orderNo,pldetail.uniqueln ORDER BY dateActual ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS RunningShippedQty
			from pldetail inner join Shipments on pldetail.packlistno=Shipments.PackingSlip and
			pldetail.UNIQUELN=Shipments.UNIQUELN

		),
		SDue as
		(
			select due_dts.SHIP_DTS,due_dts.UNIQUELN,due_dts.ACT_SHP_QT ,
			SUM(ACT_SHP_QT) OVER(partition by sono,uniqueln ORDER BY SHIP_DTS ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS RunningDueShippedQty
			from due_dts  
			where EXISTS (select 1 from plShip where plship.sono=due_dts.sono and plship.UNIQUELN=DUE_DTS.UNIQUELN)   
		),
		actionrows AS (
		SELECT t.sono, t.packlistno,t.uniqueln,t.shipDate, g.ship_dts, t.ShippedQty AS TransQty, g.Act_shp_qt, 
          t.RunningShippedQty AS TransTotQty, g.RunningDueShippedQty AS SchdTotQty,
          --LAG(t.ShippedQty, 1, 0) OVER(ORDER BY t.ShipDate, g.Ship_dts) AS PrevTransQty,
          --LAG(g.RunningDueShippedQty, 1, 0) OVER(ORDER BY t.ShipDate, g.Ship_dts) AS PrevSchdQty,
		  ROW_NUMBER() OVER (Partition by t.Packlistno,t.UniqueLn order by g.Ship_dts) as n
		 FROM   plShip t
		CROSS JOIN SDue g 
	   WHERE  t.RunningShippedQty - t.ShippedQty < g.RunningDueShippedQty
		 AND  g.RunningDueShippedQty-g.Act_shp_qt < t.RunningShippedQty
		)
		--select * from actionrows
		-- populate DateExpected with the first schd date against which the shipment was made
		INSERT INTO @tResult
		SELECT [Site],txnType,
		EntryDate,
		ISNULL(A.ship_dts,S.dateActual) as DateExpected,
		-- DateExpected ---need to find record in due_dts table  Date null, 
		dateActual,
		[Year],
		[Month],
		[Week],
		[Quarter],
		CustomerVendor,
		[Name],
		orderNo,
		[Status],
		interCompany,
		Consigned,
		SKU,
		[Description],
		PackingSlip ,
		Invoiceno,
		ISNULL(-A.Act_shp_qt,txnQty) as orderQty, -- has to come from due_dts scheduled qty
		txnQty,
		extCostUSD,
		extPriceUSD,
		entryDateTime,
		Warehouse ,
		Bonded,
		mfgrPartNo,
		skuType,
		userid 
		FROM Shipments S LEFT OUTER JOIN actionrows A  
		ON S.orderNo=A.Sono and S.PackingSlip=A.PACKLISTNO
		and S.UNIQUELN=A.UNIQUELN and A.n=1
		-- rmeove order by later
		--order by dateActual,orderNo

		--- purchase orders
		INSERT INTO @tResult
		SELECT 'LG' as [Site],
			'Purchase Order ' as txnType,
			 PO.Podate as EntryDate,
			 POS.SCHD_DATE as DateExpected , CAST(NULL AS DATE) AS dateActual,
			 datepart(year, POS.SCHD_DATE) as [Year],
			 datepart(month, POS.SCHD_DATE) as [Month],
			 datepart(week, POS.SCHD_DATE) as [Week],
			 datepart(quarter, POS.SCHD_DATE) as [Quarter],
			 S.Supid as CustomerVendor,
			 S.Supname as Name,
			 PO.Ponum as orderNo,
			 'Open' as [Status],
			 S.Internal as interCompany,
			 0 as Consigned, 
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 NULL as PackingSlip,
			 NULL as Invoiceno,
			 POS.Balance as orderQty,
			 0 as txnQty,
			 POS.Balance*POD.CostEach as extCostUSD,
			0 as extPriceUSD,
			PO.Podate as entryDateTime,
			ISNULL(W.Warehouse,space(10)) as Warehouse, 
			0 as Bonded,
			POD.Mfgr_pt_no as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			po.VERINIT as userid
		FROM Pomain PO INNER JOIN POITEMS POD ON PO.Ponum=POD.PONum
		INNER JOIN Inventor I on POD.uniq_key=I.Uniq_key
		INNER JOIN POITSCHD POS ON POD.UNIQLNNO=POS.UniqLnno
		INNER JOIN Supinfo S on PO.Uniqsupno=S.UniqSUpno
		LEFT OUTER JOIN Warehous W on POS.uniqwh=W.uniqwh
		WHERE POSTATUS<>'Closed' and POSTATUS<>'Cancel'
		and POD.LCANCEL=0
		AND POS.BALANCE>0 
		and cast(PO.PODATE as date) between @startDate and @enddate
		-- remove order by later
		--order by podate,po.ponum

		--- po receipts
		INSERT INTO @tResult
		SELECT 'LG' as [Site],
			'Receipt' as txnType,
			 PR.RECVDATE as EntryDate,
			 POS.SCHD_DATE as DateExpected , 
			 PR.RECVDATE AS dateActual,
			 datepart(year, PR.RECVDATE) as [Year],
			 datepart(month, PR.RECVDATE) as [Month],
			 datepart(week, PR.RECVDATE) as [Week],
			 datepart(quarter, PR.RECVDATE) as [Quarter],
			 S.Supid as CustomerVendor,
			 S.Supname as Name,
			 PO.Ponum as orderNo,
			 NULL as [Status],
			 S.Internal as interCompany,
			 0 as Consigned, 
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 PR.PORECPKNO as PackingSlip,
			 ISNULL(SI.INVNO ,SPACE(20)) as Invoiceno,
			 POS.SCHD_QTY as orderQty,
			 PRL.ACCPTQTY+CASE WHEN DMR.DMR_NO ='' OR DMR.DMR_NO IS NULL THEN  PRL.REJQTY ELSE 0 END as txnQty,
			 (PRL.ACCPTQTY+CASE WHEN DMR.DMR_NO ='' OR DMR.DMR_NO IS NULL THEN  PRL.REJQTY ELSE 0 END)*POD.CostEach as extCostUSD,
			 0 as extPriceUSD,
			 PR.RECVDATE as entryDateTime,
			ISNULL(W.Warehouse,space(10)) as Warehouse, 
			0 as Bonded,
			PR.Mfgr_pt_no as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			--02/03/17 YS need to change the code with the new receiving process 
			cast('' as nvarchar(100))as userid
			--pr.RECINIT as userid
		FROM PORECDTL PR INNER JOIN Porecloc PRL ON PR.UNIQRECDTL=PRL.FK_UNIQRECDTL
		INNER JOIN POITEMS POD ON PR.UNIQLNNO=POD.UNIQLNNO
		INNER JOIN POMAIN PO on POD.ponum=po.ponum
		INNER JOIN Inventor I on POD.uniq_key=I.Uniq_key
		INNER JOIN POITSCHD POS ON PRL.UNIQDETNO=POS.Uniqdetno
		INNER JOIN Supinfo S on PO.Uniqsupno=S.UniqSUpno
		left outer join porecmrb DMR on PR.UNIQRECDTL=DMR.FK_UNIQRECDTL
		LEFT OUTER JOIN Warehous W on PRL.uniqwh=W.uniqwh
		LEFT OUTER JOIN Sinvoice SI ON PR.RECEIVERNO=SI.receiverno and PR.PORECPKNO=SI.SUPPKNO
		where cast(PR.RECVDATE as date) between @startDate and @enddate
		-- remove order by later
		--order by RECVDATE,po.ponum

		--- work order
		INSERT INTO @tResult
		SELECT 'LG' as [Site],
			'Work Order ' as txnType,
			 WO.ORDERDATE as EntryDate,
			 WO.DUE_DATE as DateExpected , CAST(NULL AS DATE) AS dateActual,
			 datepart(year,  WO.DUE_DATE) as [Year],
			 datepart(month,  WO.DUE_DATE) as [Month],
			 datepart(week,  WO.DUE_DATE) as [Week],
			 datepart(quarter,  WO.DUE_DATE) as [Quarter],
			 WO.CUSTNO as CustomerVendor,
			 C.Custname as Name,
			 WO.WONO as orderNo,
			 'Open' as [Status],
			 C.Internal as interCompany,
			 0 as Consigned, 
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 NULL as PackingSlip,
			 NULL as Invoiceno,
			 WO.Balance as orderQty,
			 0 as txnQty,
			 WO.Balance*I.StdCost as extCostUSD,
			 0 as extPriceUSD,
			 WO.ORDERDATE as entryDateTime,
			ISNULL(LM.Warehouse,space(10)) as Warehouse, 
			0 as Bonded,
			ISNULL(LM.Mfgr_pt_no,space(30)) as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			-- I think we are missing user that created the po. Check again later
			wo.KITSTARTINIT as userid
		FROM WOENTRY WO INNER JOIN Customer C On WO.CUSTNO=C.CUSTNO
		INNER JOIN Inventor I on WO.uniq_key=I.Uniq_key
		outer APPLY (select top 1 M.Mfgr_pt_no ,w.Warehouse ,lmpn.Uniq_key
			--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
			from Invtmpnlink lmpn inner join Invtmfgr L on lmpn.UniqMfgrhd=l.uniqmfgrhd
			inner join mfgrmaster m on lmpn.mfgrmasterid=m.mfgrmasterid
			--Invtmfhd M inner join Invtmfgr L on m.uniqmfgrhd=l.uniqmfgrhd 
			inner join warehous w on l.uniqwh=w.uniqwh
			where m.is_deleted=0 and l.is_deleted=0 and lmpn.is_deleted=0 and 
			w.warehouse<>'MRB' and w.warehouse<>'WO-WIP' and w.warehouse<>'WIP'
			and  lmpn.uniq_key=wo.Uniq_key
			order by lmpn.orderpref,mfgr_pt_no) LM
		WHERE wo.OPENCLOS<>'Closed' and wo.openclos<>'Cancel'
		and wo.BALANCE>0 
		and cast(wo.ORDERDATE as date) between @startDate and @enddate
		-- remove order by later
		--order by wo.ORDERDATE,wo.WONO


		--- Production 
		---	information for FGI transferred into FGI
		INSERT INTO @tResult
		SELECT 'LG' as [Site],
			'Production ' as txnType,
			 IR.[DATE] as EntryDate,
			 WO.DUE_DATE as DateExpected , 
			 IR.[DATE] AS dateActual,
			 datepart(year,   IR.[DATE]) as [Year],
			 datepart(month,  IR.[DATE]) as [Month],
			 datepart(week,   IR.[DATE]) as [Week],
			 datepart(quarter,   IR.[DATE]) as [Quarter],
			 WO.CUSTNO as CustomerVendor,
			 C.Custname as Name,
			 WO.WONO as orderNo,
			 NULL as [Status],
			 C.Internal as interCompany,
			 0 as Consigned, 
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 NULL as PackingSlip,
			 NULL as Invoiceno,
			 WO.BLDQTY as orderQty,
			 IR.QTYREC as txnQty,
			 IR.QTYREC*I.StdCost as extCostUSD,
			 0 as extPriceUSD,
			 WO.ORDERDATE as entryDateTime,
			W.Warehouse as Warehouse, 
			0 as Bonded,
			M.Mfgr_pt_no as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			-- I think we are missing user that created the po. Check again later
			IR.SAVEINIT as userid
		FROM Invt_rec IR  inner join WOENTRY WO on RIGHT(RTRIM(IR.CommRec),10)=wo.WONO 
		INNER JOIN Customer C On WO.CUSTNO=C.CUSTNO
		INNER JOIN Inventor I on WO.uniq_key=I.Uniq_key
		--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
		--INNER JOIN Invtmfhd M on M.UNIQMFGRHD=IR.UniqMfgrhd 
		inner join Invtmpnlink lmpn on IR.uniqmfgrhd=lmpn.Uniqmfgrhd
		inner join Mfgrmaster M on lmpn.mfgrmasterid=m.mfgrmasterid
		inner join Invtmfgr L on l.w_key=IR.W_key 
		inner join warehous w on l.uniqwh=w.uniqwh
		WHERE IR.COMMREC LIKE 'WIP-FGI%' 
		and cast(ir.[DATE] as date) between @startDate and @enddate
		-- remove order by later
		--order by ir.DATE,wo.WONO
		--- components issued to a job (during the kitting)
		-- ??? do we need to have (-) in fornt of the order qty?
		--- ? if part is consign should we show customer part number or internal part number in the 'SKU' column?
		INSERT INTO @tResult
		SELECT 'LG' as [Site],
			-- production if issued to a work order
			-- Other if other issues
			CASE WHEN Wo.Wono is null then 'Other' else 'Production ' end as txnType,
			 ISSUE.[DATE] as EntryDate,
			 ISNULL(WO.DUE_DATE,NULL) as DateExpected , 
			 ISSUE.[DATE] AS dateActual,
			 datepart(year,   ISSUE.[DATE]) as [Year],
			 datepart(month,  ISSUE.[DATE]) as [Month],
			 datepart(week,   ISSUE.[DATE]) as [Week],
			 datepart(quarter,   ISSUE.[DATE]) as [Quarter],
			 ISNULL(WO.CUSTNO,space(10)) as CustomerVendor,
			 isnull(C.Custname,cast('' as varchar(50))) as Name,
			 ISSUE.WONO as orderNo,
			 NULL as [Status],
			 isnull(C.Internal,0) as interCompany,
			 CASE WHEN I.Part_sourc='CONSG' THEN 1 ELSE 0 END as Consigned, 
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 NULL as PackingSlip,
			 NULL as Invoiceno,
			 ISNULL(WO.BLDQTY,0) as orderQty,
			 -ISSUE.QTYISU as txnQty,
			 -ISSUE.QTYISU*I.StdCost as extCostUSD,
			 0 as extPriceUSD,
			 ISNULL(WO.ORDERDATE,ISSUE.[Date]) as entryDateTime,
			W.Warehouse, 
			0 as Bonded,
			M.Mfgr_pt_no as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			ISSUE.SAVEINIT as userid
		FROM Invt_isu ISSUE  left outer join WOENTRY WO on ISSUE.WOno=WO.wono 
		LEFT OUTER JOIN Customer C On WO.CUSTNO=C.CUSTNO
		INNER JOIN Inventor I on WO.uniq_key=I.Uniq_key
		--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
		--INNER JOIN Invtmfhd M on M.UNIQMFGRHD=ISSUE.UniqMfgrhd 
		INNER JOIN Invtmpnlink lmpn on issue.uniqmfgrhd=lmpn.uniqmfgrhd
		inner join MfgrMaster M on lmpn.mfgrmasterid=m.mfgrmasterid
		inner join Invtmfgr L on l.w_key=ISSUE.W_key 
		inner join warehous w on l.uniqwh=w.uniqwh
		WHERE ISSUE.IssuedTo NOT LIKE 'REQ PKLST%' 
		and cast(ISSUE.[DATE] as date) between @startDate and @enddate
		-- remove order by later
		--order by ISSUE.DATE,ISSUE.WONO
	
		--- inventory receiving (other than FGI)
		INSERT INTO @tResult
		SELECT 'LG' as [Site],
			'Other' as txnType,
			 IR.[DATE] as EntryDate,
			 NULL as DateExpected , 
			 IR.[DATE] AS dateActual,
			 datepart(year,   IR.[DATE]) as [Year],
			 datepart(month,  IR.[DATE]) as [Month],
			 datepart(week,   IR.[DATE]) as [Week],
			 datepart(quarter,   IR.[DATE]) as [Quarter],
			 space(10) as CustomerVendor,
			 cast('' as varchar(50)) as Name,
			 space(10) as orderNo,
			 NULL as [Status],
			 0 as interCompany,
			 CASE WHEN I.Part_sourc='CONSG' THEN 1 ELSE 0 END as Consigned,
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 NULL as PackingSlip,
			 NULL as Invoiceno,
			 0 as orderQty,
			 IR.QTYREC as txnQty,
			 IR.QTYREC*I.StdCost as extCostUSD,
			 0 as extPriceUSD,
			 IR.[DATE] as entryDateTime,
			W.Warehouse as Warehouse, 
			0 as Bonded,
			M.Mfgr_pt_no as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			-- I think we are missing user that created the po. Check again later
			IR.SAVEINIT as userid
		FROM Invt_rec IR  
		INNER JOIN Inventor I on IR.uniq_key=I.Uniq_key
		--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
		--INNER JOIN Invtmfhd M on M.UNIQMFGRHD=IR.UniqMfgrhd 
		INNER JOIN Invtmpnlink lmpn on IR.Uniqmfgrhd=lmpn.Uniqmfgrhd
		inner join MfgrMaster m on lmpn.mfgrmasterid=m.mfgrmasterid
		inner join Invtmfgr L on l.w_key=IR.W_key 
		inner join warehous w on l.uniqwh=w.uniqwh
		WHERE IR.COMMREC NOT LIKE 'WIP-FGI%' 
		and cast(ir.[DATE] as date) between @startDate and @enddate
		-- remove order by later
		--order by ir.DATE
		
		--- inventory transfer
		INSERT INTO @tResult
		SELECT 'LG' as [Site],
			'Other Transfer' as txnType,
			 X.[DATE] as EntryDate,
			 ISNULL(WO.DUE_DATE,NULL) as DateExpected , 
			 X.[DATE] AS dateActual,
			 datepart(year,   X.[DATE]) as [Year],
			 datepart(month,  X.[DATE]) as [Month],
			 datepart(week,   X.[DATE]) as [Week],
			 datepart(quarter,   X.[DATE]) as [Quarter],
			 ISNULL(WO.CUSTNO,space(10)) as CustomerVendor,
			 isnull(C.Custname,cast('' as varchar(50))) as Name,
			 X.WONO as orderNo,
			 NULL as [Status],
			 isnull(C.Internal,0) as interCompany,
			 CASE WHEN I.Part_sourc='CONSG' THEN 1 ELSE 0 END as Consigned, 
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 NULL as PackingSlip,
			 NULL as Invoiceno,
			 ISNULL(WO.BLDQTY,0) as orderQty,
			 -X.QTYXFER as txnQty,
			 -X.QTYXFER*I.StdCost as extCostUSD,
			 0 as extPriceUSD,
			 ISNULL(WO.ORDERDATE,X.[Date]) as entryDateTime,
			W.Warehouse, 
			0 as Bonded,
			M.Mfgr_pt_no as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			X.SAVEINIT as userid
		FROM InvtTrns X  left outer join WOENTRY WO on X.WOno=WO.wono 
		LEFT OUTER JOIN Customer C On WO.CUSTNO=C.CUSTNO
		INNER JOIN Inventor I on X.uniq_key=I.Uniq_key
		--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
		--INNER JOIN Invtmfhd M on M.UNIQMFGRHD=X.UniqMfgrhd 
		--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
		INNER JOIN Invtmpnlink lmpn on X.Uniqmfgrhd=lmpn.Uniqmfgrhd
		inner join MfgrMaster m on lmpn.mfgrmasterid=m.mfgrmasterid
		inner join Invtmfgr L on l.w_key=X.FROMWKEY 
		inner join warehous w on l.uniqwh=w.uniqwh
		WHERE cast(X.[DATE] as date) between @startDate and @enddate
		UNION 
		SELECT 'LG' as [Site],
			'Other ' as txnType,
			 X.[DATE] as EntryDate,
			 ISNULL(WO.DUE_DATE,NULL) as DateExpected , 
			 X.[DATE] AS dateActual,
			 datepart(year,   X.[DATE]) as [Year],
			 datepart(month,  X.[DATE]) as [Month],
			 datepart(week,   X.[DATE]) as [Week],
			 datepart(quarter,   X.[DATE]) as [Quarter],
			 ISNULL(WO.CUSTNO,space(10)) as CustomerVendor,
			 isnull(C.Custname,cast('' as varchar(50))) as Name,
			 X.WONO as orderNo,
			 NULL as [Status],
			 isnull(C.Internal,0) as interCompany,
			 CASE WHEN I.Part_sourc='CONSG' THEN 1 ELSE 0 END as Consigned, 
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 NULL as PackingSlip,
			 NULL as Invoiceno,
			 ISNULL(WO.BLDQTY,0) as orderQty,
			 X.QTYXFER as txnQty,
			 X.QTYXFER*I.StdCost as extCostUSD,
			 0 as extPriceUSD,
			 ISNULL(WO.ORDERDATE,X.[Date]) as entryDateTime,
			W.Warehouse, 
			0 as Bonded,
			M.Mfgr_pt_no as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			X.SAVEINIT as userid
		FROM InvtTrns X  left outer join WOENTRY WO on X.WOno=WO.wono 
		LEFT OUTER JOIN Customer C On WO.CUSTNO=C.CUSTNO
		INNER JOIN Inventor I on X.uniq_key=I.Uniq_key
		--INNER JOIN Invtmfhd M on M.UNIQMFGRHD=X.UniqMfgrhd 
		--02/08/16 YS remove Invtmfhd table and use invtmpnlink and mfgrmaster
		INNER JOIN Invtmpnlink lmpn on X.Uniqmfgrhd=lmpn.Uniqmfgrhd
		inner join MfgrMaster m on lmpn.mfgrmasterid=m.mfgrmasterid
		inner join Invtmfgr L on l.w_key=X.TOWKEY 
		inner join warehous w on l.uniqwh=w.uniqwh
		WHERE cast(X.[DATE] as date) between @startDate and @enddate
		-- remove order by later
		--order by 3
		---RMA
		--- RMA Receiving
		---DMR
		INSERT INTO @tResult
		SELECT 'LG' as [Site],
			'Purchase Receipt' as txnType,
			 DMR.REJ_DATE as EntryDate,
			 NULL as DateExpected , 
			 DMR.RMA_DATE  AS dateActual,
			 datepart(year, DMR.RMA_DATE) as [Year],
			 datepart(month, DMR.RMA_DATE) as [Month],
			 datepart(week, DMR.RMA_DATE) as [Week],
			 datepart(quarter, DMR.RMA_DATE) as [Quarter],
			 S.Supid as CustomerVendor,
			 S.Supname as Name,
			 PO.Ponum as orderNo,
			 NULL as [Status],
			 S.Internal as interCompany,
			 0 as Consigned, 
			 rtrim(I.Part_no)+' '+RTRIM(I.Revision) as SKU,
			 I.Descript as [Description],
			 DMR.RMA_NO as PackingSlip,
			 SPACE(20) as Invoiceno,
			 0 as orderQty,
			 -DMR.RET_QTY as txnQty,
			 -DMR.RET_QTY*POD.CostEach as extCostUSD,
			 0 as extPriceUSD,
			 DMR.REJ_DATE as entryDateTime,
			'MRB' as Warehouse, 
			0 as Bonded,
			PR.Mfgr_pt_no as mfgrPartNo,
			RTRIM(I.Part_class)+' '+RTRIM(I.Part_type) as skuType,
			--02/03/17 YS need to change the code with the new receiving process 
			cast('' as nvarchar(100))as userid
			--pr.RECINIT as userid
		FROM PORECMRB DMR INNER JOIN 
		PORECDTL PR ON PR.UNIQRECDTL=DMR.FK_UNIQRECDTL
		INNER JOIN POITEMS POD ON PR.UNIQLNNO=POD.UNIQLNNO
		INNER JOIN POMAIN PO on POD.ponum=po.ponum
		INNER JOIN Inventor I on POD.uniq_key=I.Uniq_key
		INNER JOIN Supinfo S on PO.Uniqsupno=S.UniqSUpno
		where cast(DMR.REJ_DATE as date) between @startDate and @enddate
		-- remove order by later
	--	order by REJ_DATE,po.ponum


	select * from @tResult

END