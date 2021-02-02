                                    
-- =============================================  
-- Author:  <Vicky and Debbie>   
-- Create date: <11/17/2010>  
-- Description: <compiles detailed sales order Backlog information>  
-- Reports:     <used on sobgdtpt.rpt, sobgnodt.rpt, sobgdtmo.rpt>  
-- Modified: 01/07/2015 DRP:  needed to add all of the report parameters to the procedure itself in order for it to work properly with the Cloud Parameters  
-- Added the /*CUSTOMER LIST*/ section . . added sodetail.status to ZSoCust . . Added the @lcRptType section at the end of the report to control the results based on the selections the users make within the parameters.   
-- 04/02/2015 DRP:  Found that I needed to remove the CASE WHEN ROW_NUMBER() OVER(Partition . . . for Due_dtsQty and Due_dtsBal, because there are scenarios where the users will have the same Schedule dates multiple times.  
-- 06/24/2015 DRP:  Made the same change as on 04/02/2015 but throughout the entire procedure this time. (I should have done it on 04/02/2015 originally)  
-- 09/17/15 DRP:  Noticed that in the Summary version of the results I was missing the Due_dtsQty ,Hold and z1.Is_rma columns  
-- 02/15/2016 VL:   Added FC code  
-- 04/08/2016 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement  
-- 04/18/17 DRP:  removed @customerStatus parameter.  Added a section for Summary/Month results  
-- 04/24/17 DRP:  found in the Summary/Month selection I needed to add the ShipYr and ShipMnth so that we can get it to sort in the correct order on the quickview and report form.   
-- 01/22/18 VL:   Added MrpOnHold column, request by Pro-Active  
-- 07/16/18 VL changed custname from char(35) to char(50)  
-- 01/02/19 Shrikant B: Changed  @userId from UNIQIDENTIFIER to VARCHAR(40) for fixed the conversion problem
-- 01/04/19 Shrikant B: Changed  Reverts @userId Changes from  VARCHAR(40) to UNIQIDENTIFIER 
-- =============================================  
CREATE PROCEDURE [dbo].[rptSoBackLogDtlWM]   
--DECLARE  
@lcCustNo VARCHAR(max) = 'All'  
,@lcSupZero AS CHAR(3) = 'No' --Yes = Suppress zero Backlog Qty, No = don't suppress zero backlog qty.  When @lcRptType = Summary then this has to be 'No'  
,@showCommit AS CHAR(3) = 'No' --Yes = Show Commit Date, No = Don't show commit date  
--,@customerStatus varchar (20) = 'Active' --04/18/17 DRP:  removed  
,@lcRptType as char(10) = 'Detailed' --01/07/2015 DRP:  (Detailed or Summary)  Added for Quickview results so it knows to display detailed or summary results.   
,@lcSort as char(20) = 'Product' --01/07/2015 DRP: (Product, Month)  This is where the users will pick how they wish for the report to be orderd by.   
-- 01/02/19 Shrikant B: Changed  @userId from UNIQIDENTIFIER to VARCHAR(40) for fixed the conversion problem 
-- 01/04/19 Shrikant B: Changed  Reverts @userId Changes from  VARCHAR(40) to UNIQIDENTIFIER 
,@userId uniqueidentifier = null  
  
AS  
BEGIN  
  
/*CUSTOMER LIST*/ --01/07/2015 ADDED   
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
  
DECLARE @lnCount int, @lnTotalNo int, @Due_dtsBal numeric(9,2), @Balance numeric(9,2), @lnTotalBackQty numeric(9,2), @Quantity numeric(10,2),  
  @Flat bit, @ShippedQty numeric(9,2), @lcOldUniqueln char(10), @lcCurrentUniqueln char(10), @Price numeric(14,5), @lcOldDuedt_Uniq char(10),   
  @lcCurrentDuedt_Uniq char(10), @lnOldDuedtBalance numeric(9,2), @lnSoAddQty numeric(9,2), @lnOrdQty numeric(9,2), @lnOldDuedtOrdQty numeric(9,2),  
  @lnSoBkQty numeric(9,2), @lnOrdAmt numeric(20,2), @lnBackAmt numeric(20,2), @lnSoPAllCnt int, @lnSoPTotalCnt int, @lnSoPcnt int,   
  @lSoUniqueln char(10), @lnBackQty numeric(9,2), @lcPlpricelnk char(10), @lcChkPlPricelnk char(10),  
  @PriceFC numeric(14,5), @lnOrdAmtFC numeric(20,2), @lnBackAmtFC numeric(20,2);  
  
  
-- 02/15/16 VL added for FC installed or not  
DECLARE @lFCInstalled bit  
-- 04/08/16 VL changed to get FC installed from function  
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()  
  
BEGIN  
IF @lFCInstalled = 0  
 BEGIN  
 -- 01/22/18 VL added MrpOnHold  
 DECLARE @ZSoBackLogPrep TABLE (Sono char(10), OrderDate smalldatetime, SoOrdqty numeric(9,2), Sobackqty numeric(9,2),   
  Shippedqty numeric(9,2), Custno char(10), Uniq_key char(10), Uniqueln char(10), Line_no char(7), Is_Rma bit, Pono char(20),   
  Sodet_Desc char(45),Hold char(10), MrpOnHold bit, Due_dtsqty numeric(16,2) NULL, Due_dtsbal numeric(16,2) NULL, No_Duedts bit,
  Need_NewLine bit,   
  Ship_dts smalldatetime, Commit_dts smalldatetime, Ordqty numeric(17,2), BackQty numeric(17,2), NoSchedule bit,   
  SchdRef char(15), Due_dts smalldatetime);  
  
 -- 01/22/18 VL added MrpOnHold  
 -- 07/16/18 VL changed custname from char(35) to char(50)  
 DECLARE @ZSoBackLog TABLE (nrecno int identity, Custno char(10),Custname char(50), Sono char(10), OrderDate smalldatetime, Pono char(20), Uniqueln char(10),   
  Line_no char(7), ShippedQty numeric(9,2), Part_no char(45), Revision char(8), Part_class char(8), Part_type char(8), Descriptio char(45),   
  Ship_dts Smalldatetime, Due_dts SmallDateTime, COMMIT_DTS SmallDateTime, Due_dtsQty numeric(9,2), Due_dtsBal numeric(9,2),   
  Ord_qty numeric(9,2), balance numeric(9,2), OrdAmt numeric(20,2), BackAmt numeric(20,2), Is_rma bit, SchdRef char(15),Hold char(10),uniq_key char(10),  
  MrpOnHold bit);  
  
 DECLARE @ZSoPrices TABLE (nrecno int identity, Price numeric(14,5), Quantity numeric(10,2), Flat bit, Plpricelnk char(10));  
  
 WITH ZSoCust AS   
 (  
  -- 01/22/18 VL added MrpOnHold  
  SELECT Sodetail.Sono, OrderDate, Ord_qty AS SoOrdQty, Balance AS SOBackQty, ShippedQty, Custno, Uniq_key, Uniqueln,   
   Line_no, Is_Rma ,Pono, Sodet_Desc,Case when SODETAIL.STATUS = 'Admin Hold' then 'Admin Hold' else case when SODETAIL.STATUS = 'Mfgr Hold' then 'Mfgr Hold' else '' end end as Hold,  
   MrpOnHold  
   FROM Sodetail, Somain   
   WHERE Sodetail.Sono = Somain.Sono   
   AND (Somain.Ord_type <> 'Closed'   
   AND Somain.Ord_type <> 'Cancel')  
   AND (Sodetail.Status <> 'Closed'  
   AND Sodetail.Status <> 'Cancel')   
   AND Balance <> 0   
   and 1 = case when somain.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end --01/07/2015 ADDED  
  
 ),  
 ZDue_dts2 AS  
 (  
  SELECT Uniqueln, SUM(Qty+Act_shp_qt) AS Due_dtsQty, SUM(Qty) AS Due_dtsBal  
   FROM Due_dts  
   WHERE Uniqueln IN (SELECT Uniqueln FROM ZSoCust)   
   GROUP BY Uniqueln   
 ),  
 ZSoCust2 AS  
 (  
  SELECT ZSoCust.*, Due_dtsQty, Due_dtsBal, CASE WHEN ZDue_dts2.Due_dtsQty IS NULL THEN 1 ELSE 0 END AS No_Duedts,  
   CASE WHEN ZDue_dts2.Due_dtsQty IS NULL THEN 0 ELSE   
    CASE WHEN ABS(SoOrdqty)>ABS(ZDue_dts2.Due_dtsQty) THEN 1 ELSE 0 END END AS Need_NewLine  
   FROM ZSoCust LEFT OUTER JOIN ZDue_dts2  
   ON ZSoCust.Uniqueln = ZDue_dts2.Uniqueln  
 ),  
 ZDue_dts AS  
 (  
  SELECT Uniqueln, Qty+Act_shp_qt AS Duedts_Ordqty, Qty AS Duedts_BackQty, Ship_dts, Commit_dts, Due_dts   
   FROM Due_dts   
   WHERE Uniqueln IN (SELECT Uniqueln FROM ZSoCust)   
 ),  
 --ZSoBkJoin AS  
 --( SELECT ZSoCust2.*, CASE WHEN Ship_dts IS NULL THEN CONVERT(smalldatetime, '') ELSE Ship_dts END AS Ship_dts,   
 --  CASE WHEN Commit_dts IS NULL THEN CONVERT(smalldatetime, '') ELSE Commit_dts END AS Commit_dts,  
 --  CASE WHEN ZSoCust2.No_duedts = 1 THEN SOOrdQty ELSE Duedts_Ordqty END AS OrdQty,  
 --  CASE WHEN Duedts_BackQty IS NULL THEN SOBackQty ELSE Duedts_BackQty END AS BackQty, 0 AS NoSchedule,  
 --  CASE WHEN DUE_DTS IS NULL THEN CONVERT(smalldatetime, '') ELSE DUE_DTS END AS Due_dts   
 --  FROM ZSoCust2 LEFT OUTER JOIN ZDue_dts  
 --  ON ZSoCust2.Uniqueln = ZDue_dts.Uniqueln   
 -- UNION ALL   
 --  SELECT ZSoCust2.*, CONVERT(smalldatetime, '') AS Ship_dts, CONVERT(smalldatetime, '') AS Commit_dts,   
 --  SoOrdqty-Due_dtsqty AS OrdQty, SoBackqty-Due_dtsBal AS BackQty, 1 AS NoSchedule,   
 --  CONVERT(smalldatetime, '') AS Due_dts   
 --  FROM ZSoCust2   
 --  WHERE Need_NewLine = 1  
 --)  
 ZSoBkJoin AS  
 ( SELECT ZSoCust2.*, Ship_dts, Commit_dts,  
   CASE WHEN ZSoCust2.No_duedts = 1 THEN SOOrdQty ELSE Duedts_Ordqty END AS OrdQty,  
   CASE WHEN Duedts_BackQty IS NULL THEN SOBackQty ELSE Duedts_BackQty END AS BackQty, 0 AS NoSchedule, SPACE(15) AS SchdRef,  
   Due_dts   
   FROM ZSoCust2 LEFT OUTER JOIN ZDue_dts  
   ON ZSoCust2.Uniqueln = ZDue_dts.Uniqueln   
  UNION ALL   
   SELECT ZSoCust2.*, NULL AS Ship_dts, NULL AS Commit_dts,   
   SoOrdqty-Due_dtsqty AS OrdQty, SoBackqty-Due_dtsBal AS BackQty, 1 AS NoSchedule, 'NOT SCHEDULED' AS SchdRef,  
   NULL AS Due_dts   
   FROM ZSoCust2   
   WHERE Need_NewLine = 1  
 )  
  
 INSERT @ZSoBackLogPrep  
 SELECT * FROM ZSoBkJoin  
  
 -- 01/22/18 VL added MrpOnHold  
 INSERT @ZSoBackLog  
 SELECT ZS.Custno,Custname, Zs.Sono, Zs.OrderDate, Zs.Pono, Zs.Uniqueln, Line_no, Zs.ShippedQty,  
  CASE WHEN Part_no IS NULL THEN Sodet_Desc ELSE CAST(INVENTOR.part_no AS CHAR(45)) END AS PART_NO,  
  CASE WHEN REVISION IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.REVISION END AS REVISION,  
  CASE WHEN Part_Class IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.Part_Class END AS Part_Class,  
  CASE WHEN Part_Type IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.Part_Type END AS Part_Type,  
  CASE WHEN Descript IS NULL THEN Sodet_Desc ELSE CAST(INVENTOR.Descript AS CHAR(45)) END AS DESCRIPTIO,  
  Zs.Ship_dts, Zs.Due_dts, Zs.Commit_dts, OrdQty AS Due_dtsQty, BackQty AS Due_dtsBal, SoOrdQty AS Ord_qty,  
  SOBackQty AS Balance, 0 AS OrdAmt, 0 AS BackAmt, Zs.Is_rma, ZS.SchdRef,Zs.Hold,zs.Uniq_key, Zs.MrpOnHold  
  FROM CUSTOMER, @ZSoBackLogPrep ZS LEFT OUTER JOIN INVENTOR  
  ON ZS.Uniq_key = INVENTOR.UNIQ_KEY  
  WHERE Customer.Custno = ZS.Custno   
  AND Customer.Status = 'Active'  
  ORDER BY Custno, Zs.SONO, Zs.Uniqueln, NoSchedule DESC  
   
 SET @lnTotalNo = @@ROWCOUNT;  
 SET @lnCount=0;  
 SET @lnSoAddQty = 0; -- Need to reset when uniqueln changed  
 SET @lnSoBkQty = 0   
 SET @lnSoPTotalCnt = 0  
 IF (@lnTotalNo>0)  
 BEGIN   
  SELECT @lcOldUniqueln = Uniqueln FROM @ZSoBackLog WHERE nRecno = 1 -- Get the uniqueln from first record  
   
  WHILE @lnTotalNo>@lnCount  
  BEGIN  
   SET @lnCount=@lnCount+1;  
   SELECT @lSoUniqueln = Uniqueln, @lnOrdQty = Due_dtsQty, @lnBackQty = Due_dtsBal, @ShippedQty = ShippedQty  
    FROM @ZSoBackLog  
    WHERE nrecno = @lnCount  
    
   IF @@ROWCOUNT <> 0 -- Get one @ZSoBackLog record  
   BEGIN  
    
    IF @lcOldUniqueln <> @lSoUniqueln  
    BEGIN  
     SET @lnSoAddQty = 0; -- Need to reset when uniqueln changed  
     SET @lnSoBkQty = 0   
    END   
      
    SET @lnOrdAmt = 0  
    SET @lnBackAmt = 0    
     
    -- Prepare Soprices for selected uniqueln record  
    DELETE FROM @ZSoPrices WHERE 1=1 -- Delete all old records  
  
    INSERT @ZSoPrices   
    SELECT Price, Quantity, Flat, Plpricelnk   
     FROM Soprices  
     WHERE UNIQUELN = @lSoUniqueln  
      
    SET @lnSoPcnt = @@ROWCOUNT  
    SET @lnSoPAllCnt = @lnSoPcnt + @lnSoPTotalCnt  
    BEGIN  
    IF @lnSoPcnt > 0  
     
     WHILE @lnSoPAllCnt > @lnSoPTotalCnt  
     BEGIN  
      SET @lnSoPTotalCnt = @lnSoPTotalCnt + 1;  
      SELECT @Price = Price, @Quantity = Quantity, @Flat = Flat, @lcPlpricelnk = Plpricelnk       
       FROM @ZSoPrices WHERE nrecno = @lnSoPTotalCnt  
        
      --- Update OrdAmt  
      ----------------------------------------------------------------------------------------  
      ----- OrdAmt  
      IF (@Quantity >= 0 AND @Quantity - @lnSoAddQty >= @lnOrdQty) OR (@Quantity < 0 AND ABS(@Quantity - @lnSoAddQty) >= ABS(@lnOrdQty))  -- Never been added before  
       BEGIN  
       IF @Flat = 1  
        BEGIN     
        -- OrdAmt  
        IF @lnSoAddQty = 0  
         SET @lnOrdAmt = @lnOrdAmt + @Price  
        END  
       ELSE  
        BEGIN  
         SET @lnOrdAmt = @lnOrdAmt + @lnOrdQty * @Price  
        END  
       END  
  
       
      IF (@Quantity >= 0 AND @Quantity - @lnSoAddQty < @lnOrdQty AND @Quantity - @lnSoAddQty > 0) OR   
       (@Quantity < 0 AND ABS(@Quantity - @lnSoAddQty) < ABS(@lnOrdQty) AND ABS(@Quantity - @lnSoAddQty) > 0)  
       BEGIN  
       IF @Flat = 1  
        BEGIN  
        -- OrdAmt  
        IF @lnSoAddQty = 0  
         SET @lnOrdAmt = @lnOrdAmt + @Price  
        END  
       ELSE  
        BEGIN  
         SET @lnOrdAmt = @lnOrdAmt + (@Quantity - @lnSoAddQty) *  @Price  
        END  
       END        
         
        
       
       
      --- Update BackAmt  
      ----------------------------------------------------------------------------------------  
      ----- BackAmt     
       
      IF (@Quantity >=0 AND @Quantity - @lnSoBkQty >= @lnBackQty) OR  
       (@Quantity < 0 AND ABS(@Quantity - @lnSoBkQty) >= ABS(@lnBackQty)) -- Never been added before  
       BEGIN  
       IF @Flat = 1  
        BEGIN  
         SELECT @lcChkPlPricelnk = Plpricelnk FROM PLPRICES WHERE Plpricelnk = @lcPlpricelnk  
         IF @@ROWCOUNT <> 0 AND  @lnSoBkQty = 0 AND @ShippedQty =0  
          SET @lnBackAmt =  @lnBackAmt + @Price  
        END  
       ELSE  
        BEGIN  
        IF @Quantity >= 0  
         BEGIN  
         IF @Quantity - @ShippedQty - @lnSoBkQty >= @lnBackQty  
          SET @lnBackAmt = @lnBackAmt + @lnBackQty * @Price  
         ELSE   
          IF @Quantity - @ShippedQty - @lnBackQty > 0    
           SET @lnBackAmt = @lnBackAmt + (@Quantity-@ShippedQty-@lnSoBkQty)*@Price  
          ELSE  
           SET @lnBackAmt = @lnBackAmt + 0  
         END  
        ELSE  
         BEGIN  
         IF ABS(@Quantity - @ShippedQty - @lnSoBkQty) >= ABS(@lnBackQty)  
          SET @lnBackAmt = @lnBackAmt + @lnBackQty * @Price  
         ELSE  
          SET @lnBackAmt = @lnBackAmt + 0  
         END  
        END   
       END  
  
     
      IF ABS(@Quantity - @lnSoBkQty) < ABS(@lnBackQty) AND ABS(@Quantity - @lnSoBkQty) > 0   
       BEGIN  
       IF @Flat = 1 AND @lnTotalBackQty = 0 AND @ShippedQty = 0  
        BEGIN  
         SELECT @lcChkPlPricelnk = Plpricelnk FROM PLPRICES WHERE Plpricelnk = @lcPlpricelnk  
         IF @@ROWCOUNT <> 0 AND  @lnSoBkQty = 0 AND @ShippedQty =0  
          SET @lnBackAmt =  @lnBackAmt + @Price  
        END  
       ELSE  
        BEGIN  
         IF @Quantity >= 0  
          BEGIN  
          IF @Quantity - @ShippedQty - @lnSoBkQty >= 0  
           SET @lnBackAmt = @lnBackAmt + (@Quantity-@ShippedQty-@lnSoBkQty)*@Price  
          ELSE  
           SET @lnBackAmt = @lnBackAmt + 0  
          END  
         ELSE  
          BEGIN  
          IF ABS(@Quantity - @ShippedQty - @lnSoBkQty) >= 0  
           SET @lnBackAmt = @lnBackAmt + (@Quantity-@ShippedQty-@lnSoBkQty)*@Price  
          ELSE  
           SET @lnBackAmt = @lnBackAmt + 0  
          END  
        END  
       END  
   
       
     END  
    END  
     
    SET @lnSoAddQty = @lnSoAddQty + @lnOrdQty  
    SET @lnSoBkQty = @lnSoBkQty + @lnBackQty  
    SET @lcOldUniqueln = @lSoUniqueln  
    UPDATE @ZSoBackLog SET OrdAmt = @lnOrdAmt, BackAmt = @lnBackAmt WHERE nrecno = @lnCount   
   END  
  END       
 END        
  
 if (@lcRptType = 'Summary' and  @lcSort = 'Product') --04/18/17 DRP:  added @lcSort = 'Product'  
  Begin  
   -- 01/22/18 VL added MrpOnHold  
   select Z1.Custno,Z1.custname, Z1.sono, Z1.pono, Z1.uniqueln, Z1.line_no, Z1.part_no, Z1.revision, Z1.part_class, Z1.part_type, Z1.descriptio, sum(z1.Ord_qty) as Ord_qty  
     ,sum(z1.Due_dtsQty) as Due_dtsQty,sum(z1.Due_dtsBal) as Due_dtsBal,sum(z1.OrdAmt) as OrdAmt,
	 sum(z1.backAmt) As BackAmt,z1.uniq_key,z1.Hold,
	 case when z1.Is_rma = 1 then 'RMA' else '' end as Is_Rma --09/17/15 DRP:  Added sum(z1.Due_dtsQty) as Due_dtsQty,z1.Hold and z1.Is_Rma  
     ,z1.MrpOnHold  
   from (select t1.custno,t1.custname, t1.sono, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,  
       CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	        Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
       CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1
	        Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
       t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
       --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty, --06/24/2015 DRP:  Replaced by below  
       --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal, --06/24/2015 DRP:  Replaced by below  
       Due_dtsQty,Due_dtsBal,  
       t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key, t1.MrpOnHold  
       from (SELECT TOP (100) PERCENT * FROM @ZSoBackLog order by CUSTNAME, SONO) t1 
	    where 1 = case when @lcSupZero = 'No' then 1 
		               when @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) then 1 else 0 end  
       ) Z1  
   Group by Z1.Custno,Z1.custname, Z1.sono, Z1.pono, Z1.uniqueln, Z1.line_no, Z1.part_no, Z1.revision, Z1.part_class, Z1.part_type,
            Z1.descriptio,z1.uniq_key,z1.Hold,z1.Is_rma, z1.MrpOnHold  
  End  
  
 else if  (@lcRptType = 'Summary' and @lcSort = 'Month') --04/18/17 DRP:  Added the Summary/Month section  
  Begin  
   -- 01/22/18 VL added MrpOnHold  
   select z1.MonthHd ,Z1.Custno,Z1.custname, Z1.sono, Z1.pono, Z1.uniqueln, Z1.line_no, Z1.part_no, Z1.revision, Z1.part_class, Z1.part_type,
         Z1.descriptio, sum(z1.Ord_qty) as Ord_qty  
     ,sum(z1.Due_dtsQty) as Due_dtsQty,sum(z1.Due_dtsBal) as Due_dtsBal,sum(z1.OrdAmt) as OrdAmt,
	 sum(z1.backAmt) As BackAmt,z1.uniq_key,z1.Hold,
	 case when z1.Is_rma = 1 then 'RMA' else '' end as Is_Rma --09/17/15 DRP:  Added sum(z1.Due_dtsQty) as Due_dtsQty,z1.Hold and z1.Is_Rma  
     ,z1.ShipYr,z1.ShipMnth --04/24/17 DRP:  Added to make sure that the sort order is   
     ,Z1.MrpOnHold  
   from (select isnull(DATENAME(yyyy, t1.Ship_dts)+'  '+DATENAME(mm, t1.Ship_dts),'Not Scheduled') AS MonthHd,t1.custno,t1.custname, t1.sono, 
         t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,  
       CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	        Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
       CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	        Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
       t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
       --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty, --06/24/2015 DRP:  Replaced by below  
       --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal, --06/24/2015 DRP:  Replaced by below  
       Due_dtsQty,Due_dtsBal,  
       t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key  
       ,isnull(DATENAME(yyyy, t1.Ship_dts),'') as ShipYr, isnull(DATEpart(mm, t1.Ship_dts),'') as ShipMnth --04/24/17 DRP:  Added to make sure that the sort order is correct  
       ,t1.MrpOnHold  
       from (SELECT TOP (100) PERCENT * FROM @ZSoBackLog order by CUSTNAME, SONO) t1 
	    where 1 = case when @lcSupZero = 'No' then 1 
					   when @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) then 1 else 0 end  
       ) Z1  
   Group by z1.ShipYr,z1.ShipMnth,Z1.Custno,Z1.custname, Z1.sono, Z1.pono, Z1.uniqueln, Z1.line_no, Z1.part_no, Z1.revision, Z1.part_class, Z1.part_type, Z1.descriptio,z1.uniq_key,z1.Hold,z1.Is_rma,z1.MonthHd,z1.MrpOnHold  
  END  
  
 else if (@lcRptType = 'Detailed' and @lcSort = 'Product')  
  Begin  
   -- 01/22/18 VL added MrpOnHold  
   select t1.custno,t1.custname, t1.sono, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	      Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	      Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty,  06/24/2015 DRP:  Replaced by below  
     --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal,  06/24/2015 DRP:  Replaced by below  
     Due_dtsQty,Due_dtsBal,  
     t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key  
     ,t1.MrpOnHold  
   from (SELECT TOP (100) PERCENT * FROM @ZSoBackLog order by CUSTNAME, SONO) t1
     where 1 = case when @lcSupZero = 'No' then 1
					when @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) then 1 else 0 end  
   order by Custname,part_no,revision,Ship_dts,sono,Line_no  
  
  End   
  
 else if (@lcRptType = 'Detailed' and @lcSort = 'Month')  
  Begin  
   -- 01/22/18 VL added MrpOnHold  
   select isnull(DATENAME(mm, t1.Ship_dts)+' '+DATENAME(yyyy, t1.Ship_dts),'Not Scheduled') AS MonthHd  ,
        t1.custno,t1.custname, t1.sono, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type,
	    t1.descriptio,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	      Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	      Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty, --04/02/2015 DRP:  replaced with the below  
     --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal, --04/02/2015 DRP:  replaced with the below  
     Due_dtsQty,Due_dtsBal,t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key  
     ,t1.MrpOnHold  
   from (SELECT TOP (100) PERCENT * FROM @ZSoBackLog order by CUSTNAME, SONO) t1 
     where 1 = case when @lcSupZero = 'No' then 1
	           when @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) then 1 else 0 end  
   order by Custname,ship_Dts,part_no,revision,sono,Line_no  
  
  End   
 END  
ELSE  
-- FC installed  
 BEGIN  
 -- 01/22/18 VL added MrpOnHold  
 DECLARE @ZSoBackLogPrepFC TABLE (Sono char(10), OrderDate smalldatetime, SoOrdqty numeric(9,2), Sobackqty numeric(9,2),   
  Shippedqty numeric(9,2), Custno char(10), Uniq_key char(10), Uniqueln char(10), Line_no char(7), Is_Rma bit, Pono char(20),   
  Sodet_Desc char(45),Hold char(10), MrpOnHold bit, Fcused_Uniq char(10), Currency char(3),  
  Due_dtsqty numeric(16,2) NULL, Due_dtsbal numeric(16,2) NULL, No_Duedts bit, Need_NewLine bit,   
  Ship_dts smalldatetime, Commit_dts smalldatetime, Ordqty numeric(17,2), BackQty numeric(17,2), NoSchedule bit,   
  SchdRef char(15), Due_dts smalldatetime);  
  
 -- 01/22/18 VL added MrpOnHold  
 -- 07/16/18 VL changed custname from char(35) to char(50)  
 DECLARE @ZSoBackLogFC TABLE (nrecno int identity, Custno char(10),Custname char(50), Sono char(10), OrderDate smalldatetime, Pono char(20), Uniqueln char(10),   
  Line_no char(7), ShippedQty numeric(9,2), Part_no char(45), Revision char(8), Part_class char(8), Part_type char(8), Descriptio char(45),   
  Ship_dts Smalldatetime, Due_dts SmallDateTime, COMMIT_DTS SmallDateTime, Due_dtsQty numeric(9,2), Due_dtsBal numeric(9,2),   
  Ord_qty numeric(9,2), balance numeric(9,2), OrdAmt numeric(20,2), BackAmt numeric(20,2), Is_rma bit, SchdRef char(15),Hold char(10),uniq_key char(10),  
  OrdAmtFC numeric(20,2), BackAmtFC numeric(20,2), Currency char(3), MrpOnHold bit);  
    
 DECLARE @ZSoPricesFC TABLE (nrecno int identity, Price numeric(14,5), Quantity numeric(10,2), Flat bit, Plpricelnk char(10), PriceFC numeric(14,5));  
  
  
 WITH ZSoCust AS   
 (  
  -- 01/22/18 VL added MrpOnHold  
  SELECT Sodetail.Sono, OrderDate, Ord_qty AS SoOrdQty, Balance AS SOBackQty, ShippedQty, Custno, Uniq_key, Uniqueln,   
   Line_no, Is_Rma ,Pono, Sodet_Desc,
   Case when SODETAIL.STATUS = 'Admin Hold' then 'Admin Hold' 
        else 
		case when SODETAIL.STATUS = 'Mfgr Hold' then 'Mfgr Hold' 
		else '' end end as Hold,  
   Somain.Fcused_uniq AS Fcused_uniq, Symbol AS Currency, MrpOnHold  
   FROM Sodetail, Somain, Fcused  
   WHERE Sodetail.Sono = Somain.Sono   
   AND (Somain.Ord_type <> 'Closed'   
   AND Somain.Ord_type <> 'Cancel')  
   AND (Sodetail.Status <> 'Closed'  
   AND Sodetail.Status <> 'Cancel')   
   AND Balance <> 0   
   AND Somain.FCUSED_UNIQ = Fcused.FcUsed_Uniq  
   and 1 = case when somain.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end --01/07/2015 ADDED  
  
 ),  
 ZDue_dts2 AS  
 (  
  SELECT Uniqueln, SUM(Qty+Act_shp_qt) AS Due_dtsQty, SUM(Qty) AS Due_dtsBal  
   FROM Due_dts  
   WHERE Uniqueln IN (SELECT Uniqueln FROM ZSoCust)   
   GROUP BY Uniqueln   
 ),  
 ZSoCust2 AS  
 (  
  SELECT ZSoCust.*, Due_dtsQty, Due_dtsBal, CASE WHEN ZDue_dts2.Due_dtsQty IS NULL THEN 1 ELSE 0 END AS No_Duedts,  
   CASE WHEN ZDue_dts2.Due_dtsQty IS NULL THEN 0 ELSE   
    CASE WHEN ABS(SoOrdqty)>ABS(ZDue_dts2.Due_dtsQty) THEN 1 ELSE 0 END END AS Need_NewLine  
   FROM ZSoCust LEFT OUTER JOIN ZDue_dts2  
   ON ZSoCust.Uniqueln = ZDue_dts2.Uniqueln  
 ),  
 ZDue_dts AS  
 (  
  SELECT Uniqueln, Qty+Act_shp_qt AS Duedts_Ordqty, Qty AS Duedts_BackQty, Ship_dts, Commit_dts, Due_dts   
   FROM Due_dts   
   WHERE Uniqueln IN (SELECT Uniqueln FROM ZSoCust)   
 ),  
 --ZSoBkJoin AS  
 --( SELECT ZSoCust2.*, CASE WHEN Ship_dts IS NULL THEN CONVERT(smalldatetime, '') ELSE Ship_dts END AS Ship_dts,   
 --  CASE WHEN Commit_dts IS NULL THEN CONVERT(smalldatetime, '') ELSE Commit_dts END AS Commit_dts,  
 --  CASE WHEN ZSoCust2.No_duedts = 1 THEN SOOrdQty ELSE Duedts_Ordqty END AS OrdQty,  
 --  CASE WHEN Duedts_BackQty IS NULL THEN SOBackQty ELSE Duedts_BackQty END AS BackQty, 0 AS NoSchedule,  
 --  CASE WHEN DUE_DTS IS NULL THEN CONVERT(smalldatetime, '') ELSE DUE_DTS END AS Due_dts   
 --  FROM ZSoCust2 LEFT OUTER JOIN ZDue_dts  
 --  ON ZSoCust2.Uniqueln = ZDue_dts.Uniqueln   
 -- UNION ALL   
 --  SELECT ZSoCust2.*, CONVERT(smalldatetime, '') AS Ship_dts, CONVERT(smalldatetime, '') AS Commit_dts,   
 --  SoOrdqty-Due_dtsqty AS OrdQty, SoBackqty-Due_dtsBal AS BackQty, 1 AS NoSchedule,   
 --  CONVERT(smalldatetime, '') AS Due_dts   
 --  FROM ZSoCust2   
 --  WHERE Need_NewLine = 1  
 --)  
 ZSoBkJoin AS  
 ( SELECT ZSoCust2.*, Ship_dts, Commit_dts,  
   CASE WHEN ZSoCust2.No_duedts = 1 THEN SOOrdQty ELSE Duedts_Ordqty END AS OrdQty,  
   CASE WHEN Duedts_BackQty IS NULL THEN SOBackQty ELSE Duedts_BackQty END AS BackQty, 0 AS NoSchedule, SPACE(15) AS SchdRef,  
   Due_dts   
   FROM ZSoCust2 LEFT OUTER JOIN ZDue_dts  
   ON ZSoCust2.Uniqueln = ZDue_dts.Uniqueln   
  UNION ALL   
   SELECT ZSoCust2.*, NULL AS Ship_dts, NULL AS Commit_dts,   
   SoOrdqty-Due_dtsqty AS OrdQty, SoBackqty-Due_dtsBal AS BackQty, 1 AS NoSchedule, 'NOT SCHEDULED' AS SchdRef,  
   NULL AS Due_dts   
   FROM ZSoCust2   
   WHERE Need_NewLine = 1  
 )  
 INSERT @ZSoBackLogPrepFC  
 SELECT * FROM ZSoBkJoin  
  
 -- 01/22/18 VL added MrpOnHold  
 INSERT @ZSoBackLogFC  
 SELECT ZS.Custno,Custname, Zs.Sono, Zs.OrderDate, Zs.Pono, Zs.Uniqueln, Line_no, Zs.ShippedQty,  
  CASE WHEN Part_no IS NULL THEN Sodet_Desc ELSE CAST(INVENTOR.part_no AS CHAR(45)) END AS PART_NO,  
  CASE WHEN REVISION IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.REVISION END AS REVISION,  
  CASE WHEN Part_Class IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.Part_Class END AS Part_Class,  
  CASE WHEN Part_Type IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.Part_Type END AS Part_Type,  
  CASE WHEN Descript IS NULL THEN Sodet_Desc ELSE CAST(INVENTOR.Descript AS CHAR(45)) END AS DESCRIPTIO,  
  Zs.Ship_dts, Zs.Due_dts, Zs.Commit_dts, OrdQty AS Due_dtsQty, BackQty AS Due_dtsBal, SoOrdQty AS Ord_qty,  
  SOBackQty AS Balance, 0 AS OrdAmt, 0 AS BackAmt, Zs.Is_rma, ZS.SchdRef,Zs.Hold,zs.Uniq_key,0 AS OrdAmtFC, 0 AS BackAmtFC,
   ZS.Currency,ZS.MrpOnHold  
  FROM CUSTOMER, @ZSoBackLogPrepFC ZS LEFT OUTER JOIN INVENTOR  
  ON ZS.Uniq_key = INVENTOR.UNIQ_KEY  
  WHERE Customer.Custno = ZS.Custno   
  AND Customer.Status = 'Active'  
  ORDER BY Custno, Zs.SONO, Zs.Uniqueln, NoSchedule DESC  
   
 SET @lnTotalNo = @@ROWCOUNT;  
 SET @lnCount=0;  
 SET @lnSoAddQty = 0; -- Need to reset when uniqueln changed  
 SET @lnSoBkQty = 0   
 SET @lnSoPTotalCnt = 0  
 IF (@lnTotalNo>0)  
 BEGIN   
  SELECT @lcOldUniqueln = Uniqueln FROM @ZSoBackLogFC WHERE nRecno = 1 -- Get the uniqueln from first record  
   
  WHILE @lnTotalNo>@lnCount  
  BEGIN  
   SET @lnCount=@lnCount+1;  
   SELECT @lSoUniqueln = Uniqueln, @lnOrdQty = Due_dtsQty, @lnBackQty = Due_dtsBal, @ShippedQty = ShippedQty  
    FROM @ZSoBackLogFC  
    WHERE nrecno = @lnCount  
    
   IF @@ROWCOUNT <> 0 -- Get one @ZSoBackLogFC record  
   BEGIN  
    
    IF @lcOldUniqueln <> @lSoUniqueln  
    BEGIN  
     SET @lnSoAddQty = 0; -- Need to reset when uniqueln changed  
     SET @lnSoBkQty = 0   
    END   
      
    SET @lnOrdAmt = 0  
    SET @lnBackAmt = 0    
    SET @lnOrdAmtFC = 0  
    SET @lnBackAmtFC = 0    
    -- Prepare Soprices for selected uniqueln record  
    DELETE FROM @ZSoPricesFC WHERE 1=1 -- Delete all old records  
  
    INSERT @ZSoPricesFC   
    SELECT Price, Quantity, Flat, Plpricelnk, PriceFC   
     FROM Soprices  
     WHERE UNIQUELN = @lSoUniqueln  
      
    SET @lnSoPcnt = @@ROWCOUNT  
    SET @lnSoPAllCnt = @lnSoPcnt + @lnSoPTotalCnt  
    BEGIN  
    IF @lnSoPcnt > 0  
     
     WHILE @lnSoPAllCnt > @lnSoPTotalCnt  
     BEGIN  
      SET @lnSoPTotalCnt = @lnSoPTotalCnt + 1;  
      SELECT @Price = Price, @Quantity = Quantity, @Flat = Flat, @lcPlpricelnk = Plpricelnk, @PriceFC = PriceFC       
       FROM @ZSoPricesFC WHERE nrecno = @lnSoPTotalCnt  
        
      --- Update OrdAmt  
      ----------------------------------------------------------------------------------------  
      ----- OrdAmt  
      IF (@Quantity >= 0 AND @Quantity - @lnSoAddQty >= @lnOrdQty) OR (@Quantity < 0 AND ABS(@Quantity - @lnSoAddQty) >= ABS(@lnOrdQty))  -- Never been added before  
       BEGIN  
       IF @Flat = 1  
        BEGIN     
        -- OrdAmt  
        IF @lnSoAddQty = 0  
         BEGIN  
         SET @lnOrdAmt = @lnOrdAmt + @Price  
         SET @lnOrdAmtFC = @lnOrdAmtFC + @PriceFC  
         END  
        END  
       ELSE  
        BEGIN  
         SET @lnOrdAmt = @lnOrdAmt + @lnOrdQty * @Price  
         SET @lnOrdAmtFC = @lnOrdAmtFC + @lnOrdQty * @PriceFC  
        END  
       END  
  
       
      IF (@Quantity >= 0 AND @Quantity - @lnSoAddQty < @lnOrdQty AND @Quantity - @lnSoAddQty > 0) OR   
       (@Quantity < 0 AND ABS(@Quantity - @lnSoAddQty) < ABS(@lnOrdQty) AND ABS(@Quantity - @lnSoAddQty) > 0)  
       BEGIN  
       IF @Flat = 1  
        BEGIN  
        -- OrdAmt  
        IF @lnSoAddQty = 0  
         BEGIN  
         SET @lnOrdAmt = @lnOrdAmt + @Price  
         SET @lnOrdAmtFC = @lnOrdAmtFC + @PriceFC  
         END  
        END  
       ELSE  
        BEGIN  
         SET @lnOrdAmt = @lnOrdAmt + (@Quantity - @lnSoAddQty) *  @Price  
         SET @lnOrdAmtFC = @lnOrdAmtFC + (@Quantity - @lnSoAddQty) *  @PriceFC  
        END  
       END        
         
        
       
       
      --- Update BackAmt  
      ----------------------------------------------------------------------------------------  
      ----- BackAmt     
       
      IF (@Quantity >=0 AND @Quantity - @lnSoBkQty >= @lnBackQty) OR  
       (@Quantity < 0 AND ABS(@Quantity - @lnSoBkQty) >= ABS(@lnBackQty)) -- Never been added before  
       BEGIN  
       IF @Flat = 1  
        BEGIN  
         SELECT @lcChkPlPricelnk = Plpricelnk FROM PLPRICES WHERE Plpricelnk = @lcPlpricelnk  
         IF @@ROWCOUNT <> 0 AND  @lnSoBkQty = 0 AND @ShippedQty =0  
          BEGIN  
          SET @lnBackAmt =  @lnBackAmt + @Price  
          SET @lnBackAmtFC =  @lnBackAmtFC + @PriceFC  
          END  
        END  
       ELSE  
        BEGIN  
        IF @Quantity >= 0  
         BEGIN  
         IF @Quantity - @ShippedQty - @lnSoBkQty >= @lnBackQty  
          BEGIN  
          SET @lnBackAmt = @lnBackAmt + @lnBackQty * @Price  
          SET @lnBackAmtFC = @lnBackAmtFC + @lnBackQty * @PriceFC  
          END  
         ELSE   
          IF @Quantity - @ShippedQty - @lnBackQty > 0   
           BEGIN   
           SET @lnBackAmt = @lnBackAmt + (@Quantity-@ShippedQty-@lnSoBkQty)*@Price  
           SET @lnBackAmtFC = @lnBackAmtFC + (@Quantity-@ShippedQty-@lnSoBkQty)*@PriceFC  
           END  
          ELSE  
           BEGIN  
           SET @lnBackAmt = @lnBackAmt + 0  
           SET @lnBackAmtFC = @lnBackAmtFC + 0  
           END  
         END  
        ELSE  
         BEGIN  
         IF ABS(@Quantity - @ShippedQty - @lnSoBkQty) >= ABS(@lnBackQty)  
          BEGIN  
          SET @lnBackAmt = @lnBackAmt + @lnBackQty * @Price  
          SET @lnBackAmtFC = @lnBackAmtFC + @lnBackQty * @PriceFC  
          END  
         ELSE  
          BEGIN  
          SET @lnBackAmt = @lnBackAmt + 0  
          SET @lnBackAmtFC = @lnBackAmtFC + 0  
          END  
         END  
        END   
       END  
  
     
      IF ABS(@Quantity - @lnSoBkQty) < ABS(@lnBackQty) AND ABS(@Quantity - @lnSoBkQty) > 0   
       BEGIN  
       IF @Flat = 1 AND @lnTotalBackQty = 0 AND @ShippedQty = 0  
        BEGIN  
         SELECT @lcChkPlPricelnk = Plpricelnk FROM PLPRICES WHERE Plpricelnk = @lcPlpricelnk  
         IF @@ROWCOUNT <> 0 AND  @lnSoBkQty = 0 AND @ShippedQty =0  
          BEGIN  
          SET @lnBackAmt =  @lnBackAmt + @Price  
          SET @lnBackAmtFC =  @lnBackAmtFC + @PriceFC  
          END  
        END  
       ELSE  
        BEGIN  
         IF @Quantity >= 0  
          BEGIN  
          IF @Quantity - @ShippedQty - @lnSoBkQty >= 0  
           BEGIN  
           SET @lnBackAmt = @lnBackAmt + (@Quantity-@ShippedQty-@lnSoBkQty)*@Price  
           SET @lnBackAmtFC = @lnBackAmtFC + (@Quantity-@ShippedQty-@lnSoBkQty)*@PriceFC  
           END  
          ELSE  
           BEGIN  
           SET @lnBackAmt = @lnBackAmt + 0  
           SET @lnBackAmtFC = @lnBackAmtFC + 0  
           END  
          END  
         ELSE  
          BEGIN  
          IF ABS(@Quantity - @ShippedQty - @lnSoBkQty) >= 0  
           BEGIN  
           SET @lnBackAmt = @lnBackAmt + (@Quantity-@ShippedQty-@lnSoBkQty)*@Price  
           SET @lnBackAmtFC = @lnBackAmtFC + (@Quantity-@ShippedQty-@lnSoBkQty)*@PriceFC  
           END  
          ELSE  
           BEGIN  
           SET @lnBackAmt = @lnBackAmt + 0  
           SET @lnBackAmtFC = @lnBackAmtFC + 0  
           END  
          END  
        END  
       END  
   
       
     END  
    END  
     
    SET @lnSoAddQty = @lnSoAddQty + @lnOrdQty  
    SET @lnSoBkQty = @lnSoBkQty + @lnBackQty  
    SET @lcOldUniqueln = @lSoUniqueln  
    UPDATE @ZSoBackLogFC SET OrdAmt = @lnOrdAmt, BackAmt = @lnBackAmt, OrdAmtFC = @lnOrdAmtFC, BackAmtFC = @lnBackAmtFC 
	WHERE nrecno = @lnCount   
   END  
  END       
 END        
  
 if (@lcRptType = 'Summary' and @lcSort = 'Product') --04/18/17 DRP:  added @lcSort = 'Product'  
  Begin  
   -- 01/22/18 VL added MrpOnHold  
   select Z1.Custno,Z1.custname, Z1.sono, Z1.pono, Z1.uniqueln, Z1.line_no, Z1.part_no, Z1.revision, Z1.part_class, Z1.part_type,
    Z1.descriptio, sum(z1.Ord_qty) as Ord_qty  
     ,sum(z1.Due_dtsQty) as Due_dtsQty,sum(z1.Due_dtsBal) as Due_dtsBal,sum(z1.OrdAmt) as OrdAmt,
	 sum(z1.backAmt) As BackAmt,z1.uniq_key,z1.Hold,
	 case when z1.Is_rma = 1 then 'RMA' else '' end as Is_Rma --09/17/15 DRP:  Added sum(z1.Due_dtsQty) as Due_dtsQty,z1.Hold and z1.Is_Rma  
     ,sum(z1.OrdAmtFC) as OrdAmtFC,sum(z1.backAmtFC) As BackAmtFC, Z1.MrpOnHold  
   from (select t1.custno,t1.custname, t1.sono, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,  
       CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	        Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
       CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	        Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
       t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
       --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty, --06/24/2015 DRP:  Replaced by below  
       --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal, --06/24/2015 DRP:  Replaced by below  
       Due_dtsQty,Due_dtsBal,  
       t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key,t1.ordAmtFC, t1.BackAmtFC, t1.Currency, t1.MrpOnHold  
       from (SELECT TOP (100) PERCENT * FROM @ZSoBackLogFC order by CUSTNAME, SONO) t1
	         where 1 = case when @lcSupZero = 'No' then 1
			                when @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) then 1 else 0 end  
       ) Z1  
   Group by Z1.Currency,Z1.Custno,Z1.custname, Z1.sono, Z1.pono, Z1.uniqueln, Z1.line_no, Z1.part_no, Z1.revision, Z1.part_class, Z1.part_type, Z1.descriptio,z1.uniq_key,z1.Hold,z1.Is_rma, z1.MrpOnHold  
  End  
  
 else if  (@lcRptType = 'Summary' and @lcSort = 'Month') --04/18/17 DRP:  added the Summary/Month section  
  Begin  
   -- 01/22/18 VL added MrpOnHold  
   select z1.MonthHd,Z1.Custno,Z1.custname, Z1.sono, Z1.pono, Z1.uniqueln, Z1.line_no, Z1.part_no, Z1.revision, Z1.part_class, Z1.part_type, Z1.descriptio, sum(z1.Ord_qty) as Ord_qty  
     ,sum(z1.Due_dtsQty) as Due_dtsQty,sum(z1.Due_dtsBal) as Due_dtsBal,sum(z1.OrdAmt) as OrdAmt,
	 sum(z1.backAmt) As BackAmt,z1.uniq_key,z1.Hold,
	 case when z1.Is_rma = 1 then 'RMA' else '' end as Is_Rma --09/17/15 DRP:  Added sum(z1.Due_dtsQty) as Due_dtsQty,z1.Hold and z1.Is_Rma  
     ,sum(z1.OrdAmtFC) as OrdAmtFC,sum(z1.backAmtFC) As BackAmtFC  
     ,z1.ShipYr,z1.ShipMnth --04/24/17 DRP:  Added to make sure that the sort order is correct   
     ,z1.MrpOnHold  
   from (select isnull(DATENAME(mm, t1.Ship_dts)+' '+DATENAME(yyyy, t1.Ship_dts),'Not Scheduled') AS MonthHd,t1.custno,t1.custname, t1.sono, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,  
       CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	        Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
       CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1
	       Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
       t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
       --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty, --06/24/2015 DRP:  Replaced by below  
       --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal, --06/24/2015 DRP:  Replaced by below  
       Due_dtsQty,Due_dtsBal,  
       t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key,t1.ordAmtFC, t1.BackAmtFC, t1.Currency  
       ,isnull(DATENAME(yyyy, t1.Ship_dts),'') as ShipYr, isnull(DATEpart(mm, t1.Ship_dts),'') as ShipMnth --04/24/17 DRP:  Added to make sure that the sort order is correct  
       ,t1.MrpOnHold  
       from (SELECT TOP (100) PERCENT * FROM @ZSoBackLogFC order by CUSTNAME, SONO) t1 
	    where 1 = case when @lcSupZero = 'No' 
		               then 1 when @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) then 1 else 0 end  
       ) Z1  
   Group by z1.ShipYr,z1.ShipMnth,Z1.Custno,Z1.custname, Z1.sono, Z1.pono, Z1.uniqueln, Z1.line_no, Z1.part_no, Z1.revision, Z1.part_class, Z1.part_type, Z1.descriptio,z1.uniq_key,z1.Hold,z1.Is_rma,z1.MonthHd, z1.MrpOnHold  
  END  
  
 else if (@lcRptType = 'Detailed' and @lcSort = 'Product')  
  Begin  
   -- 01/22/18 VL added MrpOnHold  
   select t1.custno,t1.custname, t1.sono, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	      Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	      Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty,  06/24/2015 DRP:  Replaced by below  
     --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal,  06/24/2015 DRP:  Replaced by below  
     Due_dtsQty,Due_dtsBal,  
     t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key,t1.ordAmtFC, t1.BackAmtFC, t1.Currency, t1.MrpOnHold  
   from (SELECT TOP (100) PERCENT * FROM @ZSoBackLogFC order by CUSTNAME, SONO) t1 
        where 1 = case when @lcSupZero = 'No' then 1
		               when @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) then 1 else 0 end  
   order by Currency, Custname,part_no,revision,Ship_dts,sono,Line_no  
  
  End   
  
 else if (@lcRptType = 'Detailed' and @lcSort = 'Month')  
  Begin  
   -- 01/22/18 VL added MrpOnHold  
   select isnull(DATENAME(mm, t1.Ship_dts)+' '+DATENAME(yyyy, t1.Ship_dts),'Not Scheduled') AS MonthHd  ,t1.custno,t1.custname, t1.sono, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	      Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,  
     CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 
	     Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance,   
     t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,  
     --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsQty ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsQty, --04/02/2015 DRP:  replaced with the below  
     --CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no, ship_dts Order by orderdate)=1 Then Due_dtsBal ELSE CAST(0.00 as Numeric(20,2)) END AS Due_dtsBal, --04/02/2015 DRP:  replaced with the below  
     Due_dtsQty,Due_dtsBal,t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key,t1.ordAmtFC, t1.BackAmtFC, t1.MrpOnHold  
   FROM (SELECT TOP (100) PERCENT * FROM @ZSoBackLogFC ORDER BY CUSTNAME, SONO) t1 
    WHERE 1 = CASE WHEN @lcSupZero = 'No' THEN 1
	               WHEN @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) THEN 1 ELSE 0 END  
   ORDER BY Currency, Custname,ship_Dts,part_no,revision,sono,Line_no  
  
  END   
 END-- end of FC installed  
END-- IF FC installed or not  
  
END  
  