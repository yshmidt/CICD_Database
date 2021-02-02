-- =============================================
-- Author:		Vicky Lu
-- Create date: 2011/08/25
-- Description:	Update ECO SO
-- Modification:
-- 04/25/16	VL	Slinkadd is moved from somain to sodetail, need to change the code of tax, also need to add FC fields
-- 11/23/16 VL	didn't consider that user might not check secondary product tax but check sttx tax, so add code to cosinder the situation
-- 11/29/16 VL	changed the finding next line number code to prevent getting error if the line_no has character in it.  Inovar got error that they had '00003e' line_no
--				also should check max number for this sono, not this uniqueln
-- 01/17/17 VL	added functional currency fields
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
-- =============================================

CREATE PROCEDURE [dbo].[sp_UpdEcoSo] @gUniqEcNo AS char(10) = ' ', @lcNewUniq_key char(10) = ' ', @lcUserId char(8) = ' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- This procedure will update SO from it's original product number to use new product number.  The rules are:
-- 1. if not shipped yet, replace sodetail.uniq_key to new uniq_key
-- 2. if already shipped, make the line closed by changing ord_qty to shipped qty, then create a new line with that balance, ;
--    for new product number.
--    a. need to check due_dts and all related tables
-- 3. deattach all WOs to the sodetail line.

-- 03/08/13 VL changed to not update w_key for new inserted sodetail record, the sodetail.w_key only need to be updated for BUY part

-- 04/25/16 VL added @Total_tax, @Total_TaxFC, @TotalPTax, @TotalPTaxFC, @TotalSTax, @TotalSTaxFC and @nCnt, @nCnt2, @SopExtended, @SopExtendedFC, @SopPlpricelnk, @SopForeigntax
--	@lnSoOldExtended numeric(16,2), @lnSoNewExtended numeric(16,2), @lnSomainExtended numeric(17,2), @lnSomainSoAmtDsct numeric(17,2),@lnSoNeedTaxAmt numeric(17,2)
--  @lnTotal_tax numeric (17,2), @lnTotalPTax numeric(17,2), @lnTotalSTax numeric(17,2)
-- 09/26/19 YS modified part number/customer part number char(25) to char(35)
DECLARE @lnTotalNo int, @lnCount int, @lcEcoSono char(10),
		@lcEcSoUniqueln char(10), @lnSoShippedQty numeric(9,2), @llEcoChgProdNo bit, @llEcoChgRev bit,
		@llEcoChgDescr bit, @lcOldPart_no varchar(35), @lcOldRevision varchar(8), @lcOldDescript varchar(45), 
		@lcNewPart_no varchar(35), @lcNewRevision varchar(8), @lcNewDescript varchar(45), @lcSoLine_no char(7),
		@llEcoCopyOthPrc bit, @llEcoUpdSoPrice bit, @lnSoOldExtended numeric(16,2), @lnSoNewExtended numeric(16,2),
		@lnDiscount numeric(5,2), @lnSomainExtended numeric(17,2), @lnSomainSoAmtDsct numeric(17,2),
		@lnTableVarCnt int, @lnSoNeedTaxAmt numeric(17,2), @llForeignTax bit, @llSttx bit, @llPtProd bit,
		@lnTotal_tax numeric (17,2), @lnTotalPTax numeric(17,2), @lnTotalSTax numeric(17,2), @lnSTaxRate numeric(8,4),
		@lcSoCustno char(10), @lcSoSLinkAdd char(10), @ltSOChangeHd varchar(max), @ltSOChangeDt varchar(max),
		@lnSoOrd_qty numeric(9,2), @lnSoBalance numeric(9,2), @lcNewSoUniqueln char(10), @lcSoNewLine_no char(7),
		@lcSoW_key char(10), @Total_tax numeric(17,2), @Total_TaxFC numeric(17,2), @TotalPTax numeric(17,2), @TotalPTaxFC numeric(17,2),
		@TotalSTax numeric(17,2), @TotalSTaxFC numeric(17,2), @nCnt int, @nCnt2 int, @SopExtended numeric(16,2), @SopExtendedFC numeric(16,2), 
		@SopPlpricelnk char(10), @SopForeigntax bit, @lnSoOldExtendedFC numeric(16,2), @lnSoNewExtendedFC numeric(16,2), @lnSomainExtendedFC numeric(17,2), 
		@lnSomainSoAmtDsctFC numeric(17,2), @lnSoNeedTaxAmtFC numeric(17,2),
		@lnTotal_taxFC numeric (17,2), @lnTotalPTaxFC numeric(17,2), @lnTotalSTaxFC numeric(17,2),
		-- 01/17/17 VL added functional currency fields
		@lnSoOldExtendedPR numeric(16,2), @lnSoNewExtendedPR numeric(16,2), @lnSomainExtendedPR numeric(17,2), @lnSomainSoAmtDsctPR numeric(17,2), @lnSoNeedTaxAmtPR numeric(17,2), 
		@lnTotal_taxPR numeric (17,2), @lnTotalPTaxPR numeric(17,2), @lnTotalSTaxPR numeric(17,2),@Total_taxPR numeric(17,2),@TotalPTaxPR numeric(17,2), 
		@TotalSTaxPR numeric(17,2),	@SopExtendedPR numeric(16,2)
		
-- 04/25/16 VL create a temp table to calculate tax
-- 01/17/17 VL added functional currency fields
DECLARE @ZSoprices TABLE (Extended numeric(20,2), ExtendedFC numeric(20,2), Plpricelnk char(10), ForeignTax bit, nRecno int, ExtendedPR numeric(20,2));
SET @ltSOChangeHd = ''
SET @ltSOChangeDt = ''

SET @lnSoNeedTaxAmt = 0
SET @llSttx = 0
SET @llPtProd = 0
-- 10/17/11 VL set followingi varable default = 0
SET @lnTotal_tax = 0
SET @lnSomainExtended = 0
SET @lnSomainSoAmtDsct = 0
SET @lnTotal_tax = 0
SET @lnTotalPTax = 0
SET @lnTotalSTax = 0
-- 04/25/16 VL set default value to 0
SET @lnTotal_taxFC = 0
SET @lnSomainExtendedFC = 0
SET @lnSomainSoAmtDsctFC = 0
SET @lnTotal_taxFC = 0
SET @lnTotalPTaxFC = 0
SET @lnTotalSTaxFC = 0
-- 01/17/17 VL added functional currency fields
SET @lnSoNeedTaxAmtFC = 0
SET @lnSoNeedTaxAmtPR = 0
SET @lnTotal_taxPR = 0
SET @lnSomainExtendedPR = 0
SET @lnSomainSoAmtDsctPR = 0
SET @lnTotal_taxPR = 0
SET @lnTotalPTaxPR = 0
SET @lnTotalSTaxPR = 0
				
SELECT @llEcoChgProdNo = ChgProdNo, @llEcoChgRev = ChgRev, @llEcoChgDescr = ChgDescr, 
	@lcNewPart_no = LTRIM(RTRIM(NEWPRODNO)), @lcNewRevision = LTRIM(RTRIM(NEWREV)), @lcNewDescript = LTRIM(RTRIM(NewDescr)),
	@llEcoCopyOthPrc = CopyOthPrc, @llEcoUpdSoPrice = UpdSoPrice
	FROM ECMAIN WHERE UNIQECNO = @gUniqEcNo
	
SELECT @lcOldPart_no = LTRIM(RTRIM(Part_no)), @lcOldRevision = LTRIM(RTRIM(Revision)), @lcOldDescript = LTRIM(RTRIM(Descript))
	FROM INVENTOR 
	WHERE UNIQ_KEY = (SELECT UNIQ_KEY FROM Ecmain WHERE UNIQECNO = @gUniqEcNo)

DECLARE @ZEcSo TABLE (nrecno int identity, Sono char(10), Uniqueln char(10))
INSERT @ZEcSo SELECT Sono, Uniqueln FROM ECSO WHERE UNIQECNO = @gUniqEcNo AND CHANGE = 1

SET @lnTotalNo = @@ROWCOUNT;
IF (@lnTotalNo>0)
BEGIN
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @lcEcoSono = Sono, @lcEcSoUniqueln = Uniqueln
			FROM @ZEcSo WHERE nrecno = @lnCount	
		IF (@@ROWCOUNT<>0)
		BEGIN
			SET @ltSOChangeHd='Sales Order ' + @lcEcoSono + ' was changed from ECO module on Date/Time: ' 
						+CONVERT(nvarchar(30), GETDATE(), 121)+', By User: '+LTRIM(RTRIM(@lcUserId))
			SET @ltSOChangeDt = ''			
			-- Cut link to WO first
			UPDATE Woentry 
				SET Uniqueln = SPACE(10)
				WHERE Uniqueln = @lcEcSoUniqueln
			
			-- Get Sodetail data
			-- 04/25/16 VL added FC field
			-- 01/17/17 VL added functional currency fields
			SELECT @lnSoShippedQty = ShippedQty, @lcSoLine_no = Line_no, @lnSoOldExtended = Extended,
					@lnSoOrd_qty = ORD_QTY, @lnSoBalance = Balance, @lnSoOldExtendedFC = ExtendedFC,
					@lnSoOldExtendedPR = ExtendedPR
				FROM SODETAIL 
				WHERE UNIQUELN = @lcEcSoUniqueln
			
			-- @lnSoShipped Qty = 0 or not has different way to update
			IF @lnSoShippedQty = 0
				-- Just changed the line to use new product number
				BEGIN
				IF @llEcoChgProdNo = 1 ANd @llEcoChgRev = 1
					SET @ltSOChangeDt = CASE WHEN @ltSOChangeDt = '' THEN CHAR(9) ELSE @ltSOChangeDt + CHAR(13)+CHAR(9) END +
							'Part Number and revision was changed from ' + @lcOldPart_no + 
							CASE WHEN @lcOldRevision = '' THEN '' ELSE '/'+@lcOldRevision END + ' to ' + 
							@lcNewPart_no + CASE WHEN @lcNewRevision = '' THEN '' ELSE '/'+@lcNewRevision END
		
									
				IF @llEcoChgProdNo = 1 ANd @llEcoChgRev = 0
					SET @ltSOChangeDt = CASE WHEN @ltSOChangeDt = '' THEN CHAR(9) ELSE @ltSOChangeDt + CHAR(13)+CHAR(9) END +
							'Part Number was changed from ' + @lcOldPart_no + ' to ' + @lcNewPart_no 

				IF @llEcoChgProdNo = 0 ANd @llEcoChgRev = 1
					SET @ltSOChangeDt = CASE WHEN @ltSOChangeDt = '' THEN CHAR(9) ELSE @ltSOChangeDt + CHAR(13)+CHAR(9) END +
							'Part Revision was changed for the item number: ' + @lcSoLine_no + ', Part #: ' + 
							@lcOldPart_no + ' from ' + @lcOldRevision + ' to ' + @lcNewRevision

				IF @llEcoChgDescr = 1 AND @lcOldDescript <> @lcNewDescript
					SET @ltSOChangeDt = CASE WHEN @ltSOChangeDt = '' THEN CHAR(9) ELSE @ltSOChangeDt + CHAR(13)+CHAR(9) END +
							'Product Description was changed for the item number: ' + @lcSoLine_no + ', Part #: ' + 
							@lcOldPart_no + ' from ' + @lcOldDescript + ' to ' + @lcNewDescript
		
		
		
				-- Update Sodetail.Uniq_key
				UPDATE SODETAIL SET UNIQ_KEY = @lcNewUniq_key WHERE SODETAIL.UNIQUELN = @lcEcSoUniqueln
				
				IF @llEcoChgDescr = 1
					UPDATE Soprices SET Descriptio = @lcNewDescript WHERE Uniqueln = @lcEcSoUniqueln AND RecordType = 'P'
		
				IF @llEcoCopyOthPrc = 0
					DELETE FROM Soprices WHERE Uniqueln = @lcEcSoUniqueln AND RecordType <> 'P'

				IF @llEcoUpdSoPrice = 0
					-- 04/25/16 VL added FC field
					-- 01/17/17 VL added functional currency fields
					UPDATE Soprices SET Flat = 0, Price = 0.00, Extended = 0.00, Taxable = 0, PriceFC = 0.00, ExtendedFC = 0.00,
										PricePR = 0.00, ExtendedPR = 0.00 WHERE Uniqueln = @lcEcSoUniqueln

				-- Update Sodetail.Extended
				-- 04/25/16 VL added FC fields
				SET @lnSoNewExtended = ISNULL((SELECT SUM(Extended) FROM SOPRICES WHERE UNIQUELN = @lcEcSoUniqueln),0)
				UPDATE SODETAIL SET EXTENDED = @lnSoNewExtended WHERE Uniqueln = @lcEcSoUniqueln
				SET @lnSoNewExtendedFC = ISNULL((SELECT SUM(ExtendedFC) FROM SOPRICES WHERE UNIQUELN = @lcEcSoUniqueln),0)
				UPDATE SODETAIL SET EXTENDEDFC = @lnSoNewExtendedFC WHERE Uniqueln = @lcEcSoUniqueln
				-- 01/17/17 VL added functional currency fields
				SET @lnSoNewExtendedPR = ISNULL((SELECT SUM(ExtendedPR) FROM SOPRICES WHERE UNIQUELN = @lcEcSoUniqueln),0)
				UPDATE SODETAIL SET EXTENDEDPR = @lnSoNewExtendedPR WHERE Uniqueln = @lcEcSoUniqueln
				
				IF @lnSoNewExtended <> @lnSoOldExtended
					SET @ltSOChangeDt = CASE WHEN @ltSOChangeDt = '' THEN CHAR(9) ELSE @ltSOChangeDt + CHAR(13)+CHAR(9) END +
						'The Extended Price for the item number: ' + @lcSoLine_no + ', Part #: ' + 
						@lcOldPart_no + CASE WHEN @lcOldRevision = '' THEN '' ELSE '/'+@lcOldRevision END +
						'was changed from ' + LTRIM(RTRIM(CAST(@lnSoOldExtended AS char(20)))) + 
						' to ' + LTRIM(RTRIM(CAST(@lnSoNewExtended AS char(20))))
				END
			ELSE
				-- @lnSoShippedQty <> 0
				BEGIN
				IF @lnSoOrd_qty > @lnSoShippedQty
				BEGIN
					-- Close sodetail with balance
					UPDATE SODETAIL
						SET ORD_QTY = ShippedQty, BALANCE = 0, STATUS = 'Closed' WHERE Uniqueln = @lcEcSoUniqueln
					
					SET @ltSOChangeDt = CASE WHEN @ltSOChangeDt = '' THEN CHAR(9) ELSE @ltSOChangeDt+CHAR(13)+CHAR(9) END +
							'Order quantity for the item number: ' + @lcSoLine_no + ', Part #: ' + 
							+ @lcOldPart_no + CASE WHEN @lcOldRevision = '' THEN '' ELSE '/'+@lcOldRevision END + 
							'was changed from ' + LTRIM(RTRIM(STR(@lnSoOrd_qty,9,2))) + ' to ' + LTRIM(RTRIM(STR(@lnSoShippedQty,9,2)))
				
					-- Close due_dts and move to new line due_dts records
					-- Eg:original due_dts ====>		Old line					New line
					-- Dt	Act_shp_qt	Qty			Dt	Act_shp_qt	Qty			Dt	Act_shp_qt	Qty
					-- 1/1		3		0			1/1		3		0			
					-- 1/2		1		2			1/2		1		0			1/2		0		2
					-- 1/3		0		3										1/3		0		3
					-- 1/4		0		1										1/4		0		1
					
					-- Get new Sodetail.Uniqueln first
					SET @lcNewSoUniqueln = dbo.fn_GenerateUniqueNumber()
					
					--------------------------
					-- Update Due_dts table --
					--------------------------
					-- Prepare data for new line due_dts first
					INSERT Due_dts (Sono, Uniqueln, Due_dts, Ship_dts, Commit_dts, Qty, Act_shp_qt, Duedt_Uniq)
						SELECT Sono, @lcNewSoUniqueln AS Uniqueln, Due_dts, Ship_dts, Commit_dts, Qty, 0.00 AS Act_shp_qt, dbo.fn_GenerateUniqueNumber() AS Duedt_Uniq
							FROM DUE_DTS
							WHERE UNIQUELN = @lcEcSoUniqueln
							AND QTY > 0
					
					-- for old due_dts line: Delete Act_shp_qt = 0 records and make all qty = 0
					DELETE FROM DUE_DTS WHERE UNIQUELN = @lcEcSoUniqueln AND Act_shp_qt = 0
					UPDATE Due_dts SET Qty = 0 WHERE Uniqueln = @lcEcSoUniqueln

					
					---------------------------
					-- Update Soprices table --
					---------------------------
					-- Current Soprices, need to adjust qty to shipped qty
					-- 04/25/16 VL added FC field
					-- 01/17/17 VL added functional currency fields
					UPDATE Soprices SET Quantity = CASE WHEN Quantity >= @lnSoShippedQty THEN @lnSoShippedQty ELSE QUANTITY END,
										EXTENDED = CASE WHEN FLAT = 1 THEN PRICE ELSE (CASE WHEN Quantity >= @lnSoShippedQty THEN @lnSoShippedQty ELSE QUANTITY END)*PRICE END,
										EXTENDEDFC = CASE WHEN FLAT = 1 THEN PRICEFC ELSE (CASE WHEN Quantity >= @lnSoShippedQty THEN @lnSoShippedQty ELSE QUANTITY END)*PRICEFC END,
										EXTENDEDPR = CASE WHEN FLAT = 1 THEN PRICEPR ELSE (CASE WHEN Quantity >= @lnSoShippedQty THEN @lnSoShippedQty ELSE QUANTITY END)*PRICEPR END
						WHERE Uniqueln = @lcEcSoUniqueln										
					
					-- Update Sodetail.Extended
					-- 04/25/16 VL added FC field
					-- 01/17/17 VL added functional currency fields
					UPDATE SODETAIL SET EXTENDED = (SELECT SUM(Extended) FROM SOPRICES WHERE UNIQUELN = @lcEcSoUniqueln),
										EXTENDEDFC = (SELECT SUM(ExtendedFC) FROM SOPRICES WHERE UNIQUELN = @lcEcSoUniqueln),
										EXTENDEDPR = (SELECT SUM(ExtendedPR) FROM SOPRICES WHERE UNIQUELN = @lcEcSoUniqueln)
						WHERE UNIQUELN = @lcEcSoUniqueln
			
					-- 11/29/16 VL changed the finding next line number code to prevent getting error if the line_no has character in it.  Inovar got error that they had '00003e' line_no
					-- also should check max number for this sono, not this uniqueln
					--SET @lcSoNewLine_no = (SELECT dbo.PADL(STR(CAST(MAX(Line_no) AS numeric)+1),7,'0') FROM Sodetail WHERE UNIQUELN = @lcEcSoUniqueln)
					SET @lcSoNewLine_no = ISNULL((SELECT dbo.PADL(MAX(CAST(SUBSTRING(line_no, PATINDEX('%[0-9]%', line_no), PATINDEX('%[0-9][^0-9]%', line_no + 't') - PATINDEX('%[0-9]%', 
                    line_no) + 1) AS numeric)+1),7,'0') FROM Sodetail WHERE Sono=@lcEcoSono),dbo.PADL(STR(CAST(@lcSoNewLine_no AS numeric)+1),7,'0'))

					-- 03/08/13 VL found no need to update w_key, w_key only need to be updated for BUY part
					--SET @lcSoW_key = (SELECT W_key FROM INVTMFGR WHERE UNIQ_KEY = @lcNewUniq_key)
					
					-- 04/25/16 VL now Slinkadd, Fob, Shipvia, BillAcount, Deliv_Time, Attention, ShipCharge are moved from somain level to sodetail level, has to update here
					INSERT Sodetail (Sono, Uniqueln, Line_no, Uniq_key, Uofmeas, Eachqty, Ord_qty, ShippedQty, Balance, 
						Trans_days, Fstduedt, Delifreq, Category, Status, W_key, Prjunique, Prodtpuniq, Prodtpukln, 
						Cnfgqtyper, MRPOnHold, SourceInsp, Firstartcl, lFcstItem,
						Slinkadd, Fob, Shipvia, BillAcount, Deliv_Time, Attention, ShipCharge)
					SELECT @lcEcoSono AS Sono, @lcNewSoUniqueln AS Uniqueln, @lcSoNewLine_no AS Line_no, 
						@lcNewUniq_key AS Uniq_key, Uofmeas, Eachqty, @lnSoOrd_qty - @lnSoShippedQty AS Ord_qty, 0.00 AS ShippedQty, 
						@lnSoOrd_qty - @lnSoShippedQty AS Balance, Trans_days, Fstduedt, Delifreq, '000000000~' AS Category, 'Standard' AS Status, 
						'' AS W_key, Prjunique, Prodtpuniq, Prodtpukln, Cnfgqtyper, MRPOnHold, SourceInsp, Firstartcl, lFcstItem,
						Slinkadd, Fob, Shipvia, BillAcount, Deliv_Time, Attention, ShipCharge 
					FROM Sodetail
					WHERE Sodetail.Uniqueln = @lcEcSoUniqueln
					
					SET @ltSOChangeDt = CASE WHEN @ltSOChangeDt = '' THEN CHAR(9) ELSE @ltSOChangeDt+CHAR(13)+CHAR(9) END +
							'Item Number ' + @lcSoNewLine_no + ', Part #: ' + @lcNewPart_no + 
							CASE WHEN @lcNewRevision = '' THEN '' ELSE '/'+@lcNewRevision END + ' was added.'
					
					BEGIN
					IF @llEcoCopyOthPrc = 0	
						-- 04/25/16 VL added FC field, extendedfc and pricefc
						-- 01/17/17 VL added functional currency fields
						INSERT Soprices (Sono, Descriptio, Quantity, Recordtype, Plpricelnk, Uniqueln, Extended, SaleTypeID, Pl_gl_nbr, Cog_gl_nbr, Price, Taxable, Flat, ExtendedFC, PriceFC, ExtendedPR, PricePR) 
							SELECT @lcEcoSono AS Sono, @lcNewDescript AS Descriptio, @lnSoOrd_qty - @lnSoShippedQty AS Quantity, 'P', 
									dbo.fn_GenerateUniqueNumber() AS Plpricelnk, @lcNewSoUniqueln AS Uniqueln, 
									CASE WHEN @llEcoUpdSoPrice = 1 THEN
										CASE WHEN Flat = 0 THEN Price * (@lnSoOrd_qty - @lnSoShippedQty) ELSE Price END
										ELSE 0 END AS Extended,
									SaleTypeId, Pl_gl_nbr, Cog_gl_nbr, 
									CASE WHEN @llEcoUpdSoPrice = 1 THEN Price ELSE 0 END AS Price, 
									CASE WHEN @llEcoUpdSoPrice = 1 THEN Taxable ELSE 0 END AS Taxable, 
									CASE WHEN @llEcoUpdSoPrice = 1 THEN Flat ELSE 0 END AS Flat,
									CASE WHEN @llEcoUpdSoPrice = 1 THEN
										CASE WHEN Flat = 0 THEN PriceFC * (@lnSoOrd_qty - @lnSoShippedQty) ELSE PriceFC END
										ELSE 0 END AS ExtendedFC,
									CASE WHEN @llEcoUpdSoPrice = 1 THEN PriceFC ELSE 0 END AS PriceFC,
									CASE WHEN @llEcoUpdSoPrice = 1 THEN
										CASE WHEN Flat = 0 THEN PricePR * (@lnSoOrd_qty - @lnSoShippedQty) ELSE PricePR END
										ELSE 0 END AS ExtendedPR,
									CASE WHEN @llEcoUpdSoPrice = 1 THEN PricePR ELSE 0 END AS PricePR
								FROM SOPRICES
								WHERE UNIQUELN = @lcEcSoUniqueln
								AND RECORDTYPE = 'P'
					ELSE
						WITH ZPlShip AS 
						(
							SELECT Plpricelnk, SUM(quantity) AS PlShippedQty
								FROM Plprices
								WHERE Plprices.PlpriceLnk IN
									(SELECT PlpriceLnk
										FROM Soprices
										WHERE Uniqueln = @lcEcSoUniqueln)
								GROUP BY Plpricelnk
						)
						-- Not Flat part first
						-- 04/25/16 VL added FC field
						-- 01/17/17 VL added functional currency fields
						INSERT Soprices (Sono, Descriptio, Quantity, Recordtype, Plpricelnk, Uniqueln, Extended, SaleTypeID, 
									Pl_gl_nbr, Cog_gl_nbr, Price, Taxable, Flat, ExtendedFC, PriceFC, ExtendedPR, PricePR) 
							SELECT @lcEcoSono AS Sono, CASE WHEN RecordType = 'P' THEN @lcNewDescript ELSE Descriptio END AS Descriptio,
								CASE WHEN RecordType = 'P' THEN @lnSoOrd_qty - @lnSoShippedQty ELSE Soprices.Quantity - ZPlShip.PlShippedQty END AS Quantity,
								RecordType, dbo.fn_GenerateUniqueNumber() AS Plpricelnk, @lcNewSoUniqueln AS Uniqueln, 
								CASE WHEN @llEcoUpdSoPrice = 1 THEN Price * (
											CASE WHEN RecordType = 'P' 
												THEN @lnSoOrd_qty - @lnSoShippedQty ELSE
												CASE WHEN Quantity >= ZPlShip.PlShippedQty THEN Quantity - ZPlShip.PlShippedQty ELSE 0 END END)
									ELSE 0 END AS Extended, SaleTypeId, Pl_gl_nbr, Cog_gl_nbr, 
								CASE WHEN @llEcoUpdSoPrice = 1 THEN Price ELSE 0 END AS Price, 
								CASE WHEN @llEcoUpdSoPrice = 1 THEN Taxable ELSE 0 END AS Taxable, 
								CASE WHEN @llEcoUpdSoPrice = 1 THEN Flat ELSE 0 END AS Flat,
								CASE WHEN @llEcoUpdSoPrice = 1 THEN PriceFC * (
											CASE WHEN RecordType = 'P' 
												THEN @lnSoOrd_qty - @lnSoShippedQty ELSE
												CASE WHEN Quantity >= ZPlShip.PlShippedQty THEN Quantity - ZPlShip.PlShippedQty ELSE 0 END END)
									ELSE 0 END AS ExtendedFC,
								CASE WHEN @llEcoUpdSoPrice = 1 THEN PriceFC ELSE 0 END AS PriceFC,
								CASE WHEN @llEcoUpdSoPrice = 1 THEN PricePR * (
											CASE WHEN RecordType = 'P' 
												THEN @lnSoOrd_qty - @lnSoShippedQty ELSE
												CASE WHEN Quantity >= ZPlShip.PlShippedQty THEN Quantity - ZPlShip.PlShippedQty ELSE 0 END END)
									ELSE 0 END AS ExtendedPR,
								CASE WHEN @llEcoUpdSoPrice = 1 THEN PricePR ELSE 0 END AS PricePR
							FROM Soprices, ZPlShip
							WHERE Soprices.Plpricelnk = ZPlship.Plpricelnk
							AND Uniqueln = 	@lcEcSoUniqueln
							AND Soprices.FLAT = 0
							
						-- Flat part, if find in Plprices, then skip
						-- 04/25/16 VL added FC field
						-- 01/17/17 VL added functional currency fields
						INSERT Soprices (Sono, Descriptio, Quantity, Recordtype, Plpricelnk, Uniqueln, Extended, SaleTypeID, 
									Pl_gl_nbr, Cog_gl_nbr, Price, Taxable, Flat, ExtendedFC, PriceFC, ExtendedPR, PricePR) 
							SELECT @lcEcoSono AS Sono, CASE WHEN RecordType = 'P' THEN @lcNewDescript ELSE Descriptio END AS Descriptio,
								1 AS Quantity, RecordType, dbo.fn_GenerateUniqueNumber() AS Plpricelnk, @lcNewSoUniqueln AS Uniqueln, 
								CASE WHEN @llEcoUpdSoPrice = 1 THEN Price ELSE 0 END AS Extended, SaleTypeId, Pl_gl_nbr, Cog_gl_nbr, 
								CASE WHEN @llEcoUpdSoPrice = 1 THEN Price ELSE 0 END AS Price, 
								CASE WHEN @llEcoUpdSoPrice = 1 THEN Taxable ELSE 0 END AS Taxable, 
								CASE WHEN @llEcoUpdSoPrice = 1 THEN Flat ELSE 0 END AS Flat,
								CASE WHEN @llEcoUpdSoPrice = 1 THEN PriceFC ELSE 0 END AS ExtendedFC,
								CASE WHEN @llEcoUpdSoPrice = 1 THEN PriceFC ELSE 0 END AS PriceFC,
								CASE WHEN @llEcoUpdSoPrice = 1 THEN PricePR ELSE 0 END AS ExtendedPR,
								CASE WHEN @llEcoUpdSoPrice = 1 THEN PricePR ELSE 0 END AS PricePR
							FROM Soprices
							WHERE Uniqueln = @lcEcSoUniqueln
							AND Plpricelnk NOT IN 
								(SELECT Plpricelnk
									FROM Plprices
									WHERE Uniqueln = @lcEcSoUniqueln)
							AND FLAT = 1
					END
					
					-- {04/25/16 VL added code to insert into SopricesTax if taxable = 1
					INSERT SopricesTax(UniqSopricesTax, Sono, Uniqueln, Plpricelnk, Tax_id, Tax_Rate, Taxtype, PtProd, PtFrt, StProd, StFrt, Sttx)
						SELECT dbo.fn_GenerateUniqueNumber() AS UniqSopricesTax, @lcEcoSono AS Sono, @lcNewSoUniqueln AS Uniqueln, Soprices.Plpricelnk AS Plpricelnk,
								Tax_id, Tax_rate, Taxtype, PtProd, PtFrt, StProd, StFrt, Sttx 
							FROM Soprices, Sodetail, Shiptax 
							WHERE Soprices.Uniqueln = Sodetail.Uniqueln
							AND Soprices.Uniqueln = @lcNewSoUniqueln
							AND Sodetail.Slinkadd = Shiptax.linkadd 
							AND Soprices.TAXABLE = 1
							AND Shiptax.RecordType = 'S'
								AND ((TAXTYPE = 'P' AND PTPROD = 1) 
								-- 11/23/16 VL didn't consider that user might not check secondary product tax but check sttx tax, so add code to cosinder the situation
								--OR (TAXTYPE = 'E' AND STPROD = 1)
								OR (TAXTYPE = 'E' AND (STPROD = 1 OR Sttx = 1))
								OR (TAXTYPE = 'S'))
					-- 04/26/16 VL End}

					-- 04/25/16 VL added FC field
					-- 01/17/17 VL added functional currency fields
					UPDATE SODETAIL SET EXTENDED = (SELECT SUM(Extended) FROM SOPRICES WHERE UNIQUELN = @lcNewSoUniqueln),
										EXTENDEDFC = (SELECT SUM(ExtendedFC) FROM SOPRICES WHERE UNIQUELN = @lcNewSoUniqueln),
										EXTENDEDPR = (SELECT SUM(ExtendedPR) FROM SOPRICES WHERE UNIQUELN = @lcNewSoUniqueln)
						WHERE UNIQUELN = @lcNewSoUniqueln					

				END -- @lnSoOrd_qty > @lnSoBalance
			END -- @lnSoShippedQty = 0



			------------------------------------------
			-- Start to update Somain
			-- 04/25/16 VL comment out getting Slinkadd from somain, now it's moved to sodetail level: @lcSoSLinkAdd = SLinkadd
			SELECT @lcSoCustno = Custno FROM SOMAIN WHERE SONO = @lcEcoSono
			
			SELECT @lnSomainExtended = ISNULL((SELECT CASE WHEN SUM(Extended)>99999999999999.99 THEN 99999999999999.99 
				ELSE SUM(Extended) END FROM SODETAIL WHERE SONO = @lcEcoSono),0)
			-- 04/25/16 VL added FC
			SELECT @lnSomainExtendedFC = ISNULL((SELECT CASE WHEN SUM(ExtendedFC)>99999999999999.99 THEN 99999999999999.99 
				ELSE SUM(ExtendedFC) END FROM SODETAIL WHERE SONO = @lcEcoSono),0)

			-- 01/17/17 VL added functional currency fields
			SELECT @lnSomainExtendedPR = ISNULL((SELECT CASE WHEN SUM(ExtendedPR)>99999999999999.99 THEN 99999999999999.99 
				ELSE SUM(ExtendedPR) END FROM SODETAIL WHERE SONO = @lcEcoSono),0)

			SELECT @lnDiscount = ISNULL((SELECT DISCOUNT FROM SALEDSCT WHERE SALEDSCTID = 
				(SELECT SALEDSCTID FROM CUSTOMER WHERE CUSTNO = @lcSoCustno)),0)
				
			IF @@ROWCOUNT = 0
				SET @lnDiscount = 0

				
			SELECT @lnSomainSoAmtDsct = ROUND(@lnSomainExtended*@lnDiscount/100,2)
			-- 04/25/16 VL added FC
			SELECT @lnSomainSoAmtDsctFC = ROUND(@lnSomainExtendedFC*@lnDiscount/100,2)
			-- 01/17/17 VL added functional currency fields
			SELECT @lnSomainSoAmtDsctPR = ROUND(@lnSomainExtendedPR*@lnDiscount/100,2)

			-- 04/26/16 VL comment out the code, now each sodetail might have different slinkadd, will scan through soprices to calculate
			---- Get if using regular tax or foreign tax
			--SELECT @llForeignTax = ISNULL(ForeignTax,0)
			--	FROM Shipbill
			--	WHERE Custno = @lcSoCustno
			--	AND Linkadd = @lcSoSlinkadd
			
			--IF @llForeignTax = 0	
			---- Regular tax, just calculate TaxType = 'S'
			--	SELECT @lnTotal_tax = ISNULL(SUM(Extended*(100-@lnDiscount)/100*Tax_rate/100),0)
			--		FROM Soprices, SHIPTAX
			--		WHERE Custno = @lcSoCustno
			--		AND Linkadd = @lcSoSlinkadd
			--		AND SOPRICES.SONO = @lcEcoSono
			--		AND TAXTYPE = 'S'
			--		AND SOPRICES.TAXABLE = 1
			--ELSE
			---- Get Foreign tax info
			--	BEGIN
			--	SELECT @llSttx = ISNULL(Sttx,0), @lnSTaxRate = ISNULL(Tax_Rate,0.00)
			--		FROM ShipTax 
			--		WHERE Custno = @lcSoCustno
			--		AND Linkadd = @lcSoSlinkadd
			--		AND TaxType = 'E'
				
			--	SELECT @llPtProd = ISNULL(PtProd,0)
			--		FROM Shiptax 
			--		WHERE Custno = @lcSoCustno
			--		AND Linkadd = @lcSoSlinkadd
			--		AND TaxType = 'P'
					
			--	SELECT @lnTotalPTax = ISNULL(SUM(Extended*(100-@lnDiscount)/100*Tax_rate/100),0)
			--		FROM Soprices, SHIPTAX
			--		WHERE Custno = @lcSoCustno
			--		AND Linkadd = @lcSoSlinkadd
			--		AND SOPRICES.SONO = @lcEcoSono
			--		AND TAXTYPE = 'P'
			--		AND PTPROD = 1
			--		AND SOPRICES.TAXABLE = 1				

			--	BEGIN
			--	IF @llSttx = 0
			--		BEGIN
			--		SELECT @lnTotalSTax = ISNULL(SUM(Extended*(100-@lnDiscount)/100*Tax_rate/100),0)
			--			FROM Soprices, SHIPTAX
			--			WHERE Custno = @lcSoCustno
			--			AND Linkadd = @lcSoSlinkadd
			--			AND SOPRICES.SONO = @lcEcoSono
			--			AND TAXTYPE = 'E'
			--			AND STPROD = 1
			--			AND SOPRICES.TAXABLE = 1
			--		END
			--	ELSE
			--		IF @llPtProd = 1
			--		BEGIN
			--			SELECT @lnSoNeedTaxAmt = ISNULL(SUM(Extended*(100-@lnDiscount)/100),0)
			--					FROM Soprices
			--					WHERE SOPRICES.SONO = @lcEcoSono
			--					AND SOPRICES.TAXABLE = 1
			--			SET @lnTotalSTax = (@lnSoNeedTaxAmt + @lnTotalPTax)*@lnSTaxRate/100
			--		END
			--	END
	
			--END	

			-- {04/25/16 VL start new code to calculate tax from SopricesTax
			-- 01/17/17 VL added functional currency fields
			SELECT @Total_tax = 0, @Total_TaxFC = 0, @TotalPTax = 0, @TotalPTaxFC = 0, @TotalSTax = 0, @TotalSTaxFC = 0, @nCnt = 0, @nCnt2 = 0, @Total_TaxPR = 0, @TotalPTaxPR = 0, @TotalSTaxPR = 0
			DELETE FROM @ZSoprices WHERE 1=1
			-- Get all soprices that need to calculate tax
			-- 01/17/17 VL added functional currency fields
			INSERT @ZSoprices (Extended, ExtendedFC, Plpricelnk, ForeignTax, ExtendedPR)
				SELECT Soprices.Extended, Soprices.ExtendedFC, Soprices.Plpricelnk, Shipbill.ForeignTax, Soprices.ExtendedPR
					FROM Soprices, Sodetail, Shipbill
					WHERE Soprices.Uniqueln = Sodetail.Uniqueln 
					AND Sodetail.Slinkadd = Shipbill.Linkadd
					AND Soprices.Taxable = 1
					AND Sodetail.Sono = @lcEcoSono
			UPDATE @ZSoprices SET @nCnt = nrecno = @nCnt + 1

			WHILE @nCnt > @nCnt2
			BEGIN	
				SET @nCnt2 = @nCnt2 + 1;
				-- 01/17/17 VL added functional currency fields
				SELECT @SopExtended = Extended, @SopExtendedFC = ExtendedFC, @SopPlpricelnk = Plpricelnk, @SopForeignTax = ForeignTax, @SopExtendedPR = ExtendedPR
					FROM @ZSoprices
					WHERE nRecno = @nCnt2

					BEGIN
					-- Regular tax
					IF @SopForeignTax = 0	
						BEGIN
						-- Regular tax, just calculate TaxType = 'S'
						-- 01/17/17 VL added functional currency fields
						SELECT @lnTotal_tax = @lnTotal_tax + ISNULL(SUM(@SopExtended*(100-@lnDiscount)/100*Tax_rate/100),0),
							 @lnTotal_taxFC = @lnTotal_taxFC + ISNULL(SUM(@SopExtendedFC*(100-@lnDiscount)/100*Tax_rate/100),0),
							 @lnTotal_taxPR = @lnTotal_taxPR + ISNULL(SUM(@SopExtendedPR*(100-@lnDiscount)/100*Tax_rate/100),0)
						FROM SopricesTax
						WHERE PlpriceLnk = @SopPlpricelnk 
						END
					ELSE
					--Foreign tax
					----------------
						BEGIN
						-- Get Foreign tax info
				
						SELECT @llSttx = ISNULL(Sttx,0), @lnSTaxRate = ISNULL(Tax_Rate,0.00)
							FROM SopricesTax 
							WHERE Plpricelnk = @SopPlpricelnk
							AND TaxType = 'E'

						SELECT @llPtProd = ISNULL(PtProd,0)
							FROM SopricesTax 
							WHERE Plpricelnk = @SopPlpricelnk
							AND TaxType = 'P'

						-- 01/17/17 VL added functional currency fields
						SELECT @TotalPTax = ISNULL(SUM(@SopExtended*(100-@lnDiscount)/100*Tax_rate/100),0),
								@TotalPTaxFC = ISNULL(SUM(@SopExtendedFC*(100-@lnDiscount)/100*Tax_rate/100),0),
								@TotalPTaxPR = ISNULL(SUM(@SopExtendedPR*(100-@lnDiscount)/100*Tax_rate/100),0)
							FROM SopricesTax
							WHERE PlpriceLnk = @SopPlpricelnk 
							AND TAXTYPE = 'P'
							AND PTPROD = 1
						SET @lnTotalPTax = @lnTotalPTax + @TotalPTax	-- @TotalPTax will be used to caclulate @lnTotalSTax
						SET @lnTotalPTaxFC = @lnTotalPTaxFC + @TotalPTaxFC	-- @TotalPTax will be used to caclulate @lnTotalSTax
						-- 01/17/17 VL added functional currency fields
						SET @lnTotalPTaxPR = @lnTotalPTaxPR + @TotalPTaxPR

						BEGIN
						IF @llSttx = 0
							BEGIN
							-- 01/17/17 VL added functional currency fields
							SELECT @TotalSTax = ISNULL(SUM(@SopExtended*(100-@lnDiscount)/100*Tax_rate/100),0),
									@TotalSTaxFC = ISNULL(SUM(@SopExtendedFC*(100-@lnDiscount)/100*Tax_rate/100),0),
									@TotalSTaxPR = ISNULL(SUM(@SopExtendedPR*(100-@lnDiscount)/100*Tax_rate/100),0)
								FROM SopricesTax
								WHERE PlpriceLnk = @SopPlpricelnk 
								AND TAXTYPE = 'E'
								AND STPROD = 1
							
							SET @lnTotalSTax = @lnTotalSTax + @TotalSTax
							SET @lnTotalSTaxFC = @lnTotalSTaxFC + @TotalSTaxFC
							-- 01/17/17 VL added functional currency fields
							SET @lnTotalSTaxPR = @lnTotalSTaxPR + @TotalSTaxPR
							END
						ELSE
							IF @llPtProd = 1
							BEGIN
								-- 01/17/17 VL added functional currency fields
								SELECT @lnSoNeedTaxAmt = ISNULL(SUM(@SopExtended*(100-@lnDiscount)/100),0),
										@lnSoNeedTaxAmtFC = ISNULL(SUM(@SopExtendedFC*(100-@lnDiscount)/100),0),
										@lnSoNeedTaxAmtPR = ISNULL(SUM(@SopExtendedPR*(100-@lnDiscount)/100),0)
										
								SET @TotalSTax = (@lnSoNeedTaxAmt + @TotalPTax)*@lnSTaxRate/100
								SET @lnTotalSTax = @lnTotalSTax + @TotalSTax
								SET @TotalSTaxFC = (@lnSoNeedTaxAmtFC + @TotalPTaxFC)*@lnSTaxRate/100
								SET @lnTotalSTaxFC = @lnTotalSTaxFC + @TotalSTaxFC
								-- 01/17/17 VL added functional currency fields
								SET @TotalSTaxPR = (@lnSoNeedTaxAmtPR + @TotalPTaxPR)*@lnSTaxRate/100
								SET @lnTotalSTaxPR = @lnTotalSTaxPR + @TotalSTaxPR

							END
						END


						END
					END -- IF @SopForeignTax = 0	

			END
			-- 04/25/16 VL End}

			-- 04/25/16 VL added FC fields
			-- 01/17/17 VL changed to only show FC values if FC is installed
			--SET @ltSOChangeHd = @ltSOChangeHd+', SO Total:$'+LTRIM(RTRIM(STR(@lnSomainExtended + @lnTotal_tax - @lnSomainSoAmtDsct,17,2)))+'. List of Changes:'
			SET @ltSOChangeHd = @ltSOChangeHd+', SO Total:$'+LTRIM(RTRIM(STR(@lnSomainExtended + @lnTotal_tax - @lnSomainSoAmtDsct,17,2)))+
			CASE WHEN dbo.fn_IsFCInstalled() = 1 THEN ', SO FC Total:$' ELSE '' END + 
			LTRIM(RTRIM(STR(@lnSomainExtendedFC + @lnTotal_taxFC - @lnSomainSoAmtDsctFC,17,2)))+'. List of Changes:'

			-- 04/25/16 VL added FC fields, now Soamount should be soextend + Sotax + SoPTax + SoSTax - SoAmtDsct 
			UPDATE Somain SET 
				SoExtend = @lnSomainExtended,
				SoAmtDsct = @lnSomainSoAmtDsct,
				SoTax = @lnTotal_tax,
				SoPTax = @lnTotalPTax,
				SOSTAX = @lnTotalSTax,
				SOAMOUNT = @lnSomainExtended + @lnTotal_tax + @lnTotalPTax + @lnTotalSTax - @lnSomainSoAmtDsct,
				-- 04/25/16 VL added FC fields
				SoExtendFC = @lnSomainExtendedFC,
				SoAmtDsctFC = @lnSomainSoAmtDsctFC,
				SoTaxFC = @lnTotal_taxFC,
				SoPTaxFC = @lnTotalPTaxFC,
				SOSTAXFC = @lnTotalSTaxFC,
				SOAMOUNTFC = @lnSomainExtendedFC + @lnTotal_taxFC + @lnTotalPTaxFC + @lnTotalSTaxFC - @lnSomainSoAmtDsctFC,
				-- 01/17/17 VL added functional currency fields
				SoExtendPR = @lnSomainExtendedPR,
				SoAmtDsctPR = @lnSomainSoAmtDsctPR,
				SoTaxPR = @lnTotal_taxPR,
				SoPTaxPR = @lnTotalPTaxPR,
				SOSTAXPR = @lnTotalSTaxPR,
				SOAMOUNTPR = @lnSomainExtendedPR + @lnTotal_taxPR + @lnTotalPTaxPR + @lnTotalSTaxPR - @lnSomainSoAmtDsctPR,
				SoChanges = CAST(CASE WHEN DATALENGTH(SOCHANGES) <> 0 THEN CAST(SoChanges AS varchar(max))+CHAR(13) ELSE '' END + @ltSOChangeHd + 
							CASE WHEN @ltSOChangeDt <> '' THEN CHAR(13) + @ltSOChangeDt ELSE '' END AS TEXT)
					WHERE SONO = @lcEcoSono
			
		END -- End of this SO update
	END -- End of @lnTotalNo>@lnCount
END -- (@lnTotalNo>0)


END









