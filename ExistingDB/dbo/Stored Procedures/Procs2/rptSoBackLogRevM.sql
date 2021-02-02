
-- =============================================  
-- Author:  <Vicky and Debbie>   
-- Create date: <11/17/2010>  
-- Last Modified: <06/28/2011 by Debbie>  
-- Description: <compiles detailed sales order Backlog Revenue/Margin Summary information>  
-- Reports:  used on bgrvbytr.rpt, bgrbbyrp.rpt,bgrvbyst,bgrvbycu,bgrvbycp  
-- Modified: 08/26/13 YS   changed first name/last name to varchar(100), increased length of the ccontact fields.  
-- 03/26/14 DRP:  Territory char(12) needed to be changed to Territory char(15)  
-- 04/02/2015 DRP:  Found that I needed to remove the CASE WHEN ROW_NUMBER() OVER(Partition . . . for Due_dtsQty and Due_dtsBal, because there are scenarios where the users will have the same Schedule dates multiple times.  
-- 11/08/15 DRP: Making changes to the procedure to work with WebManex.  Added all of the parameters, /*TERRITORY LIST*/.  Added the following fields to the results UsedDate, FurtureStartDt,MaxDt,MaxDt date,MinDt date,M1h,M2h,M3h,M4h,M5h,M6h  
--     Added the @lcSort parameter and added the Sort Sections at the end of the procedure.   
-- 11/12/15 DRP:  believe that I can run the bgrvbycu and bgrvbycp reports using this same procedure.  Just need to add the @lcCustNo parameter here.  This procedure can then replace [rptSoBackLogRevDtl]  
-- 03/28/17 VL:  the code created on 11/22/10 created multiple records, but should only show one record for the 'NOT SCHEDULED' part  
-- 07/18/17 DRP:  within the "IF  @lcTerritory='All'"  section I actually inserted a Blank record into the results  
--      This will hopefully address the situation if the customers did not setup any Territories and it should then also handle possible situations that Territoried exist in setup but the user did not assign Territories to any or some of the Customers.  Now when they Select ALL Territories they will get any results with blank Territories also     
-- 08/16/17 VL:  added functional currency code 
-- 07/16/18 VL changed custname from char(35) to char(50) 
-- 01/02/19 Shrikant B: Changed  @userId from UNIQIDENTIFIER to VARCHAR(40) for fixed the conversion problem
-- 01/04/19 Shrikant B: Changed  Reverts @userId Changes from  VARCHAR(40) to UNIQUEIDENTIFIER 
-- 05/05/20 VL: Only get top 1 sales rep so if the uniqueln has multiple sales rep, the report doesn't get duplicate record
-- 05/07/20 VL: Added CAST( AS DATE) to make the getdate() as date type, also update sales rep name separately to speed up
-- =============================================  
CREATE PROCEDURE [dbo].[rptSoBackLogRevM]   
  
--declare  
 @lcUseDt CHAR(15) = 'Commit Date'  --Due Date, Ship Date or Commit Date  
 ,@lcBkLogType CHAR(10) = 'Revenue'  --Revenue, Margin  
 ,@lcTerritory VARCHAR(max) = 'All'  
 ,@lcNoDays NUMERIC(3,0)  = 720   --Number of days to calculate past Due and future Revenue/Margins  
 ,@lcSort CHAR(15) = 'by Customer/PO'  -- by Territory,by Sales Rep, by Sales Type,by Customer,by Customer/PO  
 ,@lcCustno VARCHAR(max) = 'All' 
 -- 01/02/19 Shrikant B: Changed  @userId from UNIQIDENTIFIER to VARCHAR(40) for fixed the conversion problem 
 -- 01/04/19 Shrikant B: Changed  Reverts @userId Changes from  VARCHAR(40) to UNIQUEIDENTIFIER 
 ,@userId UNIQUEIDENTIFIER = null  
  
AS  
BEGIN  
  
  
/*TERRITORY LIST*/  
 ---- SET NOCOUNT ON added to prevent extra result sets from  
 ---- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 DECLARE  @tTerritory AS TABLE (uniqfield CHAR(10),Territory CHAR(15))  
  DECLARE @Territory AS TABLE (Territory CHAR(15))  
  
 insert into @tTerritory SELECT uniqfield,left(TEXT,15) FROM support WHERE fieldname = 'TERRITORY' ORDER BY Number  
 --select * from @tTerritory   
   
  --- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned  
 IF @lcTerritory is not null and @lcTerritory <>'' and @lcTerritory<>'All'  
  insert into @Territory select * from dbo.[fn_simpleVarcharlistToTable](@lcTerritory,',')  
   where CAST (id as CHAR(15)) in (select Territory from @tTerritory)  
 ELSE  
 --- empty or null customer or part number means no selection were made  
 IF  @lcTerritory='All'   
 BEGIN  
  INSERT INTO @Territory SELECT left(text,15) from support WHERE fieldname = 'TERRITORY' ORDER BY Number  
  insert into @Territory (Territory) values ('')  --07/18/17 DRP:  added Blank record to results  
   
 END  
  
 --select * from @Territory  
  
  
  
/*CUSTOMER LIST*/    
 DECLARE  @tCustomer as tCustomer  
  DECLARE @Customer TABLE (custno char(10))  
  -- get list of customers for @userid with access  
  INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;  
  --SELECT * FROM @tCustomer   
    
  IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'  
   insert into @Customer select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')  
     where CAST (id as CHAR(10)) in (select CustNo from @tCustomer)  
  ELSE  
  
  IF  @lcCustNo='All'   
  BEGIN  
   INSERT INTO @Customer SELECT CustNo FROM @tCustomer  
  END  
  
  --select * from @Customer  
/*RECORD SELECT SECTION*/  
  
-- 08/26/13 YS   changed first name/last name to varchar(100), increased length of the ccontact fields.  
-- 08/16/17 VL added functional currency code  
-- 07/16/18 VL changed custname from char(35) to char(50)  
DECLARE @ZSoBackLogPrep TABLE (Custname char(50), Sono char(10), OrderDate smalldatetime, Pono char(20), Uniqueln char(10),   
 Line_no char(7), Part_no char(45), Revision char(8), Part_class char(8), Part_type char(8), Descriptio char(45),uniq_key char(10), Ship_dts Smalldatetime,   
 Due_dts SmallDateTime, COMMIT_DTS SmallDateTime, Due_dtsQty numeric(9,2), Due_dtsBal numeric(9,2), ord_qty numeric(9,2), balance numeric(9,2),  
 Price numeric(14,5), RecordType char(1),SaleTypeid char(10), SalesRepF varchar(100), SalesRepL varchar(100), CID char(10), Quantity numeric(10,2), Flat bit, OrdAmt numeric(20,2), BackAmt numeric(20,2), Is_rma bit, Test numeric(20,2), plpricelnk char(10),
   
 DUEDT_UNIQ char(10), ShippedQty numeric(9,2), OrdQty numeric(9,2), MarginBckAmt numeric(9,2), Territory char (15),UsedDate date,FutureStartDt date,MaxDt date,MinDt date,M1h char(15)  
 ,M2h char(15),M3h char(15),M4h char(15),M5h char(15),M6h char(15),  
 -- 08/16/17 VL added functional currency code  
 PriceFC numeric(14,5), OrdAmtFC numeric(20,2), BackAmtFC numeric(20,2),  
 PricePR numeric(14,5), OrdAmtPR numeric(20,2), BackAmtPR numeric(20,2),MarginBckAmtPR numeric(9,2), FSymbol char(3), TSymbol char(3), PSymbol char(3))  
  
-- 07/16/18 VL changed custname from char(35) to char(50)  
DECLARE @ZSoBackLog TABLE (nrecno int identity, Custname char(50), Sono char(10), OrderDate smalldatetime, Pono char(20), Uniqueln char(10),   
 Line_no char(7), Part_no char(45), Revision char(8), Part_class char(8), Part_type char(8), Descriptio char(45), uniq_key char(10), Ship_dts Smalldatetime,   
 Due_dts SmallDateTime, COMMIT_DTS SmallDateTime, Due_dtsQty numeric(9,2), Due_dtsBal numeric(9,2), ord_qty numeric(9,2), balance numeric(9,2),  
 Price numeric(14,5), RecordType char(1),SaleTypeid char(10), SalesRepF varchar(100), SalesRepL varchar(100), CID char(10), Quantity numeric(10,2), Flat bit, OrdAmt numeric(20,2), BackAmt numeric(20,2), Is_rma bit, Test numeric(20,2), plpricelnk char(10),
   
 DUEDT_UNIQ char(10), ShippedQty numeric(9,2), OrdQty numeric(9,2), MarginBckAmt numeric(9,2),Territory char (15),UsedDate date,FutureStartDt date,MaxDt date,MinDt date,M1h char(15)  
 ,M2h char(15),M3h char(15),M4h char(15),M5h char(15),M6h char(15),  
 -- 08/16/17 VL added functional currency code  
 PriceFC numeric(14,5), OrdAmtFC numeric(20,2), BackAmtFC numeric(20,2),  
 PricePR numeric(14,5), OrdAmtPR numeric(20,2), BackAmtPR numeric(20,2),MarginBckAmtPR numeric(9,2), FSymbol char(3), TSymbol char(3), PSymbol char(3))  
   
DECLARE @lnCount int, @lnTotalNo int, @Due_dtsBal numeric(9,2), @Balance numeric(9,2), @lnTotalBackQty numeric(9,2), @Quantity numeric(10,2),  
  @Flat bit, @ShippedQty numeric(9,2), @lcOldUniqueln char(10), @lcCurrentUniqueln char(10), @Price numeric(14,5), @lcOldDuedt_Uniq char(10),   
  @lcCurrentDuedt_Uniq char(10), @lnOldDuedtBalance numeric(9,2), @lnSoAddQty numeric(9,2), @lnOrdQty numeric(9,2), @lnOldDuedtOrdQty numeric(9,2),  
  -- 08/16/17 VL added functional currency code  
  @PriceFC numeric(14,5),@PricePR numeric(14,5);  

-- 05/07/20 VL changed to update sales rep name separately to speed up
DECLARE @ZSrep TABLE (Uniqueln char(10), Cid char(10), Firstname varchar(100), Lastname varchar(100))

--- 08/26/13 YS   changed first name/last name to varchar(100), increased length of the ccontact fields.  
INSERT @ZSoBackLogPrep  
SELECT     TOP (100) PERCENT dbo.CUSTOMER.CUSTNAME, dbo.SOMAIN.SONO, dbo.SOMAIN.ORDERDATE, dbo.SOMAIN.PONO, dbo.SODETAIL.UNIQUELN,   
                      dbo.SODETAIL.LINE_NO, CASE WHEN dbo.inventor.part_no IS NULL THEN dbo.sodetail.Sodet_Desc ELSE CAST(dbo.INVENTOR.part_no AS CHAR(45))   
                      END AS PART_NO, CASE WHEN dbo.INVENTOR.REVISION IS NULL THEN CAST(' ' AS CHAR(8)) ELSE dbo.INVENTOR.REVISION END AS REVISION,   
                      dbo.INVENTOR.PART_CLASS, dbo.INVENTOR.PART_TYPE, CASE WHEN dbo.inventor.part_no IS NULL THEN CAST('' AS char(45))   
                      ELSE dbo.soprices.descriptio END AS DESCRIPTIO, dbo.inventor.UNIQ_KEY,  
                      dbo.Due_dts.SHIP_DTS,  
                      dbo.Due_dts.DUE_DTS,  
                      dbo.DUE_DTS.COMMIT_DTS,  
                      dbo.DUE_DTS.QTY+dbo.DUE_DTS.ACT_SHP_QT as Due_dtsQty,  
                      dbo.DUE_DTS.QTY as Due_dtsBal,  
                      dbo.SODETAIL.ORD_QTY, dbo.SODETAIL.BALANCE, dbo.SOPRICES.PRICE, dbo.SOPRICES.RECORDTYPE,dbo.soprices.saletypeid,  
					  -- 05/05/20 VL: Only get top 1 sales rep so if the uniqueln has multiple sales rep, the report doesn't get duplicate record
                      --case when dbo.CCONTACT.CID = dbo.SOPRSREP.CID and dbo.SODETAIL.UNIQUELN = dbo.SOPRSREP.UNIQUELN then CAST(dbo.CCONTACT.FIRSTNAME AS varCHAR (100)) else cast( '' as varchar (100)) end AS SalesRepF,
                      --case when dbo.CCONTACT.CID = dbo.SOPRSREP.CID and dbo.SODETAIL.UNIQUELN = dbo.SOPRSREP.UNIQUELN then CAST(dbo.CCONTACT.LASTNAME AS varCHAR (100)) else cast( '' as varchar (100)) end AS SalesRepL, 
                      --dbo.CCONTACT.CID,
					  -- 05/07/20 VL changed to update sales rep name separately to speed up
					  --AST(ISNULL(K.FIRSTNAME, '') AS varchar(100)) AS SalesRepF,
					  --CAST(ISNULL(K.LASTNAME, '') AS varchar(100)) AS SalesRepL,
					  --K.CID,
					  SPACE(100) AS SalesRepF, SPACE(100) AS SalesRepL, SPACE(10) AS CID,
				       dbo.Soprices.Quantity, dbo.SOPRICES.FLAT,   
                      0 AS OrdAmt,  
                      0 AS BackAmt,  
         dbo.SOMAIN.IS_RMA,   
        case when recordtype = 'P'  
      then   
       case when QUANTITY > qty then qty * price end   
        else  
         case when  qty > quantity then (QUANTITY - ACT_SHP_QT) * PRICE else 0 end end as test,  
      plpricelnk, DUEDT_UNIQ, ShippedQty,   
                      CASE WHEN DUE_DTS.DUEDT_UNIQ IS NULL   
      THEN SODETAIL.Ord_qty   
      ELSE DUE_DTs.qty+DUE_DTS.ACT_SHP_QT   
      END  
        AS OrdQty,  
        (dbo.SOPRICES.PRICE - dbo.INVENTOR.STDCOST) * dbo.DUE_DTS.QTY as MarginBckAmt,   
        CUSTOMER.TERRITORY 
		-- 05/07/20 VL added to make the USedDate as date type
		--,case when @lcUseDt = 'Due Date' then due_dts  when @lcUseDt = 'Ship Date' then Ship_dts else Commit_dts end as UsedDate 
		,CAST(case when @lcUseDt = 'Due Date' then due_dts  when @lcUseDt = 'Ship Date' then Ship_dts else Commit_dts end AS DATE) as UsedDate 
        ,DATEADD(mm, DATEDIFF(mm, 0, GETDATE())+6, 0) FurtureStartDt  
        ,DATEADD(mm, DATEDIFF(mm, 0, GETDATE())+6, 0) + @lcNoDays-1 as MaxDt  
		-- 05/07/20 VL added to make the USedDate as date type
		--,getdate()-@lcNoDays as MinDt
		,CAST(getdate()-@lcNoDays AS DATE) as MinDt					   
		,DATEname(month,GETDATE()) as M1h,datename(month,dateadd(mm,datediff(mm,0,getdate())+1,0)) as M2h  
        ,datename(month,dateadd(mm,datediff(mm,0,getdate())+2,0)) as M3h,datename(month,dateadd(mm,datediff(mm,0,getdate())+3,0)) as M4h  
        ,datename(month,dateadd(mm,datediff(mm,0,getdate())+4,0)) as M5h,datename(month,dateadd(mm,datediff(mm,0,getdate())+5,0)) as M6h  
        -- 08/16/17 VL:  added functional currency code  
        ,dbo.SOPRICES.PRICEFC, 0 AS OrdAmtFC, 0 AS BackAmtFC  
        ,dbo.SOPRICES.PRICEPR, 0 AS OrdAmtPR, 0 AS BackAmtPR, (dbo.SOPRICES.PRICEPR - dbo.INVENTOR.STDCOSTPR) * dbo.DUE_DTS.QTY as MarginBckAmtPR  
        ,ISNULL(FF.Symbol,'') AS FSymbol, ISNULL(TF.Symbol,'') AS TSymbol, ISNULL(PF.Symbol,'') AS PSymbol  
                                        
            
FROM         dbo.INVENTOR RIGHT OUTER JOIN  
                      dbo.SODETAIL LEFT OUTER JOIN  
                      dbo.SOPRICES ON dbo.SODETAIL.SONO = dbo.SOPRICES.SONO AND dbo.SODETAIL.UNIQUELN = dbo.SOPRICES.UNIQUELN ON   
                      dbo.INVENTOR.UNIQ_KEY = dbo.SODETAIL.UNIQ_KEY RIGHT OUTER JOIN  
                      dbo.CUSTOMER INNER JOIN  
                      dbo.SOMAIN ON dbo.CUSTOMER.CUSTNO = dbo.SOMAIN.CUSTNO ON dbo.SODETAIL.SONO = dbo.SOMAIN.SONO left outer join  
                      dbo.DUE_DTS on dbo.sodetail.UNIQUELN = dbo.DUE_DTS.UNIQUELN
					  -- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
					  --left outer join
                      --dbo.SOPRSREP on dbo.SODETAIL.UNIQUELN = dbo.SOPRSREP.uniqueln left outer join
                      --dbo.CCONTACT on dbo.SOPRSREP.CID = dbo.CCONTACT.CID
					   -- 05/07/20 VL changed to update sales rep name separately to speed up
					 -- LEFT OUTER JOIN (SELECT TOP 1 WITH TIES P.*, t.FIRSTNAME, t.LASTNAME
					 -- FROM SOPRSREP p INNER JOIN CCONTACT t ON p.CID = t.cid
					 --ORDER BY ROW_NUMBER() OVER (PARTITION BY Uniqueln ORDER BY FIRSTNAME)) k
					 -- ON Sodetail.UNIQUELN = k.UNIQUELN					  					  
                       -- 08/16/17 VL:  added functional currency code  
      LEFT OUTER JOIN Fcused FF ON Inventor.FuncFcused_uniq = FF.Fcused_uniq  
      LEFT OUTER JOIN Fcused TF ON Inventor.FuncFcused_uniq = TF.Fcused_uniq  
      LEFT OUTER JOIN Fcused PF ON Inventor.PrFcused_uniq = PF.Fcused_uniq   
                        
where  dbo.SODETAIL.STATUS <> 'Cancel' and dbo.SODETAIL.STATUS <> 'Closed' and dbo.SOMAIN.ORD_TYPE <> 'Cancel' and dbo.SOMAIN.ORD_TYPE <>'Closed' and dbo.SOPRICES.RECORDTYPE = 'P'  
   and dbo.SODETAIL.BALANCE <> 0   
   and exists (select 1 from @Territory C1  where customer.Territory = c1.Territory)   
   and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer c on t.custno=c.custno where c.custno=somain.custno))  
  
order by CUSTNAME, SONO, Uniqueln, DUEDT_UNIQ, PLPRICELNK;  
 
-- 05/07/20 VL changed to update sales rep name separately to speed up
INSERT INTO @ZSrep SELECT TOP 1 WITH TIES Uniqueln, P.Cid, Firstname, Lastname
	  FROM SOPRSREP p INNER JOIN CCONTACT t ON p.CID = t.cid
	  WHERE EXISTS(SELECT 1 FROM @ZSoBackLogPrep Z WHERE Z.Uniqueln = p.UNIQUELN)
	  ORDER BY ROW_NUMBER() OVER (PARTITION BY Uniqueln ORDER BY FIRSTNAME)
						
UPDATE @ZSoBackLogPrep SET SalesRepF = CAST(ISNULL(K.FIRSTNAME, '') AS varchar(100)),
							SalesRepL = CAST(ISNULL(K.LASTNAME, '') AS varchar(100)),
							CID = K.CID
			FROM @ZSrep k
		WHERE [@ZSoBackLogPrep].UNIQUELN = k.UNIQUELN
-- 05/07/20 VL End}

-----------------------------------------  
-- 03/28/17 VL the code created on 11/22/10 created multiple records, but should only show one record for the 'NOT SCHEDULED' part  
--11/22/10 added code for not scheduled record (added extra record for not scheduled in due_dts)  
--WITH ZNoDueDtRecord AS   
-- (SELECT Ord_qty - SUM(Qty+Act_shp_qt) AS Due_dtsQty, Balance - SUM(Qty+Act_shp_qt) AS Due_dtsBal, Sodetail.Uniqueln, Ord_qty, Balance  
-- FROM SODETAIL, DUE_DTS  
-- WHERE SODETAIL.UNIQUELN = DUE_DTS.UNIQUELN  
-- AND dbo.SODETAIL.STATUS <> 'Cancel' and dbo.SODETAIL.STATUS <> 'Closed'  
-- Group by Sodetail.Uniqueln, Ord_qty, Balance  
-- having ORD_QTY<>SUM(Qty+Act_shp_qt))  
   
--INSERT @ZSoBackLogPrep  
--SELECT  DISTINCT TOP (100) PERCENT T.CUSTNAME, T.SONO, T.ORDERDATE, 'NOT SCHEDULED' AS PONO, T.UNIQUELN, T.LINE_NO, T.PART_NO,   
--      T.REVISION, T.PART_CLASS, T.PART_TYPE, T.DESCRIPTIO,t.uniq_key, NULL AS SHIP_DTS,NULL AS DUE_DTS,  
--                      NULL AS COMMIT_DTS,ZNoDueDtRecord.Due_dtsQty, ZNoDueDtRecord.Due_dtsBal,T.ORD_QTY,   
--                      T.BALANCE, T.PRICE, T.RecordType,t.SaleTypeid, t.SalesRepF, t.SalesRepL, t.CID, T.Quantity, T.FLAT, 0 AS OrdAmt,0 AS BackAmt, T.IS_RMA,   
--       0 AS test, T.plpricelnk, SPACE(10) AS DUEDT_UNIQ, ShippedQty,  
--                      T.OrdQty , t.MarginBckAmt, t.Territory,t.UsedDate,t.FutureStartDt,t.MaxDt,t.Mindt,t.M1h,t.M2h,t.M3h,t.M4h,t.M5h,t.M6h   
--        FROM @ZSoBackLogPrep T, ZNoDueDtRecord  
--  WHERE T.Uniqueln = ZNoDueDtRecord.Uniqueln  
--  order by CUSTNAME, SONO, Uniqueln, DUEDT_UNIQ, PLPRICELNK;  
-- {03/28/17 VL try to only create one record,and the Due_dtsQty and Due_dtsBal need to be changed too, in some case it shows negative qty  
--11/22/10 added code for not scheduled record (added extra record for not scheduled in due_dts)  
  
--03/28/17 VL:  beginning of code that replaces the above  
;WITH ZNoDueDtRecord AS   
 (  
 SELECT 0 AS Due_dtsQty,  
 CASE WHEN ABS(Sodetail.Shippedqty)>=ABS(ISNULL(SUM(Qty+Act_shp_qt),0)) THEN Balance ELSE Ord_qty - SUM(Qty+Act_shp_qt) END AS Due_dtsBal,   
 Sodetail.Uniqueln, Ord_qty, Balance  
 FROM SODETAIL, DUE_DTS  
 WHERE SODETAIL.UNIQUELN = DUE_DTS.UNIQUELN  
 AND dbo.SODETAIL.STATUS <> 'Cancel' and dbo.SODETAIL.STATUS <> 'Closed'  
 Group by Sodetail.Uniqueln, Ord_qty, Balance, Shippedqty  
 having ORD_QTY<>SUM(Qty+Act_shp_qt))  
  
, ZDistItem AS -- Only get one record per item, then join with ZNoDueDtRecord later  
(  
 SELECT DISTINCT T.CUSTNAME, T.SONO, T.ORDERDATE, 'NOT SCHEDULED' AS PONO, T.UNIQUELN, T.LINE_NO, T.PART_NO,   
      T.REVISION, T.PART_CLASS, T.PART_TYPE, T.DESCRIPTIO,t.uniq_key, NULL AS SHIP_DTS,NULL AS DUE_DTS,  
                      NULL AS COMMIT_DTS, T.ORD_QTY,   
                      T.BALANCE, T.PRICE, T.RecordType,t.SaleTypeid, t.SalesRepF, t.SalesRepL, t.CID, T.Quantity, T.FLAT, 0 AS OrdAmt,0 AS BackAmt, T.IS_RMA,   
       0 AS test, T.plpricelnk, SPACE(10) AS DUEDT_UNIQ, ShippedQty,  
                      0 AS OrdQty , 0 AS MarginBckAmt, t.Territory,NULL AS UsedDate,t.FutureStartDt,t.MaxDt,t.Mindt,t.M1h,t.M2h,t.M3h,t.M4h,t.M5h,t.M6h,   
         -- 08/16/17 VL:  added functional currency code  
       T.PRICEFC, 0 AS OrdAmtFC, 0 AS BackAmtFC,   
       T.PRICEPR, 0 AS OrdAmtPR, 0 AS BackAmtPR, 0 AS MarginBckAmtPR, FSymbol, TSymbol, PSymbol  
        FROM @ZSoBackLogPrep T  
  WHERE T.Uniqueln IN (SELECT Uniqueln FROM  ZNoDueDtRecord))  
  
INSERT @ZSoBackLogPrep  
SELECT T.CUSTNAME, T.SONO, T.ORDERDATE, T.PONO, T.UNIQUELN, T.LINE_NO, T.PART_NO,   
      T.REVISION, T.PART_CLASS, T.PART_TYPE, T.DESCRIPTIO,t.uniq_key, T.SHIP_DTS,T.DUE_DTS,  
                     T.COMMIT_DTS,ZNoDueDtRecord.Due_dtsQty, ZNoDueDtRecord.Due_dtsBal,T.ORD_QTY,   
                      T.BALANCE, T.PRICE, T.RecordType,t.SaleTypeid, t.SalesRepF, t.SalesRepL, t.CID, T.Quantity, T.FLAT, T.OrdAmt,0 AS BackAmt, T.IS_RMA,   
       T.test, T.plpricelnk, T.DUEDT_UNIQ, ShippedQty,  
                      T.OrdQty , t.MarginBckAmt, t.Territory,t.UsedDate,t.FutureStartDt,t.MaxDt,t.Mindt,t.M1h,t.M2h,t.M3h,t.M4h,t.M5h,t.M6h,  
       -- 08/16/17 VL:  added functional currency code  
       T.PRICEFC, T.OrdAmtFC, 0 AS BackAmtFC,  
       T.PRICEPR, T.OrdAmtPR ,0 AS BackAmtPR, MarginBckAmtPR, FSymbol, TSymbol, PSymbol  
        FROM ZDistItem T, ZNoDueDtRecord  
  WHERE T.Uniqueln = ZNoDueDtRecord.Uniqueln  
  order by CUSTNAME, SONO, Uniqueln, DUEDT_UNIQ, PLPRICELNK;  
-- 03/28/17 VL End}  
  
INSERT INTO @ZSoBackLog  
SELECT * FROM @ZSoBackLogPrep order by CUSTNAME, SONO, Uniqueln, DUEDT_UNIQ, PLPRICELNK   
  
---- 11/22/10 End  
  
  
SET @lnTotalNo = @@ROWCOUNT;  
   
IF (@lnTotalNo>0)  
SELECT @lcOldUniqueln = Uniqueln, @lcOldDuedt_Uniq = Duedt_Uniq FROM @ZSoBackLog WHERE nRecno = 1 -- Get the uniqueln from first record  
BEGIN   
 SET @lnCount=0;  
 SET @lnSoAddQty = 0; -- Need to reset when uniqueln changed  
 SET @lnTotalBackQty = 0; -- Need to reset when uniqueln changed  
 SET @lnOldDuedtOrdQty = 0;  
 SET @lnOldDuedtBalance = 0;  
 WHILE @lnTotalNo>@lnCount  
 BEGIN   
  SET @lnCount=@lnCount+1;  
  -- @lnTotalBackQty numeric(9,2)  
  -- 08/16/17 VL:  added functional currency code  
  SELECT @Due_dtsBal = Due_dtsBal, @Balance = Balance, @Quantity = Quantity, @lcCurrentUniqueln = Uniqueln, @Price = Price,   
   @Flat = Flat, @ShippedQty = Shippedqty, @lcCurrentDuedt_Uniq = Duedt_Uniq, @lnOrdQty = OrdQty, @PriceFC = PriceFC, @PricePR = PricePR    
   FROM @ZSoBackLog WHERE nrecno = @lnCount  
     
  BEGIN  
  IF (@@ROWCOUNT<>0)  
    
   IF @lcCurrentUniqueln <> @lcOldUniqueln  
   BEGIN  
    SET @lnTotalBackQty = 0; -- Reset when a new Uniqueln record starts  
    SET @lnSoAddQty = 0;  
    -- 11/17/10 VL added next two lines  
    SET @lnOldDuedtBalance = 0;  
    SET @lnOldDuedtOrdQty = 0;      
   END  
     
   IF @lcCurrentDuedt_Uniq <> @lcOldDuedt_Uniq  
   BEGIN  
    SET @lnTotalBackQty = @lnTotalBackQty + @lnOldDuedtBalance;  
    SET @lnSoAddQty = @lnSoAddQty + @lnOldDuedtOrdQty;  
   END  
      
   ----------------------------------------------------------------------------------------  
   ----- OrdAmt  
   IF ABS(@Quantity - @lnSoAddQty) >= ABS(@Due_dtsBal) -- Never been added before  
    BEGIN  
    IF @Flat = 1  
     BEGIN     
     -- OrdAmt  
     IF @lnSoAddQty = 0  
      -- 08/16/17 VL:  added functional currency code  
      UPDATE @ZSoBackLog SET OrdAmt = @Price, OrdAmtFC = @PriceFC, OrdAmtPR = @PricePR WHERE nrecno = @lnCount  
     END  
    ELSE  
     BEGIN  
     IF @Quantity > 0  
      IF @Quantity - @lnSoAddQty >= @Due_dtsBal  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET OrdAmt = @lnOrdQty * @Price, OrdAmtFC = @lnOrdQty * @PriceFC, OrdAmtPR = @lnOrdQty * @PricePR WHERE nrecno = @lnCount  
      ELSE  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET OrdAmt = 0, OrdAmtFC = 0, OrdAmtPR = 0 WHERE nrecno = @lnCount  
     ELSE  
      IF ABS(@Quantity - @lnSoAddQty) >= ABS(@Due_dtsBal)  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET OrdAmt = @lnOrdQty * @Price, OrdAmtFC = @lnOrdQty * @PriceFC, OrdAmtPR = @lnOrdQty * @PricePR WHERE nrecno = @lnCount  
      ELSE  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET OrdAmt = 0, OrdAmtFC = 0, OrdAmtPR = 0 WHERE nrecno = @lnCount        
     END  
    END  
  
   BEGIN  
   IF ABS(@Quantity - @lnSoAddQty) < ABS(@lnOrdQty) AND ABS(@Quantity - @lnSoAddQty) > 0  
    BEGIN  
    IF @Quantity > 0  
     BEGIN  
     IF @Quantity - @lnSoAddQty < @lnOrdQty AND @Quantity - @lnSoAddQty > 0  
        
      IF @Flat = 1  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET OrdAmt = @Price, OrdAmtFC = @PriceFC, OrdAmtPR = @PricePR WHERE nrecno = @lnCount  
      ELSE   
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET OrdAmt = (@Quantity - @lnSoAddQty) * @Price, OrdAmtFC = (@Quantity - @lnSoAddQty) * @PriceFC, OrdAmtPR = (@Quantity - @lnSoAddQty) * @PricePR WHERE nrecno = @lnCount  
     ELSE  
      -- 08/16/17 VL:  added functional currency code  
      UPDATE @ZSoBackLog SET OrdAmt = 0, OrdAmtFC = 0, OrdAmtPR = 0 WHERE nrecno = @lnCount  
     END       
    ELSE  
     BEGIN  
     IF ABS(@Quantity - @lnSoAddQty) < ABS(@lnOrdQty) AND ABS(@Quantity - @lnSoAddQty) > 0   
      IF @Flat = 1  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET OrdAmt = @Price, OrdAmtFC = @PriceFC, OrdAmtPR = @PricePR WHERE nrecno = @lnCount  
      ELSE   
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET OrdAmt = (@Quantity - @lnSoAddQty) * @Price, OrdAmtFC = (@Quantity - @lnSoAddQty) * @PriceFC, OrdAmtPR = (@Quantity - @lnSoAddQty) * @PricePR WHERE nrecno = @lnCount  
     ELSE  
      -- 08/16/17 VL:  added functional currency code  
      UPDATE @ZSoBackLog SET OrdAmt = 0, OrdAmtFC = 0, OrdAmtPR = 0 WHERE nrecno = @lnCount  
     END  
    END  
   END  
           
   ----------------------------------------------------------------------------------------  
   ----- BackAmt  
   IF ABS(@Quantity - @lnTotalBackQty) >= ABS(@Due_dtsBal) -- Never been added before  
    BEGIN  
    IF @Flat = 1  
     BEGIN  
     -- BackAmt  
     IF @lnTotalBackQty = 0 AND @ShippedQty = 0  
      -- 08/16/17 VL:  added functional currency code  
      UPDATE @ZSoBackLog SET BackAmt = @Price, BackAmtFC = @PriceFC, BackAmtPR = @PricePR WHERE nrecno = @lnCount  
     END  
    ELSE  
     BEGIN  
     IF @Quantity > 0  
      IF @Quantity - @ShippedQty - @lnTotalBackQty >= @Due_dtsBal  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET BackAmt = @Due_dtsBal * @Price, BackAmtFC = @Due_dtsBal * @PriceFc, BackAmtPR = @Due_dtsBal * @PricePR WHERE nrecno = @lnCount  
      ELSE   
       IF @Quantity - @ShippedQty - @lnTotalBackQty > 0   
        -- 08/16/17 VL:  added functional currency code   
        UPDATE @ZSoBackLog SET BackAmt = (@Quantity - @ShippedQty - @lnTotalBackQty) * @Price,   
              BackAmtFC = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PriceFC,   
              BackAmtPR = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PricePR WHERE nrecno = @lnCount  
       ELSE  
        -- 08/16/17 VL:  added functional currency code  
        UPDATE @ZSoBackLog SET BackAmt = 0, BackAmtFC = 0, BackAmtPR = 0 WHERE nrecno = @lnCount  
        
     ELSE  
      BEGIN  
      IF ABS(@Quantity - @ShippedQty - @lnTotalBackQty) >= ABS(@Due_dtsBal)  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET BackAmt = @Due_dtsBal * @Price, BackAmtFC = @Due_dtsBal * @PriceFC, BackAmtPR = @Due_dtsBal * @PricePR WHERE nrecno = @lnCount   
      ELSE  
       -- 08/16/17 VL:  added functional currency code  
       UPDATE @ZSoBackLog SET BackAmt = 0, BackAmtFC = 0, BackAmtPR = 0 WHERE nrecno = @lnCount    
      END  
     END   
    END  
  
   
   IF ABS(@Quantity - @lnTotalBackQty) < ABS(@Due_dtsBal) AND ABS(@Quantity - @lnTotalBackQty) > 0   
    BEGIN  
    IF @Flat = 1 AND @lnTotalBackQty = 0 AND @ShippedQty = 0  
     BEGIN  
      -- 08/16/17 VL:  added functional currency code  
      UPDATE @ZSoBackLog SET BackAmt = @Price, BackAmtFC = @PriceFC, BackAmtPR = @PricePR WHERE nrecno = @lnCount  
     END  
    ELSE  
     BEGIN  
      IF @Quantity > 0  
       BEGIN  
       IF @Quantity - @ShippedQty - @lnTotalBackQty > 0  
        -- 08/16/17 VL:  added functional currency code  
        UPDATE @ZSoBackLog SET BackAmt = (@Quantity - @ShippedQty - @lnTotalBackQty)*@Price,  
              BackAmtFC = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PriceFC,   
              BackAmtPR = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PricePR WHERE nrecno = @lnCount   
       ELSE  
        -- 08/16/17 VL:  added functional currency code  
        UPDATE @ZSoBackLog SET BackAmt = 0, BackAmtFC = 0, BackAmtPR = 0 WHERE nrecno = @lnCount  
       END  
  
      ELSE  
       BEGIN  
       IF ABS(@Quantity - @ShippedQty - @lnTotalBackQty) >= 0  
        -- 08/16/17 VL:  added functional currency code  
        UPDATE @ZSoBackLog SET BackAmt = (@Quantity - @ShippedQty - @lnTotalBackQty)*@Price,  
              BackAmtFC = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PriceFC,   
              BackAmtPR = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PricePR WHERE nrecno = @lnCount   
       ELSE  
        -- 08/16/17 VL:  added functional currency code  
        UPDATE @ZSoBackLog SET BackAmt = 0, BackAmtFC = 0, BackAmtPR = 0 WHERE nrecno = @lnCount  
       END  
     END  
    END  
   ----------------------------------------------------------------------------------------   
  SET @lnOldDuedtBalance = @Due_dtsBal;  
  SET @lnOldDuedtOrdQty = @lnOrdQty;  
  SET @lcOldUniqueln = @lcCurrentUniqueln;  
  SET @lcOldDuedt_Uniq = @lcCurrentDuedt_Uniq;  
        
  END  
 END  
END  
  
-- 08/16/17 VL separate FC and non FC  
/*----------------------  
None FC installation  
*/----------------------  
IF dbo.fn_IsFCInstalled() = 0   
 BEGIN  
  
 if @lcSort = 'by Territory'  
  begin  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select t1.Territory,t1.custname,t1.part_no, t1.revision, t1.sono, t1.orderdate, t1.pono, t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType, t1.saletypeid,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY Territory,Custname,Part_no,Revision  
  end  
  
  
 else if @lcSort = 'by Sales Rep'  
  BEGIN 
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
     t1.custname,t1.pono,t1.part_no, t1.revision, t1.sono, t1.orderdate,  t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType, t1.saletypeid,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     t1.Territory,  
      
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY SalesRepL,custname,pono,part_no,Revision  
  END  
  
 else if @lcSort = 'by Sales Type'  
  BEGIN  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select t1.saletypeid,t1.Territory,  
     t1.custname,t1.part_no, t1.revision, t1.sono, t1.pono,t1.orderdate,  t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType,   
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
      
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY SaleTypeid,Territory,Custname,Part_no,Revision  
  END  
  
 else if @lcSort = 'by Customer'  
  BEGIN  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select t1.custname,t1.part_no, t1.revision, t1.sono, t1.pono,t1.orderdate,  t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType, t1.saletypeid,t1.Territory,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
      
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY Custname,Part_no,Revision  
  END  
 else if @lcSort = 'by Customer/PO'  
  BEGIN  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select t1.custname,t1.pono,t1.part_no, t1.revision, t1.sono, t1.orderdate,  t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType, t1.saletypeid,t1.Territory,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY Custname,Pono,Part_no,Revision  
  END  
 END  
ELSE  
/*-----------------  
 FC installation  
*/-----------------  
 BEGIN  
  
 if @lcSort = 'by Territory'  
  begin  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select t1.Territory,t1.custname,t1.part_no, t1.revision, t1.sono, t1.orderdate, t1.pono, t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType, t1.saletypeid,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future  
     -- 08/16/17 VL added functional currency code  
     ,t1.FSymbol  
     ,t1.priceFC,OrdAmtFC,BackAmtFC, 0 AS MarginBckAmtFC  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end else 00 end as PastDueFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M1dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M2dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M3dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M4dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M5dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M6dFC  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0  end else 0.00 end as FutureFC  
     ,t1.TSymbol  
     ,t1.pricePR,OrdAmtPR,BackAmtPR,t1.MarginBckAmtPR  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end else 00 end as PastDuePR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M1dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M2dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M3dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M4dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M5dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M6dPR  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR  end else 0.00 end as FuturePR  
     ,t1.PSymbol  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY Territory,Custname,Part_no,Revision  
  end  
  
  
 else if @lcSort = 'by Sales Rep'  
  BEGIN  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
     t1.custname,t1.pono,t1.part_no, t1.revision, t1.sono, t1.orderdate,  t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType, t1.saletypeid,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     t1.Territory,  
      
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
     -- 08/16/17 VL added functional currency code  
     ,t1.FSymbol  
     ,t1.priceFC,OrdAmtFC,BackAmtFC, 0 AS MarginBckAmtFC  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end else 00 end as PastDueFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M1dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M2dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M3dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M4dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M5dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M6dFC  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0  end else 0.00 end as FutureFC  
     ,t1.TSymbol  
     ,t1.pricePR,OrdAmtPR,BackAmtPR,t1.MarginBckAmtPR  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end else 00 end as PastDuePR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M1dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M2dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M3dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M4dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M5dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M6dPR  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR  end else 0.00 end as FuturePR  
     ,t1.PSymbol  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY SalesRepL,custname,pono,part_no,Revision  
  END  
  
 else if @lcSort = 'by Sales Type'  
  BEGIN  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select t1.saletypeid,t1.Territory,  
     t1.custname,t1.part_no, t1.revision, t1.sono, t1.pono,t1.orderdate,  t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType,   
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
      
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
     -- 08/16/17 VL added functional currency code  
     ,t1.FSymbol  
     ,t1.priceFC,OrdAmtFC,BackAmtFC, 0 AS MarginBckAmtFC  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end else 00 end as PastDueFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M1dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M2dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M3dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M4dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M5dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M6dFC  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0  end else 0.00 end as FutureFC  
     ,t1.TSymbol  
     ,t1.pricePR,OrdAmtPR,BackAmtPR,t1.MarginBckAmtPR  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end else 00 end as PastDuePR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M1dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M2dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M3dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M4dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M5dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M6dPR  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR  end else 0.00 end as FuturePR  
     ,t1.PSymbol  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY SaleTypeid,Territory,Custname,Part_no,Revision  
  END  
  
 else if @lcSort = 'by Customer'  
  BEGIN  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select t1.custname,t1.part_no, t1.revision, t1.sono, t1.pono,t1.orderdate,  t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType, t1.saletypeid,t1.Territory,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
      
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
     -- 08/16/17 VL added functional currency code  
     ,t1.FSymbol  
     ,t1.priceFC,OrdAmtFC,BackAmtFC, 0 AS MarginBckAmtFC  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end else 00 end as PastDueFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M1dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M2dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M3dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M4dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M5dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M6dFC  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0  end else 0.00 end as FutureFC  
     ,t1.TSymbol  
     ,t1.pricePR,OrdAmtPR,BackAmtPR,t1.MarginBckAmtPR  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end else 00 end as PastDuePR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M1dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M2dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M3dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M4dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M5dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M6dPR  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR  end else 0.00 end as FuturePR  
     ,t1.PSymbol  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY Custname,Part_no,Revision  
  END  
 else if @lcSort = 'by Customer/PO'  
  BEGIN  
  -- 05/07/20 VL added CAST( AS DATE) to make the getdate() as date type
   select t1.custname,t1.pono,t1.part_no, t1.revision, t1.sono, t1.orderdate,  t1.uniqueln, t1.line_no,  t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.price, t1.RecordType, t1.saletypeid,t1.Territory,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,  
     case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,  
     T1.CID,t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.UsedDate,t1.FutureStartDt,t1.MaxDt,t1.MinDt  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end else 00 end as PastDue  
     ,t1.M1h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M1d  
     ,t1.M2h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M2d  
     ,t1.M3h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M3d  
     ,t1.M4h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M4d  
     ,t1.M5h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M5d  
     ,t1.M6h,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt end  else 0.00 end as M6d  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmt else t1.MarginBckAmt  end else 0.00 end as Future   
     -- 08/16/17 VL added functional currency code  
     ,t1.FSymbol  
     ,t1.priceFC,OrdAmtFC,BackAmtFC, 0 AS MarginBckAmtFC  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end else 00 end as PastDueFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M1dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M2dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M3dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M4dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M5dFC  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0 end  else 0.00 end as M6dFC  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0  end else 0.00 end as FutureFC  
     ,t1.TSymbol  
     ,t1.pricePR,OrdAmtPR,BackAmtPR,t1.MarginBckAmtPR  
     ,case when t1.useddate >= t1.MinDt and t1.useddate < CAST(getdate() AS DATE)  then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end else 00 end as PastDuePR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M1h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M1dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M2h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M2dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M3h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M3dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M4h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M4dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M5h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M5dPR  
     ,case when t1.useddate >= CAST(getdate() AS DATE)  and t1.UsedDate < t1.futureStartDt and datename(month,t1.useddate) = t1.M6h then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR end  else 0.00 end as M6dPR  
     ,case when t1.useddate >= t1.futurestartdt and t1.UsedDate <= MaxDt then case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else t1.MarginBckAmtPR  end else 0.00 end as FuturePR  
     ,t1.PSymbol  
     from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog  
     order by CUSTNAME, SONO                        
     )t1  
     ORDER BY Custname,Pono,Part_no,Revision  
  END  
 END  
 -- 08/16/17 VL End for FC installed  
end