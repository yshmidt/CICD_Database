-- =============================================
-- Author:		Vicky Lu	
-- Create date: <07/28/17>
-- Description:	<Serial number import validation
-- =============================================
CREATE PROCEDURE [dbo].[chkImportSerialno ]
	-- Add the parameters for the stored procedure here
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lReturn bit = 1, @lcXxSnAssign char(1)
DECLARE @ZFailedTB TABLE (Wono char(10), Serialno char(30), FailedReason varchar(100), ShouldBe char(40), Butis char(40))
SET @lReturn = 1

-- initial check for serialization
----------------------
IF @lReturn = 1
BEGIN
	SELECT @lcXxSnAssign = XxSnAssign FROM Shopfset
	IF @lcXxSnAssign <> 'P' AND @lcXxSnAssign <> 'S'
		BEGIN
		INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) VALUES ('', '', 'System is not set up for serial numbers','','')
		SET @lReturn = 0
	END
END


-- Check if empty wono, serialno
--------------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
	SELECT Wono, Serialno, CASE WHEN Wono='' THEN 'EMPTY Work order number' ELSE 'EMPTY serial number' END AS FailedReason, '',''
		FROM ImportSerialNo
		WHERE Wono = ''
		OR Serialno = ''

	--IF @@ROWCOUNT > 0
	--	BEGIN
	--	SET @lReturn = 0
	--END
END

--update fields with leading zeros if needed
-- 11/25/15 VL added UPPER(), so program can find it
-- 07/28/17 VL moved to adding leading zero to calling program
--UPDATE ImportSerialNo SET Serialno = UPPER(dbo.PADL(LTRIM(RTRIM(serialno)),30,'0')), 
--					Wono = dbo.PADL(LTRiM(RTRIM(Wono)),10,'0')
UPDATE ImportSerialNo SET Balance = Woentry.BALANCE, 
							Uniq_key = Woentry.Uniq_key FROM WOENTRY WHERE ImportSerialNo.Wono = Woentry.Wono

--  initial check for duplicate serial numbers in import
------------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
	SELECT Wono, Serialno, 'Duplicate serial numbers' AS FailedReason, 'empty' AS ShouldBe, Serialno AS ButIs
		FROM ImportSerialNo
		GROUP BY Wono, Serialno
		HAVING COUNT(*) > 1

--	IF @@ROWCOUNT > 0
--		BEGIN
--		SET @lReturn = 0
--	END
END


--  initial check for wo existence   
----------------------------------
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
	SELECT DISTINCT Wono, '' AS Serialno, 'Invalid work order numbers' AS FailedReason, 'empty' AS ShouldBe, Wono AS ButIs
		FROM ImportSerialNo
		WHERE Wono NOT IN 
			(SELECT Wono 
				FROM WOENTRY)
		
--	IF @@ROWCOUNT > 0
--		BEGIN
--		SET @lReturn = 0
--	END
END


--  initial safety check for wo part number equals import part number
----------------------------------------------------------------	
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
		SELECT DISTINCT ImportSerialNo.Wono, '' AS Serialno, 'Import part number did not match work order part number' AS FailedReason, 
				LTRIM(RTRIM(Inventor.PART_NO))+CASE WHEN LTRIM(RTRIM(Inventor.Revision)) = '' THEN '' ELSE 'Rev: '+LTRIM(RTRIM(Inventor.Revision)) END AS ShouldBe,
				LTRIM(RTRIM(ImportSerialNo.PART_NO))+CASE WHEN LTRIM(RTRIM(ImportSerialNo.Revision)) = '' THEN '' ELSE 'Rev: '+LTRIM(RTRIM(ImportSerialNo.Revision)) END AS ButIs
			FROM ImportSerialNo, INVENTOR
			WHERE ImportSerialNo.UNIQ_KEY = Inventor.UNIQ_KEY
			AND (ImportSerialNo.Part_no <> Inventor.PART_NO 
			OR ImportSerialNo.Revision <> Inventor.Revision)
--	IF @@ROWCOUNT > 0
--		BEGIN
--		SET @lReturn = 0
--	END
END	
		
--  check balance against # of serial numbers
---------------------------------------------
IF @lReturn = 1
BEGIN
	;WITH ZChkSN AS
	(
	SELECT Wono, Balance, COUNT(*) AS N
		FROM ImportSerialNo
		GROUP BY Wono, Balance
		HAVING Balance <> COUNT(*)
	)
	INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
		SELECT ZChkSN.Wono, '' AS Serialno, 'Serial number count does not match WO balance' AS FailedReason, STR(Balance,7,0) AS ShouldBe, STR(N) AS ButIs
			FROM ZChkSN
--	IF @@ROWCOUNT > 0
--		BEGIN
--		SET @lReturn = 0
--	END
END	


-- check for balance in front of serial number work center
--------------------------------------------------------------
IF @lReturn = 1
BEGIN
	;WITH ZWCStartNo AS
	(
	-- 07/27/17 VL added DISTINCT, so one work order only has one record
	SELECT DISTINCT ImportSerialNo.Wono, ISNULL(Number,1) AS StartNo
		FROM ImportSerialNo LEFT OUTER JOIN Dept_qty 
		ON ImportSerialNo.Wono = Dept_qty.Wono
		AND SerialStrt = 1
	),
	ZDept_qtySum AS 
	(
	SELECT Dept_qty.Wono, SUM(Dept_qty.Curr_qty) AS WOqty
		FROM Dept_qty, ZWCStartNo
		WHERE Dept_qty.Wono = ZWCStartNo.Wono
		AND Dept_qty.Number <= ZWCStartNo.StartNo
		GROUP BY Dept_qty.wono
	),
	ZChkSN AS
	(
	SELECT Wono, Balance, COUNT(*) AS N
		FROM ImportSerialNo
		GROUP BY Wono, Balance
		HAVING Balance <> COUNT(*)
	)
	INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
		SELECT ZDept_qtySum.Wono, '' AS Serialno, 'Serial number count does not match Quantities of Assys in and before SN starting WC' AS FailedReason, 
			STR(ZDept_qtySum.WoQty,7,0) AS ShouldBe, STR(ZChkSN.N) AS ButIs
			FROM ZDept_qtySum, ZChkSN
			WHERE ZDept_qtySum.WoQty > ZChkSN.N
--	IF @@ROWCOUNT > 0
--		BEGIN
--		SET @lReturn = 0
--	END
END		


-- check that if some serial numbers in invtser, there is enough room for additional serial numbers
-----------------------------------------------------------------------------------------------------
IF @lReturn = 1
BEGIN
	;WITH ZInvtSerCnt AS
	(
	SELECT Wono, COUNT(*) AS Invtqty
		FROM Invtser
		WHERE Wono IN 
			(SELECT Wono FROM ImportSerialNo)
		GROUP BY Wono
		HAVING COUNT(*) > 0
	),
	ZChkSN AS
	(
	SELECT Wono, Balance, COUNT(*) AS N
		FROM ImportSerialNo
		GROUP BY Wono, Balance
		-- 04/15/14 VL comment out next line
		--HAVING Balance <> COUNT(*)
	)
	
	INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
		SELECT ZChkSN.Wono, '' AS Serialno, 'Serial numbers are more than open spaces in WO', LTRIM(RTRIM(STR(ZChkSN.Balance-ZInvtSerCnt.InvtQty))) AS ShouldBe,
		LTRIM(RTRIM(STR(ZChkSN.N))) AS Butis
		FROM ZInvtSerCnt, ZChkSN
		WHERE ZInvtSerCnt.Wono = ZChkSN.Wono
		AND ZChkSN.N > ZChkSN.Balance-ZInvtSerCnt.InvtQty
--	IF @@ROWCOUNT > 0
--		BEGIN
--		SET @lReturn = 0
--	END		
END

--  check for duplicate serial numbers
-----------------------------------------------------------------------------------------------------
--  need to check setup for  SN    Shopfset.XxSnAssign.  P- by product, S- always unique, N - no use
IF @lReturn = 1
BEGIN
	IF @lcXxSnAssign = 'P'
		BEGIN
		INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
			-- 07/28/17 VL changed the SQL, it took too long to run
			--SELECT Wono, Serialno, 'SN already exist' AS FailedReason, 'not exist' AS ShouldBe, Serialno AS Butis
			--	FROM @ZImport
			--	WHERE Uniq_key+Serialno IN (SELECT Uniq_key+Serialno FROM INVTSER)
			SELECT ImportSerialNo.Wono, ImportSerialNo.Serialno, 'SN already exist' AS FailedReason, 'not exist' AS ShouldBe, ImportSerialNo.Serialno AS Butis
				FROM ImportSerialNo INNER JOIN Invtser
				ON ImportSerialNo.Uniq_key = Invtser.Uniq_key
				AND ImportSerialNo.Serialno = Invtser.Serialno
		--IF @@ROWCOUNT > 0
		--	BEGIN
		--	SET @lReturn = 0
		--END				
	END
	IF @lcXxSnAssign = 'S'
		BEGIN
		INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
			SELECT Wono, Serialno, 'SN already exist' AS FailedReason, 'not exist' AS ShouldBe, Serialno AS Butis
				FROM ImportSerialNo
				WHERE Serialno IN (SELECT Serialno FROM INVTSER)
		--IF @@ROWCOUNT > 0
		--	BEGIN
		--	SET @lReturn = 0
		--END					
	END
END			

-- 04/14/14 VL added to disallow REWORK work order
IF @lReturn = 1
BEGIN
	INSERT INTO @ZFailedTB (Wono, Serialno, FailedReason, ShouldBe, Butis) 	
		SELECT DISTINCT ImportSerialNo.Wono, '' AS Serialno, 'Can not import SN for Rework work order that is created from RMA receiver.','',''
			FROM ImportSerialNo INNER JOIN Woentry
			ON ImportSerialNo.Wono = Woentry.WONO 
			INNER JOIN SOMAIN
			ON Woentry.SONO = Somain.SONO 
			AND Somain.Is_rma = 1
		
END

SELECT * FROM @ZFailedTB
END