-- =============================================
-- Author:		Yelena/Vicky
-- Create date: 11/20/19
-- Description:	Get consigned parts of the BOM for the product in open SO, calculate reqDate from SO ship date, and available/shortag information
-- Modification:
-- 08/17/20 VL added customer filter
-- =============================================
CREATE PROCEDURE [dbo].[rptKitConsgMaterialRequest]
	
@userid uniqueidentifier = null
	
AS
BEGIN

-- 08/17/20 VL added customer filter
DECLARE  @tCustomer as tCustomer    
INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;  

IF OBJECT_ID('tempdb..#consignPartList') is not null
DROP TABLE #consignPartList
IF OBJECT_ID('tempdb..#consignPartCalc') is not null
DROP TABLE #consignPartCalc
IF object_id('tempdb..#wo') is not null
DROP TABLE  #wo
IF object_id('tempdb..#runtotal') is not null
DROP TABLE  #runtotal

-- Get all products from open SO that having CONSG parts in BOM
SELECT s.Sono, s.Custno,s.PONO, sd.LINE_NO, sd.UNIQUELN, sd.UNIQ_KEY AS Productuniqkey, P.Part_no AS ProductNo, P.Revision AS ProdRev,
	c.PART_NO,c.REVISION,c.CUSTPARTNO,c.CUSTREV,C.UNIQ_KEY, b.qty AS Qtyeach, cust.CUSTNAME, d.SHIP_DTS, d.QTY-d.ACT_SHP_QT AS Balancedue, 
	--(d.QTY-d.ACT_SHP_QT)*b.QTY as reqQty,
	CASE WHEN LEFT(C.U_of_meas,2)='EA' THEN 
		CAST(CEILING(((d.QTY-d.ACT_SHP_QT)*b.QTY )+(((d.QTY-d.ACT_SHP_QT)*b.QTY)*C.Scrap)/100)+CASE WHEN P.UseSetScrp = 1 AND (d.QTY-d.ACT_SHP_QT)*b.QTY <>0 THEN C.SetupScrap ELSE 0 END AS Numeric(12,2))	
	ELSE
		CAST(ROUND(((d.QTY-d.ACT_SHP_QT)*b.QTY )+(((d.QTY-d.ACT_SHP_QT)*b.QTY )*C.Scrap)/100,2)+CASE WHEN P.UseSetScrp = 1 AND (d.QTY-d.ACT_SHP_QT)*b.QTY <>0 THEN C.SetupScrap ELSE 0 END AS Numeric(12,2))
	END AS ReqQty,
	--SUM((d.QTY-d.ACT_SHP_QT)*b.QTy) OVER( partition by custname,b.uniq_key ORDER BY ship_dts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS runningReqQty,
	CAST(isnull(t.qtyAvial,0.00) AS numeric(12,2)) as QtyOHandKitted,
	CAST(isnull(t.qtyAvial,0.00) AS numeric(12,2)) as InvtQtyOnHand,
	CAST(0.00 AS numeric(12,2)) as KittedQty
	-- 11/20/19 VL added leadtime and ReqDate
	,P.Prod_ltime*(CASE WHEN P.Prod_lunit = 'DY' THEN 1 
						     WHEN P.Prod_lunit = 'WK' THEN 5 
						     WHEN P.Prod_lunit = 'MO' THEN 20 ELSE 1 END) + 
				P.Kit_ltime*(CASE WHEN P.Kit_lunit = 'DY' THEN 1 
						        WHEN P.Kit_lunit = 'WK' THEN 5 
								WHEN P.Kit_lunit = 'MO' THEN 20 ELSE 1 END) AS ProdLeadTime
	,CAST('' AS smalldatetime) AS ReqDate
	INTO #consignPartList
	FROM Somain s INNER JOIN SODETAIL sd ON s.sono=sd.sono
	INNER JOIN bom_det b ON sd.UNIQ_KEY=b.bomparent
	INNER JOIN inventor c ON b.UNIQ_KEY=c.UNIQ_KEY
	INNER JOIN customer cust ON s.CUSTNO=cust.custno
	INNER JOIN DUE_DTS d ON sd.UNIQUELN=d.UNIQUELN
	-- 11/19/19 VL added for parent part scrap setting
	INNER JOIN inventor P ON P.Uniq_key = sd.Uniq_key
	OUTER APPLY
	(SELECT SUM(qty_oh)-SUM(reserved) AS QtyAvial FROM Invtmfgr WHERE Invtmfgr.UNIQ_KEY=c.UNIQ_KEY) t
	WHERE c.part_sourc='CONSG     '
	AND s.ORD_TYPE='Open'
	AND sd.BALANCE>0
	AND sd.[STATUS] NOT IN ('Closed','Cancel')
	AND d.QTY-d.ACT_SHP_QT>0
	-- 08/17/20 VL added customer filter
	AND EXISTS (SELECT 1 FROM @tCustomer T WHERE T.Custno = cust.Custno)
	ORDER BY CUSTNAME,c.uniq_key,d.SHIP_DTS

-- Get all the WO created for the product and kit has picked qty for the CONSG parts
SELECT cust.Custname, w.Wono, w.UNIQ_KEY AS Productkey, w.DUE_DATE, w.Custno, k.UNIQ_KEY, k.ACT_QTY
	INTO #wo
	FROM Woentry w INNER JOIN Kamain k ON w.Wono = k.Wono
	INNER JOIN Customer cust ON w.Custno = cust.Custno
	WHERE Openclos NOT LIKE 'C%' AND w.Kit = 1
	AND k.ACT_QTY > 0 
	AND EXISTS (SELECT 1 FROM #consignPartList c WHERE c.Productuniqkey = w.UNIQ_KEY AND k.UNIQ_KEY=c.UNIQ_KEY
				-- 11/19/19 VL added custno criteria
				AND c.CUSTNO = w.CUSTNO)  
	ORDER BY Custname,k.uniq_key,DUE_DATE


-- QtyOHandKitted is udpated for calculation purpose
UPDATE #consignPartList SET QtyOHandKitted = QtyOHandKitted + Sum_qty,
							KittedQty=sum_qty
	FROM
	(SELECT ISNULL(SUM(act_qty),0) AS Sum_qty, UNIQ_KEY
		FROM #wo 
		GROUP BY  UNIQ_KEY) t 
	WHERE t.UNIQ_KEY=[#consignPartList].UNIQ_KEY
	

	
-- Calculate Leadtime and ReqDate
;WITH
	Leadt AS 
	(
		SELECT Productuniqkey, Ship_dts, h.SubLeadTime
		FROM #consignPartList t 
		CROSS APPLY (SELECT Subleadtime from dbo.fnGetTotalLeadTimeAndCount(t.Productuniqkey,t.Ship_dts) ) H
	)
UPDATE #consignPartList
	SET ProdLeadTime = ProdLeadTime + ISNULL(l.SubLeadTime,0),
		ReqDate=dbo.fn_GetWorkDayWithOffset(l.Ship_dts, ProdLeadTime+ISNULL(l.SubLeadTime,0), '-')
		FROM Leadt L 
		WHERE l.Productuniqkey=[#consignPartList].Productuniqkey
		AND l.SHIP_DTS = [#consignPartList].SHIP_DTS


-- Get running ReqQty column
SELECT *, SUM(Reqqty) OVER(partition by custname,uniq_key ORDER BY ship_dts ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) AS runningReqQty
	INTO #runtotal
	FROM #consignPartList 
	ORDER BY CUSTNAME,uniq_key,SHIP_DTS

-- get PrevTotReq
SELECT c.*,LAG(runningReqQty, 1, 0) OVER(partition by custname,uniq_key ORDER BY ship_dts) AS PrevTotReq 
	INTO #consignPartCalc
	FROM #runtotal c
	WHERE runningReqQty>0
	ORDER BY custname,UNIQ_KEY

--SELECT [#consignPartCalc].*,
SELECT Sono, Custno, Pono, Line_no, Custname, ProductNo, ProdRev, Part_no, Revision, CustPartno, CustRev, QtyEach, Ship_dts, BalanceDue, ReqQty, InvtQtyOnHand, KittedQty AS TotalKitted, QtyOHandKitted, ProdLeadTime, ReqDate, --runningReqQty, PrevTotReq, 
CASE 
WHEN QtyOHandKitted-PrevTotReq<=0 THEN 0
WHEN QtyOHandKitted-PrevTotReq>=reqQty THEN reqQty
ELSE QtyOHandKitted-PrevTotReq END AS Avail2use,
ReqQty-
CASE 
WHEN QtyOHandKitted-PrevTotReq<=0 THEN 0
WHEN QtyOHandKitted-PrevTotReq>=reqQty THEN reqQty
ELSE QtyOHandKitted-PrevTotReq END AS Shortage,
Uniqueln, Productuniqkey, Uniq_key
  FROM #consignPartCalc
  ORDER BY custname,UNIQ_KEY

END