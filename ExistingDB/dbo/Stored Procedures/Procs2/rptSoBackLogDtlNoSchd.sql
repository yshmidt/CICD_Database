-- =============================================
-- Author:		Vicky and Debbie 
-- Create date:	11/06/2015
-- Description:	compiles detailed sales order Backlog without schedule
-- Reports:		sobgndt2
-- Modified:	11/06/15 DRP:  copied this procedure from <rptSoBackLogDtlWM> and made modifications so that it would work with the Backlog Without Schedules. 
-- 11/14/15 DRP:  added Extended to a couple of the declared tables and the final results in order for it to work on the Web Reports
-- 04/19/17 DRP:  removed the @customerStatus param.
-- 07/16/18 VL changed custname from char(35) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptSoBackLogDtlNoSchd] 
--DECLARE
	@lcCustNo varchar(max) = 'All'
	,@lcSupZero as char(3) = 'No'	--Yes = Suppress zero Backlog Qty, No = don't suppress zero backlog qty.  When @lcRptType = Summary then this has to be 'No'
	--,@customerStatus varchar (20) = 'Active'	--04/19/17 DRP:  removed
	,@userId uniqueidentifier = null

AS
BEGIN

/*CUSTOMER LIST*/	--01/07/2015 ADDED	
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

DECLARE @ZSoBackLogPrep TABLE (Sono char(10), OrderDate smalldatetime, SoOrdqty numeric(9,2), Sobackqty numeric(9,2), 
	Shippedqty numeric(9,2), Custno char(10), Uniq_key char(10), Uniqueln char(10), Line_no char(7), Is_Rma bit, Pono char(20), 
	Sodet_Desc char(45),Hold char(10),Extended numeric(15,2), Due_dtsqty numeric(16,2) NULL, Due_dtsbal numeric(16,2) NULL, No_Duedts bit, Need_NewLine bit, 
	Ship_dts smalldatetime, Commit_dts smalldatetime, Ordqty numeric(17,2), BackQty numeric(17,2), NoSchedule bit, 
	SchdRef char(15), Due_dts smalldatetime	);

	-- 07/16/18 VL changed custname from char(35) to char(50)
DECLARE @ZSoBackLog TABLE (nrecno int identity, Custno char(10),Custname char(50), Sono char(10), OrderDate smalldatetime, Pono char(20), Uniqueln char(10), 
	Line_no char(7), ShippedQty numeric(9,2), Part_no char(45), Revision char(8), Part_class char(8), Part_type char(8), Descriptio char(45), 
	Ship_dts Smalldatetime, Due_dts SmallDateTime, COMMIT_DTS SmallDateTime, Due_dtsQty numeric(9,2), Due_dtsBal numeric(9,2), 
	Ord_qty numeric(9,2), balance numeric(9,2),	OrdAmt numeric(20,2), BackAmt numeric(20,2), Is_rma bit, SchdRef char(15),Hold char(10),uniq_key char(10)
	,Extended numeric(15,2)
	);

DECLARE @ZSoPrices TABLE (nrecno int identity, Price numeric(14,5), Quantity numeric(10,2), Flat bit, Plpricelnk char(10));

DECLARE @lnCount int, @lnTotalNo int, @Due_dtsBal numeric(9,2), @Balance numeric(9,2), @lnTotalBackQty numeric(9,2), @Quantity numeric(10,2),
		@Flat bit, @ShippedQty numeric(9,2), @lcOldUniqueln char(10), @lcCurrentUniqueln char(10), @Price numeric(14,5), @lcOldDuedt_Uniq char(10), 
		@lcCurrentDuedt_Uniq char(10), @lnOldDuedtBalance numeric(9,2), @lnSoAddQty numeric(9,2), @lnOrdQty numeric(9,2), @lnOldDuedtOrdQty numeric(9,2),
		@lnSoBkQty numeric(9,2), @lnOrdAmt numeric(20,2), @lnBackAmt numeric(20,2), @lnSoPAllCnt int, @lnSoPTotalCnt int, @lnSoPcnt int, 
		@lSoUniqueln char(10), @lnBackQty numeric(9,2), @lcPlpricelnk char(10), @lcChkPlPricelnk char(10);


WITH ZSoCust AS 
(
	SELECT Sodetail.Sono, OrderDate, Ord_qty AS SoOrdQty, Balance AS SOBackQty, ShippedQty, Custno, Uniq_key, Uniqueln, 
		Line_no, Is_Rma ,Pono, Sodet_Desc,Case when SODETAIL.STATUS = 'Admin Hold' then 'Admin Hold' else case when SODETAIL.STATUS = 'Mfgr Hold' then 'Mfgr Hold' else '' end end as Hold
		,sodetail.EXTENDED
		FROM Sodetail, Somain 
		WHERE Sodetail.Sono = Somain.Sono 
		AND (Somain.Ord_type <> 'Closed' 
		AND Somain.Ord_type <> 'Cancel')
		AND (Sodetail.Status <> 'Closed'
		AND Sodetail.Status <> 'Cancel') 
		AND Balance <> 0 
		and 1 = case when somain.CUSTNO in (select CUSTNO from @customer ) then 1 else 0 end	--01/07/2015 ADDED

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

ZSoBkJoin AS
(	SELECT ZSoCust2.*, Ship_dts, Commit_dts,
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


INSERT @ZSoBackLog
SELECT ZS.Custno,Custname, Zs.Sono, Zs.OrderDate, Zs.Pono, Zs.Uniqueln, Line_no, Zs.ShippedQty,
	CASE WHEN Part_no IS NULL THEN Sodet_Desc ELSE CAST(INVENTOR.part_no AS CHAR(45)) END AS PART_NO,
	CASE WHEN REVISION IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.REVISION END AS REVISION,
	CASE WHEN Part_Class IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.Part_Class END AS Part_Class,
	CASE WHEN Part_Type IS NULL THEN CAST(' ' AS CHAR(8)) ELSE INVENTOR.Part_Type END AS Part_Type,
	CASE WHEN Descript IS NULL THEN Sodet_Desc ELSE CAST(INVENTOR.Descript AS CHAR(45)) END AS DESCRIPTIO,
	Zs.Ship_dts, Zs.Due_dts, Zs.Commit_dts, OrdQty AS Due_dtsQty, BackQty AS Due_dtsBal, SoOrdQty AS Ord_qty,
	SOBackQty AS Balance, 0 AS OrdAmt, 0 AS BackAmt, Zs.Is_rma
	,case when zs.ship_dts is null then 'NOT SCHEDULED' ELSE  ZS.SchdRef END	--11/06/15 DRP: added this case when
	,Zs.Hold,zs.Uniq_key
	,zs.extended
	FROM CUSTOMER, @ZSoBackLogPrep ZS LEFT OUTER JOIN INVENTOR
	ON ZS.Uniq_key = INVENTOR.UNIQ_KEY
	WHERE Customer.Custno = ZS.Custno 
	AND Customer.Status = 'Active'
	ORDER BY Custno, Zs.SONO, Zs.Uniqueln, NoSchedule DESC
	
SET @lnTotalNo = @@ROWCOUNT;
SET @lnCount=0;
SET @lnSoAddQty = 0;	-- Need to reset when uniqueln changed
SET @lnSoBkQty = 0	
SET @lnSoPTotalCnt = 0
IF (@lnTotalNo>0)
BEGIN	
	SELECT @lcOldUniqueln = Uniqueln FROM @ZSoBackLog WHERE nRecno = 1	-- Get the uniqueln from first record
	
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
				SET @lnSoAddQty = 0;	-- Need to reset when uniqueln changed
				SET @lnSoBkQty = 0	
			END	
				
			SET @lnOrdAmt = 0
			SET @lnBackAmt = 0		
			
			-- Prepare Soprices for selected uniqueln record
			DELETE FROM @ZSoPrices WHERE 1=1	-- Delete all old records

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
					IF (@Quantity >= 0 AND @Quantity - @lnSoAddQty >= @lnOrdQty) OR (@Quantity < 0 AND ABS(@Quantity - @lnSoAddQty) >= ABS(@lnOrdQty))	 -- Never been added before
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
						(@Quantity < 0 AND ABS(@Quantity - @lnSoBkQty) >= ABS(@lnBackQty))	-- Never been added before
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


select	t1.custno,t1.custname, t1.sono, t1.pono, t1.uniqueln, t1.line_no, t1.part_no, t1.revision, t1.part_class, t1.part_type, t1.descriptio,
				CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 Then ord_qty ELSE CAST(0.00 as Numeric(20,2)) END AS Ord_qty,
				CASE WHEN ROW_NUMBER() OVER(Partition by custno,sono, line_no Order by orderdate)=1 Then balance ELSE CAST(0.00 as Numeric(20,2)) END AS balance, 
				t1.Ship_dts, t1.Due_dts, t1.COMMIT_DTS,Due_dtsQty,Due_dtsBal,
				t1.ordAmt, t1.BackAmt, t1.is_rma, t1.SchdRef,t1.Hold,t1.uniq_key,t1.Extended
		from	(SELECT TOP (100) PERCENT * FROM @ZSoBackLog order by CUSTNAME, SONO) t1	
		where	 1 = case when @lcSupZero = 'No' then 1 when @lcSupZero = 'Yes' and (t1.balance <> 0.00 and t1.due_dtsBal<> 0.00) then 1 else 0 end
				and t1.schdref = 'NOT SCHEDULED'	
		order by Custname,part_no,revision,Ship_dts,sono,Line_no


END
		