-- =============================================
-- Author:		<Vicky and Debbie> 
-- Create date: <11/17/2010>
-- Last Modified: <06/28/2011 by Debbie>
-- Description:	<compiles detailed sales order Backlog Revenue/Margin Summary information>
-- Reports:     <used on bgrevnmg.rpt, bgrvbycu.rpt, bgrvbycp.rpt>
-- Modified:	08/26/13 YS   changed first name/last name to varchar(100), increased length of the ccontact fields.
-- 03/26/14 DRP:  Territory char(12) needed to be changed to Territory char(15)
-- 04/02/2015 DRP:  Found that I needed to remove the CASE WHEN ROW_NUMBER() OVER(Partition . . . for Due_dtsQty and Due_dtsBal, because there are scenarios where the users will have the same Schedule dates multiple times.
-- 05/26/2015 DRP:  the @userId was commented out . . I just had to make sure that is was not commented out. 
-- 03/28/17 VL:  the code created on 11/22/10 created multiple records, but should only show one record for the 'NOT SCHEDULED' part
-- 04/11/17 DRP:  needed to add many Parameters and  fields to the procedure results in order to convert Crystal version to Stimulsoft report form. 
-- 08/15/17 VL:  added functional currency code
-- 08/16/17 VL checked with DRP that we only need one PastDue field, so I comment out one of these fields
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 03/13/20 VL Changed how MinDt, MaxDt, FutureStartDate calculated, not just used the current date, has to get the first date of thag month (e.g. today is 3/13/20, 6 month later don't use 9/13/20, use the 9/1/20),
-- match the date calculation in rptSoBackLogRevM and also match VFP version
-- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
-- =============================================
CREATE PROCEDURE [dbo].[rptSoBackLogRevDtl] 

--DRP: <06/28/2011>  Added the Customer Parameter to the Stored Procedure itself instead of using it through the Crystal Report.  Due to the fact that CR had issue with Large data sets and was not listing out all available customers.
--DRP: <06/28/2011>  Also added Territory throughout the procedure.

--declare

	@lcCustNo as varchar (max) = 'All'		--04/11/17 DRP:  changed param from @lcCust to @lcCustno
	,@lcUseDt as char(15) = 'Ship Date'		--Ship Date, Due Date, Commit Date	--04/11/17 DRP:  added this new @lcUseDt
	,@lcNoDays as int = 720					--04/11/17 DRP:  added this new param 
	,@lcBkLogType as char(15) = 'Revenue'		--Revenue or Margin	--04/11/17 DRP:  Added this new param
 , @userId uniqueidentifier= null

AS
BEGIN



/*CUSTOMER LIST*/	--04/11/17 DRP:  added	
	DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'Active' ;
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


---  08/26/13 YS   changed first name/last name to varchar(100), increased length of the ccontact fields.
--- 04/11/17 DRP:  added ,UsedDt,CurrDate,MinDt,MaxDt,FutureStartDate
-- 08/15/17 VL:  added functional currency code
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
DECLARE @ZSoBackLogPrep TABLE (Custname char(50), Sono char(10), OrderDate smalldatetime, Pono char(20), Uniqueln char(10), 
	Line_no char(7), Part_no char(45), Revision char(8), Part_class char(8), Part_type char(8), Descriptio char(45),uniq_key char(10), Ship_dts Smalldatetime, 
	Due_dts SmallDateTime, COMMIT_DTS SmallDateTime, Due_dtsQty numeric(9,2), Due_dtsBal numeric(9,2), ord_qty numeric(9,2), balance numeric(9,2),
	Price numeric(14,5), RecordType char(1),SaleTypeid char(10), --SalesRepF varchar(100), SalesRepL varchar(100), CID char(10), 
	Quantity numeric(10,2), Flat bit, OrdAmt numeric(20,2), BackAmt numeric(20,2), Is_rma bit, Test numeric(20,2), plpricelnk char(10), 
	DUEDT_UNIQ char(10), ShippedQty numeric(9,2), OrdQty numeric(9,2), MarginBckAmt numeric(9,2), Territory char (15)
	,UsedDt smalldatetime,CurrDate smalldatetime,MinDt smalldatetime,MaxDt smalldatetime,FutureStartDate smalldatetime,
	-- 08/15/17 VL:  added functional currency code
	PriceFC numeric(14,5), OrdAmtFC numeric(20,2), BackAmtFC numeric(20,2), 
	PricePR numeric(14,5), OrdAmtPR numeric(20,2), BackAmtPR numeric(20,2), MarginBckAmtPR numeric(9,2), FSymbol char(3), TSymbol char(3), PSymbol char(3))

-- 08/15/17 VL:  added functional currency code
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
DECLARE @ZSoBackLog TABLE (nrecno int identity, Custname char(50), Sono char(10), OrderDate smalldatetime, Pono char(20), Uniqueln char(10), 
	Line_no char(7), Part_no char(45), Revision char(8), Part_class char(8), Part_type char(8), Descriptio char(45), uniq_key char(10), Ship_dts Smalldatetime, 
	Due_dts SmallDateTime, COMMIT_DTS SmallDateTime, Due_dtsQty numeric(9,2), Due_dtsBal numeric(9,2), ord_qty numeric(9,2), balance numeric(9,2),
	Price numeric(14,5), RecordType char(1),SaleTypeid char(10), --SalesRepF varchar(100), SalesRepL varchar(100), CID char(10), 
	Quantity numeric(10,2), Flat bit, OrdAmt numeric(20,2), BackAmt numeric(20,2), Is_rma bit, Test numeric(20,2), plpricelnk char(10), 
	DUEDT_UNIQ char(10), ShippedQty numeric(9,2), OrdQty numeric(9,2), MarginBckAmt numeric(9,2),Territory char (15)
	,UseDt smalldatetime,CurrDate smalldatetime,MinDt smalldatetime,MaxDt smalldatetime,FutureStartDate smalldatetime,
	-- 08/15/17 VL:  added functional currency code
	PriceFC numeric(14,5), OrdAmtFC numeric(20,2), BackAmtFC numeric(20,2), 
	PricePR numeric(14,5), OrdAmtPR numeric(20,2), BackAmtPR numeric(20,2), MarginBckAmtPR numeric(9,2), FSymbol char(3), TSymbol char(3), PSymbol char(3))
	
DECLARE @lnCount int, @lnTotalNo int, @Due_dtsBal numeric(9,2), @Balance numeric(9,2), @lnTotalBackQty numeric(9,2), @Quantity numeric(10,2),
		@Flat bit, @ShippedQty numeric(9,2), @lcOldUniqueln char(10), @lcCurrentUniqueln char(10), @Price numeric(14,5), @lcOldDuedt_Uniq char(10), 
		@lcCurrentDuedt_Uniq char(10), @lnOldDuedtBalance numeric(9,2), @lnSoAddQty numeric(9,2), @lnOrdQty numeric(9,2), @lnOldDuedtOrdQty numeric(9,2),
		-- 08/15/17 VL:  added functional currency code
		@PriceFC numeric(14,5),@PricePR numeric(14,5);

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
					  -- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
                      --cast(case when dbo.CCONTACT.CID = dbo.SOPRSREP.CID and dbo.SODETAIL.UNIQUELN = dbo.SOPRSREP.UNIQUELN then dbo.CCONTACT.FIRSTNAME  else ''  end as varchar(100)) AS SalesRepF,
                      --cast(case when dbo.CCONTACT.CID = dbo.SOPRSREP.CID and dbo.SODETAIL.UNIQUELN = dbo.SOPRSREP.UNIQUELN then dbo.CCONTACT.LASTNAME else  ''   end as varchar(100)) AS SalesRepL, 
                      --dbo.CCONTACT.CID,
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
					   --- 04/11/17 DRP:  added ,UsedDt,CurrDate,MinDt,MaxDt,FutureStartDate
					   ,case when @lcUseDt = 'Ship Date' then  dbo.Due_dts.SHIP_DTS else case when @lcUseDt = 'Due Date' then  dbo.Due_dts.DUE_DTS else dbo.DUE_DTS.COMMIT_DTS end end as UseDt 
					   ,cast(getdate() as date) as CurrDate,null as MinDt,null as MaxDt,null as FutureStartDate
					   -- 08/15/17 VL:  added functional currency code
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
                      -- 08/15/17 VL:  added functional currency code
						LEFT OUTER JOIN Fcused FF ON Inventor.FuncFcused_uniq = FF.Fcused_uniq
						LEFT OUTER JOIN Fcused TF ON Inventor.FuncFcused_uniq = TF.Fcused_uniq
						LEFT OUTER JOIN Fcused PF ON Inventor.PrFcused_uniq = PF.Fcused_uniq	

                      
where		dbo.SODETAIL.STATUS <> 'Cancel' and dbo.SODETAIL.STATUS <> 'Closed' and dbo.SOMAIN.ORD_TYPE <> 'Cancel' and dbo.SOMAIN.ORD_TYPE <>'Closed' and dbo.SOPRICES.RECORDTYPE = 'P'
			and dbo.SODETAIL.BALANCE <> 0 
--DRP: <06/28/2011> added this filter to go with the Customer Parameter above
			--and CUSTOMER.Custname like case when @lcCust ='*' then '%' else @lcCust+'%' end	--04/11/17 DRP:  replaced by the below.
			and (@lcCustNo='All' OR exists (select 1 from @Customer t inner join customer w on t.custno=w.custno where w.custno=somain.custno))

order by CUSTNAME, SONO, Uniqueln, DUEDT_UNIQ, PLPRICELNK;

---04/11/17 DRP:  updated the new fields with info
-- 03/13/20 VL Changed how MinDt, MaxDt, FutureStartDate calculated, not just used the current date, has to get the first date of thag month (e.g. today is 3/13/20, 6 month later don't use 9/13/20, use the 9/1/20),
-- match the date calculation in rptSoBackLogRevM and also match VFP version
--update @ZSoBackLogPrep set MinDt = CurrDate-@lcNoDays,MaxDt = CurrDate+@lcNoDays,FutureStartDate = cast(DateAdd(month,6,getdate()) as date)  from @ZSoBackLogPrep 
update @ZSoBackLogPrep set MinDt = GETDATE() - @lcNoDays, MaxDt = DATEADD(mm, DATEDIFF(mm, 0, GETDATE())+6, 0) + @lcNoDays-1, FutureStartDate = DATEADD(mm, DATEDIFF(mm, 0, GETDATE())+6, 0)

-----------------------------------------
-- 03/28/17 VL the code created on 11/22/10 created multiple records, but should only show one record for the 'NOT SCHEDULED' part
--11/22/10 added code for not scheduled record (added extra record for not scheduled in due_dts)
--WITH ZNoDueDtRecord AS 
--	(SELECT Ord_qty - SUM(Qty+Act_shp_qt) AS Due_dtsQty, Balance - SUM(Qty+Act_shp_qt) AS Due_dtsBal, Sodetail.Uniqueln, Ord_qty, Balance
--	FROM SODETAIL, DUE_DTS
--	WHERE SODETAIL.UNIQUELN = DUE_DTS.UNIQUELN
--	AND dbo.SODETAIL.STATUS <> 'Cancel' and dbo.SODETAIL.STATUS <> 'Closed'
--	Group by Sodetail.Uniqueln, Ord_qty, Balance
--	having ORD_QTY<>SUM(Qty+Act_shp_qt))
	
--INSERT @ZSoBackLogPrep
--SELECT  DISTINCT TOP (100) PERCENT T.CUSTNAME, T.SONO, T.ORDERDATE, 'NOT SCHEDULED' AS PONO, T.UNIQUELN, T.LINE_NO, T.PART_NO, 
--						T.REVISION, T.PART_CLASS, T.PART_TYPE, T.DESCRIPTIO,t.uniq_key, NULL AS SHIP_DTS,NULL AS DUE_DTS,
--                      NULL AS COMMIT_DTS,ZNoDueDtRecord.Due_dtsQty, ZNoDueDtRecord.Due_dtsBal,T.ORD_QTY, 
--                      T.BALANCE, T.PRICE, T.RecordType,t.SaleTypeid, t.SalesRepF, t.SalesRepL, t.CID, T.Quantity, T.FLAT, 0 AS OrdAmt,0 AS BackAmt, T.IS_RMA, 
--					  0 AS test, T.plpricelnk, SPACE(10) AS DUEDT_UNIQ, ShippedQty,
--                      T.OrdQty	, t.MarginBckAmt, t.Territory	
--        FROM @ZSoBackLogPrep T, ZNoDueDtRecord
--		WHERE T.Uniqueln = ZNoDueDtRecord.Uniqueln
--		order by CUSTNAME, SONO, Uniqueln, DUEDT_UNIQ, PLPRICELNK;
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
--select * from ZNoDueDtRecord

-- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
, ZDistItem	AS -- Only get one record per item, then join with ZNoDueDtRecord later
(
	SELECT DISTINCT T.CUSTNAME, T.SONO, T.ORDERDATE, 'NOT SCHEDULED' AS PONO, T.UNIQUELN, T.LINE_NO, T.PART_NO, 
						T.REVISION, T.PART_CLASS, T.PART_TYPE, T.DESCRIPTIO,t.uniq_key, NULL AS SHIP_DTS,NULL AS DUE_DTS,
                      NULL AS COMMIT_DTS, T.ORD_QTY, 
                      T.BALANCE, T.PRICE, T.RecordType,t.SaleTypeid, --t.SalesRepF, t.SalesRepL, t.CID, 
					  T.Quantity, T.FLAT, 0 AS OrdAmt,0 AS BackAmt, T.IS_RMA, 
					  0 AS test, T.plpricelnk, SPACE(10) AS DUEDT_UNIQ, ShippedQty,
                      0 AS OrdQty	, 0 AS MarginBckAmt, t.Territory,NULL AS UsedDate,cast(getdate() as date) as CurrDate,
					  -- 08/15/17 VL:  added functional currency code
					  T.PRICEFC, 0 AS OrdAmtFC, 0 AS BackAmtFC, 
					  T.PRICEPR, 0 AS OrdAmtPR, 0 AS BackAmtPR, 0 AS MarginBckAmtPR, FSymbol, TSymbol, PSymbol
        FROM @ZSoBackLogPrep T
		WHERE T.Uniqueln IN (SELECT Uniqueln FROM  ZNoDueDtRecord))
--select * from ZDistItem

-- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
INSERT @ZSoBackLogPrep
SELECT T.CUSTNAME, T.SONO, T.ORDERDATE, T.PONO, T.UNIQUELN, T.LINE_NO, T.PART_NO, 
						T.REVISION, T.PART_CLASS, T.PART_TYPE, T.DESCRIPTIO,t.uniq_key, T.SHIP_DTS,T.DUE_DTS,
                     T.COMMIT_DTS,ZNoDueDtRecord.Due_dtsQty, ZNoDueDtRecord.Due_dtsBal,T.ORD_QTY, 
                      T.BALANCE, T.PRICE, T.RecordType,t.SaleTypeid, --t.SalesRepF, t.SalesRepL, t.CID, 
					  T.Quantity, T.FLAT, T.OrdAmt,0 AS BackAmt, T.IS_RMA, 
					  T.test, T.plpricelnk, T.DUEDT_UNIQ, ShippedQty,
                      T.OrdQty	, t.MarginBckAmt, t.Territory
					  ,null,cast(getdate() as date),null,null,null,	--04/11/17 DRP:  added
					  -- 08/15/17 VL:  added functional currency code
					  T.PRICEFC, T.OrdAmtFC, 0 AS BackAmtFC,
					  T.PRICEPR, T.OrdAmtPR ,0 AS BackAmtPR, MarginBckAmtPR, FSymbol, TSymbol, PSymbol
        FROM ZDistItem T, ZNoDueDtRecord
		WHERE T.Uniqueln = ZNoDueDtRecord.Uniqueln
		order by CUSTNAME, SONO, Uniqueln, DUEDT_UNIQ, PLPRICELNK;
--select * from @ZSoBackLogPrep

INSERT INTO @ZSoBackLog
SELECT * FROM @ZSoBackLogPrep order by CUSTNAME, SONO, Uniqueln, DUEDT_UNIQ, PLPRICELNK 
----03/28/17 VL:  End of replacement code

update @ZSoBackLogPrep set MinDt = CurrDate-@lcNoDays,MaxDt = CurrDate+@lcNoDays,FutureStartDate = cast(DateAdd(month,6,getdate()) as date) from @ZSoBackLogPrep	---04/11/17 DRP:  Added

---- 11/22/10 End



SET @lnTotalNo = @@ROWCOUNT;
	
IF (@lnTotalNo>0)
SELECT @lcOldUniqueln = Uniqueln, @lcOldDuedt_Uniq = Duedt_Uniq FROM @ZSoBackLog WHERE nRecno = 1	-- Get the uniqueln from first record
BEGIN	
	SET @lnCount=0;
	SET @lnSoAddQty = 0;	-- Need to reset when uniqueln changed
	SET @lnTotalBackQty = 0;	-- Need to reset when uniqueln changed
	SET @lnOldDuedtOrdQty = 0;
	SET @lnOldDuedtBalance = 0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		-- @lnTotalBackQty numeric(9,2)
		-- 08/15/17 VL:  added functional currency code
		SELECT @Due_dtsBal = Due_dtsBal, @Balance = Balance, @Quantity = Quantity, @lcCurrentUniqueln = Uniqueln, @Price = Price, 
			@Flat = Flat, @ShippedQty = Shippedqty, @lcCurrentDuedt_Uniq = Duedt_Uniq, @lnOrdQty = OrdQty, @PriceFC = PriceFC, @PricePR = PricePR  
			FROM @ZSoBackLog WHERE nrecno = @lnCount
			
		BEGIN
		IF (@@ROWCOUNT<>0)
		
			IF @lcCurrentUniqueln <> @lcOldUniqueln
			BEGIN
				SET @lnTotalBackQty = 0;	-- Reset when a new Uniqueln record starts
				SET @lnSoAddQty = 0;
				-- 11/17/10 VL added next two lines
				SET @lnOldDuedtBalance = 0;
				SET @lnOldDuedtOrdQty = 0;				
			END
			
			IF @lcCurrentDuedt_Uniq <> @lcOldDuedt_Uniq
			BEGIN
				SET @lnTotalBackQty	= @lnTotalBackQty + @lnOldDuedtBalance;
				SET @lnSoAddQty	= @lnSoAddQty + @lnOldDuedtOrdQty;
			END
				
			----------------------------------------------------------------------------------------
			----- OrdAmt
			IF ABS(@Quantity - @lnSoAddQty) >= ABS(@Due_dtsBal)	-- Never been added before
				BEGIN
				IF @Flat = 1
					BEGIN			
					-- OrdAmt
					IF @lnSoAddQty = 0
						-- 08/15/17 VL:  added functional currency code
						UPDATE @ZSoBackLog SET OrdAmt = @Price, OrdAmtFC = @PriceFC, OrdAmtPR = @PricePR WHERE nrecno = @lnCount
					END
				ELSE
					BEGIN
					IF @Quantity > 0
						IF @Quantity - @lnSoAddQty >= @Due_dtsBal
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET OrdAmt = @lnOrdQty * @Price, OrdAmtFC = @lnOrdQty * @PriceFC, OrdAmtPR = @lnOrdQty * @PricePR WHERE nrecno = @lnCount
						ELSE
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET OrdAmt = 0, OrdAmtFC = 0, OrdAmtPR = 0 WHERE nrecno = @lnCount
					ELSE
						IF ABS(@Quantity - @lnSoAddQty) >= ABS(@Due_dtsBal)
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET OrdAmt = @lnOrdQty * @Price, OrdAmtFC = @lnOrdQty * @PriceFC, OrdAmtPR = @lnOrdQty * @PricePR WHERE nrecno = @lnCount
						ELSE
							-- 08/15/17 VL:  added functional currency code
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
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET OrdAmt = @Price, OrdAmtFC = @PriceFC, OrdAmtPR = @PricePR WHERE nrecno = @lnCount
						ELSE	
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET OrdAmt = (@Quantity - @lnSoAddQty) * @Price, OrdAmtFC = (@Quantity - @lnSoAddQty) * @PriceFC, OrdAmtPR = (@Quantity - @lnSoAddQty) * @PricePR WHERE nrecno = @lnCount
					ELSE
						-- 08/15/17 VL:  added functional currency code
						UPDATE @ZSoBackLog SET OrdAmt = 0, OrdAmtFC = 0, OrdAmtPR = 0 WHERE nrecno = @lnCount
					END
					
				ELSE
					BEGIN
					IF ABS(@Quantity - @lnSoAddQty) < ABS(@lnOrdQty) AND ABS(@Quantity - @lnSoAddQty) > 0	
						IF @Flat = 1
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET OrdAmt = @Price, OrdAmtFC = @PriceFC, OrdAmtPR = @PricePR WHERE nrecno = @lnCount
						ELSE	
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET OrdAmt = (@Quantity - @lnSoAddQty) * @Price, OrdAmtFC = (@Quantity - @lnSoAddQty) * @PriceFC, OrdAmtPR = (@Quantity - @lnSoAddQty) * @PricePR WHERE nrecno = @lnCount
					ELSE
						-- 08/15/17 VL:  added functional currency code
						UPDATE @ZSoBackLog SET OrdAmt = 0, OrdAmtFC = 0, OrdAmtPR = 0 WHERE nrecno = @lnCount
					END
				END
			END
									
			----------------------------------------------------------------------------------------
			----- BackAmt
			IF ABS(@Quantity - @lnTotalBackQty) >= ABS(@Due_dtsBal)	-- Never been added before
				BEGIN
				IF @Flat = 1
					BEGIN
					-- BackAmt
					IF @lnTotalBackQty = 0 AND @ShippedQty = 0
						-- 08/15/17 VL:  added functional currency code
						UPDATE @ZSoBackLog SET BackAmt = @Price, BackAmtFC = @PriceFC, BackAmtPR = @PricePR WHERE nrecno = @lnCount
					END
				ELSE
					BEGIN
					IF @Quantity > 0
						IF @Quantity - @ShippedQty - @lnTotalBackQty >= @Due_dtsBal
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET BackAmt = @Due_dtsBal * @Price, BackAmtFC = @Due_dtsBal * @PriceFc, BackAmtPR = @Due_dtsBal * @PricePR WHERE nrecno = @lnCount
						ELSE	
							IF @Quantity - @ShippedQty - @lnTotalBackQty > 0	
								-- 08/15/17 VL:  added functional currency code	
								UPDATE @ZSoBackLog SET BackAmt = (@Quantity - @ShippedQty - @lnTotalBackQty) * @Price, 
														BackAmtFC = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PriceFC, 
														BackAmtPR = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PricePR WHERE nrecno = @lnCount
							ELSE
								-- 08/15/17 VL:  added functional currency code
								UPDATE @ZSoBackLog SET BackAmt = 0, BackAmtFC = 0, BackAmtPR = 0 WHERE nrecno = @lnCount
						
					ELSE
						BEGIN
						IF ABS(@Quantity - @ShippedQty - @lnTotalBackQty) >= ABS(@Due_dtsBal)
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET BackAmt = @Due_dtsBal * @Price, BackAmtFC = @Due_dtsBal * @PriceFC, BackAmtPR = @Due_dtsBal * @PricePR WHERE nrecno = @lnCount	
						ELSE
							-- 08/15/17 VL:  added functional currency code
							UPDATE @ZSoBackLog SET BackAmt = 0, BackAmtFC = 0, BackAmtPR = 0 WHERE nrecno = @lnCount		
						END
					END	
				END

	
			IF ABS(@Quantity - @lnTotalBackQty) < ABS(@Due_dtsBal) AND ABS(@Quantity - @lnTotalBackQty) > 0	
				BEGIN
				IF @Flat = 1 AND @lnTotalBackQty = 0 AND @ShippedQty = 0
					BEGIN
						-- 08/15/17 VL:  added functional currency code
						UPDATE @ZSoBackLog SET BackAmt = @Price, BackAmtFC = @PriceFC, BackAmtPR = @PricePR WHERE nrecno = @lnCount
					END
				ELSE
					BEGIN
						IF @Quantity > 0
							BEGIN
							IF @Quantity - @ShippedQty - @lnTotalBackQty > 0
								-- 08/15/17 VL:  added functional currency code
								UPDATE @ZSoBackLog SET BackAmt = (@Quantity - @ShippedQty - @lnTotalBackQty)*@Price,
														BackAmtFC = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PriceFC, 
														BackAmtPR = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PricePR WHERE nrecno = @lnCount	
							ELSE
								-- 08/15/17 VL:  added functional currency code
								UPDATE @ZSoBackLog SET BackAmt = 0, BackAmtFC = 0, BackAmtPR = 0 WHERE nrecno = @lnCount
							END
						ELSE
							BEGIN
							IF ABS(@Quantity - @ShippedQty - @lnTotalBackQty) >= 0
								-- 08/15/17 VL:  added functional currency code
								UPDATE @ZSoBackLog SET BackAmt = (@Quantity - @ShippedQty - @lnTotalBackQty)*@Price,
														BackAmtFC = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PriceFC, 
														BackAmtPR = (@Quantity - @ShippedQty - @lnTotalBackQty) * @PricePR WHERE nrecno = @lnCount	
							ELSE
								-- 08/15/17 VL:  added functional currency code
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

-- 08/15/17 VL separate FC and non FC
/*----------------------
None FC installation
*/----------------------
IF dbo.fn_IsFCInstalled() = 0 
	BEGIN
	select t1.custname, t1.sono, t1.orderdate, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,
	CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,
	CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance, 
	t1.price, t1.RecordType, t1.saletypeid,
	-- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
	--case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,
	--case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,
	--T1.CID,
	t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,
	--CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty,	--04/02/2015 DRP:  replaced with the below
	--CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal,	--04/02/2015 DRP:  replaced with the below
	--CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no, ship_dts Order by orderdate)=1 then OrdAmt else CAST (0.00 as numeric(20,2)) end as OrdAmt,			--04/02/2015 DRP:  replaced with the below
	--CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no, ship_dts Order by orderdate)=1 then BackAmt else cast (0.00 as numeric (20,2)) end as BackAmt,		--04/02/2015 DRP:  replaced with the below
	Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.Territory
	---04/11/17 DRP:  Begin new field addition
	,cast (t1.UseDt as date) as UseDt,cast (t1.MinDt as date) as MinDt,cast (t1.MaxDt as date) as MaxDt
	-- 08/16/17 VL checked with DRP that we only need one PastDue field, so I comment out one of these fields
	--,case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Revenue' then t1.BackAmt 
	--	else case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end  end as PastDue
	,cast (t1.CurrDate as Date) as CurrDate,cast (t1.FutureStartDate as Date) as FutureStartDate
	,case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Revenue' then t1.BackAmt 
		else case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end  end as PastDue
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = DATENAME(month, t1.CurrDate) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M1
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,1,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M2
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,2,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M3
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,3,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M4
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,4,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M5
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,5,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M6
	,case when (t1.UseDt >= t1.FutureStartDate and t1.UseDt <= t1.MaxDt) and @lcBkLogType = 'Revenue' then t1.BackAmt
		else case when (t1.UseDt >= t1.FutureStartDate and t1.UseDt <= t1.MaxDt)and @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end as Future
	--04/11/17 DRP:  End new field addition

	from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog 

	order by CUSTNAME, SONO                      
	)t1
	ORDER BY 1, 2, 3
	END
ELSE
/*-----------------
 FC installation
*/-----------------
	BEGIN

	select t1.custname, t1.sono, t1.orderdate, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,t1.uniq_key,
	CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,
	CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance, 
	t1.price, t1.RecordType, t1.saletypeid,
	-- 05/05/20 VL: removed sales rep info, it caused duplicate records and don't see it's used in the reports
	--case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepF else cast('RepNotInc' as char (15)) end as SalesRepF,
	--case when row_number() over(partition by custname, sono, line_no, ship_dts order by orderdate) = 1 then SalesRepL else cast('RepNotInc' as char (15)) end as SalesRepL,
	--T1.CID,
	t1.flat, t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,
	--CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty,	--04/02/2015 DRP:  replaced with the below
	--CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal,	--04/02/2015 DRP:  replaced with the below
	--CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no, ship_dts Order by orderdate)=1 then OrdAmt else CAST (0.00 as numeric(20,2)) end as OrdAmt,			--04/02/2015 DRP:  replaced with the below
	--CASE WHEN ROW_NUMBER() OVER(Partition by custname,sono, line_no, ship_dts Order by orderdate)=1 then BackAmt else cast (0.00 as numeric (20,2)) end as BackAmt,		--04/02/2015 DRP:  replaced with the below
	Due_dtsQty,Due_dtsBal,OrdAmt,BackAmt,t1.is_rma, t1.MarginBckAmt, t1.Territory
	---04/11/17 DRP:  Begin new field addition
	,cast (t1.UseDt as date) as UseDt,cast (t1.MinDt as date) as MinDt,cast (t1.MaxDt as date) as MaxDt
	-- 08/16/17 VL checked with DRP that we only need one PastDue field, so I comment out one of these fields
	--,case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Revenue' then t1.BackAmt 
	--	else case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end  end as PastDue
	,cast (t1.CurrDate as Date) as CurrDate,cast (t1.FutureStartDate as Date) as FutureStartDate
	,case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Revenue' then t1.BackAmt 
		else case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end  end as PastDue
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = DATENAME(month, t1.CurrDate) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M1
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,1,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M2
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,2,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M3
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,3,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M4
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,4,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M5
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,5,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmt else case when @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end end,0.00) as M6
	,case when (t1.UseDt >= t1.FutureStartDate and t1.UseDt <= t1.MaxDt) and @lcBkLogType = 'Revenue' then t1.BackAmt
		else case when (t1.UseDt >= t1.FutureStartDate and t1.UseDt <= t1.MaxDt)and @lcBkLogType = 'Margin' then t1.MarginBckAmt else 0.00 end end as Future
	--04/11/17 DRP:  End new field addition
	-- 08/15/17 VL:  added functional currency code
	,t1.FSymbol
	,t1.priceFC,OrdAmtFC,BackAmtFC, 0 AS MarginBckAmtFC
	,case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0.00 end as PastDueFC
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = DATENAME(month, t1.CurrDate) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0.00 end end,0.00) as M1FC
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,1,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0.00 end end,0.00) as M2FC
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,2,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0.00 end end,0.00) as M3FC
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,3,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0.00 end end,0.00) as M4FC
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,4,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0.00 end end,0.00) as M5FC
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,5,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtFC else 0.00 end end,0.00) as M6FC
	,case when (t1.UseDt >= t1.FutureStartDate and t1.UseDt <= t1.MaxDt) and @lcBkLogType = 'Revenue' then t1.BackAmtFC
		else 0.00 end as FutureFC, t1.TSymbol
	,t1.pricePR,OrdAmtPR,BackAmtPR, t1.MarginBckAmtPR
	,case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Revenue' then t1.BackAmtPR 
		else case when (t1.UseDt >= t1.MinDt and t1.UseDt < t1.CurrDate) and @lcBkLogType = 'Margin' then t1.MarginBckAmtPR else 0.00 end  end as PastDuePR
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = DATENAME(month, t1.CurrDate) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else case when @lcBkLogType = 'Margin' then t1.MarginBckAmtPR else 0.00 end end end,0.00) as M1PR
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,1,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else case when @lcBkLogType = 'Margin' then t1.MarginBckAmtPR else 0.00 end end end,0.00) as M2PR
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,2,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else case when @lcBkLogType = 'Margin' then t1.MarginBckAmtPR else 0.00 end end end,0.00) as M3PR
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,3,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else case when @lcBkLogType = 'Margin' then t1.MarginBckAmtPR else 0.00 end end end,0.00) as M4PR
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,4,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else case when @lcBkLogType = 'Margin' then t1.MarginBckAmtPR else 0.00 end end end,0.00) as M5PR
	,isnull(case when t1.usedt >= t1.CurrDate and t1.UseDt < t1.FutureStartDate and DATENAME(month, t1.UseDt) = datename(month,DATEADD(month,5,t1.CurrDate)) then 
		case when @lcBkLogType = 'Revenue' then t1.BackAmtPR else case when @lcBkLogType = 'Margin' then t1.MarginBckAmtPR else 0.00 end end end,0.00) as M6PR
	,case when (t1.UseDt >= t1.FutureStartDate and t1.UseDt <= t1.MaxDt) and @lcBkLogType = 'Revenue' then t1.BackAmtPR
		else case when (t1.UseDt >= t1.FutureStartDate and t1.UseDt <= t1.MaxDt)and @lcBkLogType = 'Margin' then t1.MarginBckAmtPR else 0.00 end end as FuturePR
	,t1.PSymbol
	from(SELECT TOP (100) PERCENT * FROM @ZSoBackLog 

	order by CUSTNAME, SONO                      
	)t1
	ORDER BY 1, 2, 3

	END
end