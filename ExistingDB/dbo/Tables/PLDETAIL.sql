CREATE TABLE [dbo].[PLDETAIL] (
    [PACKLISTNO]   CHAR (10)      CONSTRAINT [DF__PLDETAIL__PACKLI__025E20EC] DEFAULT ('') NOT NULL,
    [UNIQUELN]     CHAR (10)      CONSTRAINT [DF__PLDETAIL__UNIQUE__03524525] DEFAULT ('') NOT NULL,
    [UOFMEAS]      CHAR (4)       CONSTRAINT [DF__PLDETAIL__UOFMEA__0446695E] DEFAULT ('') NOT NULL,
    [SHIPPEDQTY]   NUMERIC (9, 2) CONSTRAINT [DF__PLDETAIL__SHIPPE__053A8D97] DEFAULT ((0)) NOT NULL,
    [cDESCR]       CHAR (45)      CONSTRAINT [DF__PLDETAIL__DESC__062EB1D0] DEFAULT ('') NOT NULL,
    [NOTE]         TEXT           CONSTRAINT [DF__PLDETAIL__NOTE__0722D609] DEFAULT ('') NOT NULL,
    [S_N_PRINT]    NUMERIC (1)    CONSTRAINT [DF__PLDETAIL__S_N_PR__0816FA42] DEFAULT ((0)) NOT NULL,
    [BEGSERNO]     CHAR (10)      CONSTRAINT [DF__PLDETAIL__BEGSER__090B1E7B] DEFAULT ('') NOT NULL,
    [ENDSERNO]     CHAR (10)      CONSTRAINT [DF__PLDETAIL__ENDSER__09FF42B4] DEFAULT ('') NOT NULL,
    [CERTDONE]     BIT            CONSTRAINT [DF__PLDETAIL__CERTDO__0AF366ED] DEFAULT ((0)) NOT NULL,
    [INV_LINK]     CHAR (10)      CONSTRAINT [DF__PLDETAIL__INV_LI__0BE78B26] DEFAULT ('') NOT NULL,
    [SHIPPEDREV]   CHAR (4)       CONSTRAINT [DF__PLDETAIL__SHIPPE__0CDBAF5F] DEFAULT ('') NOT NULL,
    [ARCSTATUS]    CHAR (10)      CONSTRAINT [DF__PLDETAIL__ARCSTA__0DCFD398] DEFAULT ('') NOT NULL,
    [SOBALANCE]    NUMERIC (9, 2) CONSTRAINT [DF__PLDETAIL__SOBALA__0EC3F7D1] DEFAULT ((0)) NOT NULL,
    [plpl_gl_nbr]  CHAR (13)      CONSTRAINT [DF_PLDETAIL_plpl_gl_nbr] DEFAULT ('') NOT NULL,
    [plcog_gl_nbr] CHAR (13)      CONSTRAINT [DF_PLDETAIL_plcog_gl_nbr] DEFAULT ('') NOT NULL,
    [uniq_key]     CHAR (10)      CONSTRAINT [DF_PLDETAIL_uniq_key] DEFAULT ('') NOT NULL,
    CONSTRAINT [PLDETAIL_PK] PRIMARY KEY CLUSTERED ([INV_LINK] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PACKLISTNO]
    ON [dbo].[PLDETAIL]([PACKLISTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [PKNOULN]
    ON [dbo].[PLDETAIL]([PACKLISTNO] ASC, [UNIQUELN] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQUELN]
    ON [dbo].[PLDETAIL]([UNIQUELN] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/11/10
-- Description:	Re-calculate invoice total when Plmain is updated
-- 04/22/13 VL found the code were incorrect, should not delete for packlistno, should delete for that inv_link
-- 11/14/13 VL found the delete code is still incorrect shoud be inv_link = @lcInv_link
-- ??/??/15 VL FC change
-- =============================================
CREATE TRIGGER [dbo].[Pldetail_Delete]
   ON [dbo].[PLDETAIL]
   AFTER DELETE
AS 

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	-- 04/22/13 VL found the code were incorrect, should not delete for packlistno, should delete for that inv_link
	--DECLARE @lcPacklistno char(10);
	--SELECT @lcPacklistno = Packlistno FROM Deleted 
	--DELETE FROM Plprices WHERE Packlistno = @lcPacklistno
	DECLARE @lcPacklistno char(10), @lcInv_link char(10);
	SELECT @lcPacklistno = Packlistno, @lcInv_link = Inv_link FROM deleted
	DELETE FROM PLPRICES WHERE Inv_link = @lcInv_link
	-- ??/??/15 VL FC change (new table)
	DELETE FROM PlpricesTax where Inv_link = @lcInv_link
	EXEC sp_Invoice_Total @lcPacklistno
	COMMIT			
END
GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/11/10
-- Description:	Re-calculate invoice total when Pldetail is updated
-- Modified:	04/29/14	VL	Added BEGIN..END in update plprice.quantity when there is difference.  Old code would run even @lnDifference2=0
--				12/22/14	VL	Added FC and GST
--				04/08/16	VL	Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				08/01/16	VL	Changed @PlShippedQty and @lnUpdShippedQty from numeric(7,0) to (9,2)
--				08/18/16	VL	Removed the '=' sign from insertint/updating Plprices for amortization charge, otherwise, it might create extra plprices record with 0 qty
--				10/06/16	VL	Added presentation currency code for functional curreny project
--				10/13/16	VL	Remove PRFchist_key because now both functional and presentation rates in one record
--				10/31/17 YS added new column to plAdj table (AdjustQty) and insert the record into pladj only if shipped qty were changed
--				11/01/17 YS remove @lcNewUniqNbr use default constraint for the filed 
--				11/11/2017 : Satish B : Insert fk_userId into PlAdj table
--              12/11/2019 Nitesh B : Change the Prichead to priceCustomer table to get Amortizaton
---             11/05/2020-11/09/2020 YS extensive modifications. 
---				11/10/2020 YS  more changes
---				11/11/2020 YS more changes
----			11/11/2020 YS fix qty to amortize now
-- =============================================	
CREATE TRIGGER [dbo].[Pldetail_Update]
   ON [dbo].[PLDETAIL]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @lcNewUniqNbr char(10), @lcChkUniqValue char(10), @PlPacklistno char(10), @PlUniqueln char(10), 
			@PlShippedQty numeric(9,2), @PlcDescr char(45), @PlInv_link char(10), @lnNewShippedQty numeric(9,2), 
			@lnOldShippedQty numeric(9,2), @m_invqty numeric(6,0), @m_amyqty numeric(6,0),
			@m_amortchg numeric(12,5), @lcSodetUniq_key char(10), @lcSodetCategory char(10), 
			@lnTotalNo int, @lcPlUniqLnk char(10), @PlPDescript char(45), @PlPPrice numeric(14,5), @PlPFlat bit, 
			@PlPExtended numeric(20,2), @PlPTaxable bit, @PlPPl_gl_nbr char(13), @PlPPlPriceLnk char(10), 
			@PlPCog_gl_nbr char(13), @lnDifference numeric(9,2), @PLPQuantity numeric(10,2), @lcPlUniqLnk2 char(10),
			@PLPQuantity2 numeric(10,2), @lcNewUniqNbrPrice char(10), @PlpricesQuantity numeric(10,2),
			@PlpricesPlpriceLnk char(10), @PlpricesPlUniqLnk char(10), @lnCount int, @lnSumQty numeric(10,2), 
			@SoQuantity numeric(10,2), @lnDifference2 numeric(9,2), @lnUpdShippedQty numeric(9,2), @PlPPriceFC numeric(14,5),
			@PlPExtendedFC numeric(20,2), @lFCInstalled bit, @PlFcUsed_uniq char(10), @PlFchist_key char(10),
			-- 10/06/16 VL added presentation currency fields
			@PlPPricePR numeric(14,5), @PlPExtendedPR numeric(20,2), @PlFuncFcused_Uniq char(10), @PlPrFcUsed_uniq char(10),
			---11/06/20 YS add varibale for qty available to amortize
			@amortizeQ NUMERIC(10,2) =0,@amortizeNowQ NUMERIC(10,2)=0,
			--11/09/20 YS added variable to check if the line edited marked as isSFBL
			@isSFBL BIT	;
	
	---11/09/20 YS add errror handling
	
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRY
	BEGIN TRANSACTION
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	-- 	10/06/16 VL added @PlFuncFcused_uniq, @PlPrFcused_uniq
	SELECT @PlFcUsed_uniq = FcUsed_uniq, @PlFchist_key = Fchist_key, @PlFuncFcused_uniq = FuncFcused_uniq, @PlPrFcused_uniq = PrFcused_uniq
		FROM PLMAIN
		WHERE PACKLISTNO = (SELECT packlistno FROM Inserted)
		
	DECLARE @ZPlprices TABLE (nrecno int identity, Quantity numeric(10,2), Plpricelnk char(10), PlUniqLnk char(10));
			
	SELECT @PlPacklistno = Inserted.Packlistno, @PlUniqueln = Inserted.Uniqueln, 
			@PlShippedQty = Inserted.ShippedQty, @PlInv_link = Inserted.Inv_link
		FROM Inserted
	
	SELECT @PlcDescr = ISNULL(Descript,ISNULL(Sodet_Desc,cDescr))
		FROM Pldetail
		LEFT OUTER JOIN Sodetail
		ON Pldetail.Uniqueln = Sodetail.Uniqueln
		LEFT OUTER JOIN Inventor
		ON Sodetail.uniq_key = Inventor.uniq_key
		WHERE Inv_link = @PlInv_link

	--10/31/17 YS insert a record only if the ShippedQty were cahnged 
	SELECT @lnNewShippedQty = ShippedQty FROM Inserted 
	SELECT @lnOldShippedQty = ShippedQty FROM Deleted
	IF (@lnNewShippedQty<>@lnOldShippedQty)
	BEGIN
		--- 11/01/17 YS remove @lcNewUniqNbr use default constraint for the filed 
		INSERT INTO PlAdj (Packlistno,Uniqueln,SavedDate,ShippedQty, AdjustQty,fk_userId)
		--11/11/2017 : Satish B : Insert fk_userId into PlAdj table
		SELECT @PlPacklistno,@PlUniqueln,GETDATE(),@lnNewShippedQty, @lnNewShippedQty-@lnOldShippedQty,saveUserId FROM inserted i INNER JOIN PLMAIN PL ON I.PACKLISTNO = PL.PACKLISTNO 
			--VALUES (@PlPacklistno,@PlUniqueln,GETDATE(),@lnNewShippedQty, @lnNewShippedQty-@lnOldShippedQty)
    END ---IF (@lnNewShippedQty<>@lnOldShippedQty)
	/* Update Plprices */
	--11/09/20 YS added @isSFBL
		SELECT @lcSodetUniq_key = Uniq_key, @lcSodetCategory = Category , --- customer (custno)
			@isSFBL = isSFBL
			FROM Sodetail 
			WHERE Uniqueln = @PlUniqueln and SUBSTRING(@PlUniqueln,1,1) <> '*'

	/*for the manual item */
	--11/09/20 YS added @isSFBL
	IF SUBSTRING(@PlUniqueln,1,1) = '*' 
	BEGIN	
		-- Pldetail Manaul Item
		UPDATE Plprices SET Quantity = @PlShippedQty, Descript = ISNULL(@PlcDescr,'') 
			WHERE Inv_link = @PlInv_link
	END --- F SUBSTRING(@PlUniqueln,1,1) = '*'
	/* for the item from the sales order */
	IF SUBSTRING(@PlUniqueln,1,1) <> '*' 
	BEGIN
		
		SELECT	@PlPDescript = Descript, @PlPPrice =Price, @PlPFlat =Flat, 
				@PlPExtended = Extended, @PlPTaxable = Taxable, @PlPPl_gl_nbr = Pl_gl_nbr, 
				@PlPPlPriceLnk = PlPriceLnk, @PlPCog_gl_nbr = Cog_gl_nbr, @PlPPriceFC = PriceFC, 
				@PlPExtendedFC = ExtendedFC, @PlPPricePR = PricePR, @PlPExtendedPR = ExtendedPR
				FROM Plprices
			WHERE Inv_link = @PlInv_link
			AND RecordType = 'P' 
			AND AmortFlag = ''
		--11/10/20 YS if prior SQL returns no records get the price from the sales order
		IF @@ROWCOUNT=0
			--- cannot find records with amortflag<>'A'. Need to get the price from the sales order
			SELECT @PlPDescript=Descriptio, 
			@PlPPrice=Price, @PlPFlat=Flat, 
			@PlPPlPriceLnk = Plpricelnk, 
			@PlPCog_gl_nbr = Cog_gl_nbr, 
			@PlPPriceFC = PriceFC, 
			@PlPPricePR = PricePR,
			@PlPTaxable = TAXABLE,
			@PlPPl_gl_nbr = PL_GL_NBR
			FROM SoPrices 
			WHERE Uniqueln = @PlUniqueln
			and RECORDTYPE='P';
		
		-- Get Sodetail info
		SELECT @m_invqty = 0, @m_amyqty = 0, @m_amortchg = 0;
		
	-- if the packing list ship first bill later do not include amortization	
		IF  @isSFBL=0
		BEGIN
		---11/06/20 YS change calcualtion for the amortization
		SELECT @m_amyqty = ISNULL(AmortQty,0), @m_amortchg = ISNULL(round(AmortAmount/AmortQty,5),0.00)
			FROM priceheader ph
				join priceCustomer pc on ph.uniqprhead = pc.uniqprhead
			WHERE ph.uniq_key = @lcSodetUniq_key
			AND pc.custno = @lcSodetCategory
			and AmortQty<>0
			/* find shipped so far with amortization price added*/
			select  @m_invqty=isnull(sum(pr.quantity),0.0)
			from pldetail pd inner join plmain pm on pm.PACKLISTNO = pd.PACKLISTNO 
			inner join PLPRICES pr on pd.INV_LINK=pr.INV_LINK
			where pd.uniq_key=@lcSodetUniq_key and pm.CUSTNO = @lcSodetCategory
			and pr.AMORTFLAG='A'
		END	--- IF  @isSFBL=0
	
		--- available to amortize
		SELECT @amortizeQ=CASE WHEN @m_amyqty-@m_invqty>0 then  @m_amyqty-@m_invqty else 0.00 end
		DECLARE @UpDateQty numeric(10,2)
		SELECT @UpDateQty=@lnNewShippedQty - @lnOldShippedQty
	
		-- 08/18/16 VL removed the '=' sign from next line, otherwise, it might create extra plprices record with 0 qty
		IF @lnNewShippedQty > @lnOldShippedQty
		BEGIN
			/* find what can be amortize now*/
			---11/11/20 YS changed @amortizeNowQ calculation
		
			SELECT @amortizeNowQ=CASE WHEN @amortizeQ=0 THEN 0 
				--11/11/20 YS remove the next line
			---or @amortizeQ<=ISNULL(SUM(Quantity),0.0) THEN 0 
				WHEN @amortizeQ>@UpDateQty THEN @amortizeQ-@UpDateQty 
				WHEN @amortizeQ<=@UpDateQty THEN @amortizeQ END
			---@amortizeQ-ISNULL(SUM(Quantity),0.0) END
				FROM plprices where Inv_link = @PlInv_link
						 AND RecordType = 'P' 
						AND AmortFlag = 'A'

			IF (@UpDateQty <= @amortizeNowQ)
				/* check if the record with amortization exists */
			BEGIN	
				-- update if exists	
				UPDATE plprices set QUANTITY=QUANTITY+@UpDateQty,
					EXTENDED=(QUANTITY+@UpDateQty)*Price,
					EXTENDEDFC=(QUANTITY+@UpDateQty)*PriceFC,
					EXTENDEDPR=(QUANTITY+@UpDateQty)*PricePR,
					@amortizeNowQ=0
						where Inv_link = @PlInv_link
						 AND RecordType = 'P' 
						AND AmortFlag = 'A'
				/* check if @amortizeQ<>0 need to insert. Probably did not have amortized record for this PL*/
				IF @amortizeNowQ<>0
					INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity, Flat, Extended, Taxable, 
							Inv_Link, RecordType, AmortFlag, Pl_gl_nbr, PlPriceLnk, Cog_gl_nbr,  PriceFC, ExtendedFC,
							PricePR, ExtendedPR)
					VALUES (@PlPacklistno, @PlUniqueln, ISNULL(@PlPDescript,''), @PlPPrice + @m_amortchg,
							@UpDateQty, @PlPFlat, @UpDateQty*(@PlPPrice + @m_amortchg), @PlPTaxable,
							@PlInv_link, 'P', 'A', @PlPPl_gl_nbr, @PlPPlPriceLnk, @PlPCog_gl_nbr, 
							@PlPPriceFC+ @m_amortchg, @UpDateQty*(@PlPPriceFC+ @m_amortchg), @PlPPricePR, @PlPExtendedPR)
	
			END -- (@UpDateQty <= @amortizeNowQ)
			ELSE IF (@UpDateQty > @amortizeNowQ)
			BEGIN	
				UPDATE plprices set QUANTITY=QUANTITY+@amortizeNowQ,
						Extended=(QUANTITY+@amortizeNowQ)*Price,
						ExtendedFC=(QUANTITY+@amortizeNowQ)*PriceFc,
						@UpDateQty=@UpDateQty-@amortizeNowQ						
						where Inv_link = @PlInv_link
						 AND RecordType = 'P' 
						AND AmortFlag = 'A'
				IF @@ROWCOUNT<>0
					SELECT @amortizeNowQ=0
				IF @amortizeNowQ<>0
					/* no record with AmortFlag = 'A' prior to update */
					INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity, Flat, Extended, Taxable, 
							Inv_Link, RecordType, AmortFlag, Pl_gl_nbr, PlPriceLnk, Cog_gl_nbr,  PriceFC, ExtendedFC,
							PricePR, ExtendedPR)
					VALUES (@PlPacklistno, @PlUniqueln, isnull(@PlPDescript,''), @PlPPrice + @m_amortchg,
							@amortizeNowQ, @PlPFlat, @amortizeNowQ*(@PlPPrice + @m_amortchg), @PlPTaxable,
							@PlInv_link, 'P', 'A', @PlPPl_gl_nbr, @PlPPlPriceLnk, @PlPCog_gl_nbr, 
							@PlPPriceFC+ @m_amortchg, @amortizeNowQ*(@PlPPriceFC+ @m_amortchg), @PlPPricePR, @PlPExtendedPR)
				
/* test */
--select @UpDateQty
--select QUANTITY=QUANTITY+@UpDateQty,* from plprices where Inv_link = @PlInv_link
--						 AND RecordType = 'P' 
--						AND AmortFlag = ''
/*end test*/
				IF @UpDateQty<>0
				BEGIN
					UPDATE plprices set QUANTITY=QUANTITY+@UpDateQty,
						Extended=(QUANTITY+@UpDateQty)*Price,
						ExtendedFC=(QUANTITY+@UpDateQty)*PriceFc
						where Inv_link = @PlInv_link
						 AND RecordType = 'P' 
						AND AmortFlag = ''
					IF @@ROWCOUNT<>0 
					SELECT @UpDateQty=0
				END
--/* test */
--select @UpDateQty
--select QUANTITY=QUANTITY+@UpDateQty,* from plprices where Inv_link = @PlInv_link
--						 AND RecordType = 'P' 
--						AND AmortFlag = ''
--/*end test*/
				IF @UpDateQty>0 --- the above update failed because we did not have RecordType = 'P' AND AmortFlag = ' '
					INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity, Flat, Extended, Taxable, 
							Inv_Link, RecordType, AmortFlag, Pl_gl_nbr, PlPriceLnk, Cog_gl_nbr,  PriceFC, ExtendedFC,
							PricePR, ExtendedPR)
					VALUES (@PlPacklistno, @PlUniqueln, isnull(@PlPDescript,''), @PlPPrice ,
							@UpDateQty, @PlPFlat, @UpDateQty*@PlPPrice, @PlPTaxable,
							@PlInv_link, 'P', '', @PlPPl_gl_nbr, @PlPPlPriceLnk, @PlPCog_gl_nbr, 
							@PlPPriceFC, @UpDateQty*@PlPPriceFC, @PlPPricePR, @UpDateQty*@PlPPricePR)
			

			END --- ELSE IF (@UpDateQty > @amortizeNowQ)
		END --- IF @lnNewShippedQty > @lnOldShippedQty
		ELSE IF @lnNewShippedQty < @lnOldShippedQty
		BEGIN
		/*@updateQty is <0*/
			--- complete changes to calculation when qty is reduced
			if object_id('tempdb..#prUpdate') IS NOT NULL
				DROP TABLE #prUpdate
			if object_id('tempdb..#t1') IS NOT NULL
				DROP TABLE #t1
			if object_id('tempdb..#t2') IS NOT NULL
				DROP TABLE #t2
			
			SELECT @UpDateQty=ABS(@UpDateQty);

			--;WITH T1 AS
			 SELECT  * ,
				running_total = SUM(QUANTITY) OVER (ORDER BY AmortFlag 
                         ROWS BETWEEN UNBOUNDED PRECEDING 
                                            AND CURRENT ROW)
				INTO #T1
				FROM PLPRICES
				where Inv_link = @PlInv_link
				AND RecordType = 'P' 
				--)
/*test*/
--select * from #t1
/*test*/
			--T2 AS 
			--(
			SELECT *, 
				prev_running_total = isnull(LAG(running_total) OVER (ORDER BY AmortFlag),0.00)
			INTO #T2
			FROM #T1
		---)
/*test*/
--select * from #t2
/*test*/
			--prUpdate
			--as
			--(
			SELECT  PLUNIQLNK,
				AMORTFLAG,QUANTITY,
            CASE
             --run out
             WHEN prev_running_total >= @UpDateQty THEN 0
				 --budget left but not enough for whole qty
				WHEN running_total > @UpDateQty THEN @UpDateQty - prev_running_total 
				WHEN @UpDateQty <= T2.Quantity  THEN @UpDateQty
             --Can do full amount 
             ELSE Quantity    END as Reduce
			INTO #prUpdate
			FROM     #T2 T2
			--)
			--SELECT * INTO #prUpdate from prUpdate
/*test */
--select * from #prUpdate
/*test*/
			--- 11/11/20 YS if qty reduced become 0 delete the record
			delete from plprices where PLUNIQLNK in (select PLUNIQLNK from #prUpdate where PLPRICES.QUANTITY-reduce<=0)

			UPDATE plprices set QUANTITY=plprices.QUANTITY-Reduce, 
				EXTENDED=(plprices.QUANTITY-Reduce)*Price,
				EXTENDEDFC=(plprices.QUANTITY-Reduce)*PriceFC
			FROM #prUpdate 
				where [#prUpdate].PLUNIQLNK = plprices.PLUNIQLNK
				and plprices.QUANTITY>Reduce
			
		END -- ELSE IF @lnNewShippedQty < @lnOldShippedQty
		 -- have to deal with amortization quantities
	END--- IF SUBSTRING(@PlUniqueln,1,1) <> '*'
	
	-- Now update Plprices.Recordtype = 'O'
	INSERT @ZPlprices
	SELECT Quantity, Plpricelnk, PlUniqlnk
		FROM PlPrices 
		WHERE RecordType <> 'P'
		AND SUBSTRING(Uniqueln,1,1) <> '*'
		AND Inv_link = @PlInv_link
		
		
	SET @lnTotalNo = @@ROWCOUNT;	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @PlpricesQuantity = Quantity, @PlpricesPlpriceLnk = PlpriceLnk, @PlpricesPlUniqLnk = PlUniqLnk	
			FROM @ZPlprices WHERE nrecno = @lnCount
		BEGIN
		IF (@@ROWCOUNT<>0)
				
			SELECT @lnSumQty = ISNULL(SUM(Quantity),0) FROM Plprices 
				WHERE PlPricelnk = @PlpricesPlpriceLnk
				AND PlUniqLnk <> @PlpricesPlUniqLnk	-- not count itself
				
			SELECT @SoQuantity = Quantity FROM Soprices
				WHERE PlPriceLnk = @PlpricesPlpriceLnk
				
			SET @lnDifference2 = @SoQuantity - @lnSumQty
			BEGIN
			IF @lnDifference2 <> 0
				-- 04/29/14 VL added BEGIN..END, so the @lnDifference2<>0 code won't be run unintentionally
				BEGIN
					BEGIN
					IF @lnDifference2 < @PlShippedQty
						SET @lnUpdShippedQty = CASE WHEN @lnDifference2 >=0 THEN @lnDifference2 ELSE 0 END
					ELSE
						SET @lnUpdShippedQty = @PlShippedQty
					END
				UPDATE Plprices SET Quantity = @lnUpdShippedQty
					WHERE PlUniqLnk = @PlpricesPlUniqLnk
				END
			END
			
		END
	END
	-- 12/22/14 VL added code to update Price by PriceFC conversion and Extended by ExtendedFC conversion
	IF @lFCInstalled = 1
	BEGIN
	UPDATE PLPRICES SET 
		-- 10/06/16 VL added 4th @PlFuncFcused_uniq as 4th basecurkey parameter and added for PricePR and ExtendedPR convert from PriceFC and Extended
		PRICE = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq, PRICEFC, @PlFuncFcused_uniq, @PlFchist_key),
		EXTENDED = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq, ExtendedFC,@PlFuncFcused_uniq,@PlFchist_key),
		PRICEPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq, PRICEFC, @PlPRFcused_uniq, @PlFchist_key),
		EXTENDEDPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq, ExtendedFC,@PlPRFcused_uniq,@PlFchist_key)
		WHERE PLUNIQLNK = @PlInv_link
	END
	-- 12/22/14 VL End}
						
	EXEC sp_Invoice_Total @PlPacklistno
	IF @@TRANCOUNT>0
		COMMIT
	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT>0
		ROLLBACK
		SELECT @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

	END CATCH
END --- trigger end
GO
-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <2010/07/30>
-- Description:	<Update necessary tables when user insert new Pldetail record>
-- 07/21/14 VL changed @PlShippedQty from numeric(7,0) to numeric(9,2), so if the shipped qty has decimal, it will carry to plprice table properly
-- 12/18/14 VL added PriceFC and ExtendedFC	
-- 12/19,22/14 VL Added PlpricesTax code 
-- 02/27/15 VL added 5 logical tax fields into PlpricesTax
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 10/05/16 VL Added presentation currency code for functional curreny project
-- 10/13/16 VL removed PRfchist_key
-- 11/11/2017 Satish B : Insert fk_userId into PlAdj table
-- 8/26/2019 Nitesh B : Change for Flat scenario "When Flat is Check AND if already invoice is created and we added SOAMOUNT/PRICE then the remaining amount left for sales order should be the invoice total for next PL"
-- 8/26/2019 Nitesh B : Added @plPrice and @soPrice for getting Price from PLPRICES and SOPRICES
-- 12/11/2019 Nitesh B : Change the Prichead to priceCustomer table to get Amortizaton
-- 12/26/2019 Nitesh B : Insert record into PLPRICE when Manual Packing List only
-- 02/18/2020 Nitesh B : Added @isSFBL for checking sales order is SFBL true and make price 0
-- 11/05/20 YS Amortization calculation is not working correctly CAPA 3209
-- 11/19/2020 VL added 4 new tax fields in inserting PlpricesTax
-- 01/25/21 VL comment out the code Nitesh B added on 12/26/19, we will still add the plprices if the manual pk item is linked to a SO, also, if this is stand-alone PK, the cog_gl_nbr is from Arsetup.Ar_gl_no
-- =============================================
CREATE TRIGGER [dbo].[Pldetail_Insert]
   ON [dbo].[PLDETAIL]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	-- Insert statements for trigger here
	-- 12/18/14 VL added lnSoPriceFC and lnSoExtendedFC
	-- 12/19/14 VL added to get if FC module is installed
	-- 10/05/16 VL added @lnSoPricePR, @lnSoExtendedPR, @PlFuncFcused_uniq, @PlPrFcused_uniq
	--11/05/20 YS add default for @m_amortchg and @m_amyqty
	-- 01/25/21 VL added @Sono, so can check if the PK is stand-alone PK or not, and added @Ar_gl_no to get from Arsetup.Ar_gl_no to save in plprices.cog_gl_nbr
	DECLARE @lcNewUniqNbr char(10), @lcChkUniqValue char(10), @PlPacklistno char(10), 
			@PlUniqueln char(10), @PlShippedQty numeric(9,2), @PlPl_gl_nbr char(13),
			@PlCog_gl_nbr char(13), @PlcDescr char(45), @PlInv_link char(10), @lnTotalNo int,
			@lnCount int, @lcSoSono char(10), @lcSoDescriptio char(45), @lnSoQuantity numeric(10,2),
			@lnSoPrice numeric(14,5), @lnSoExtended numeric(20,2), @llSoTaxable bit, @llSoFlat bit, 
			@lcSoRecordType char(1), @lcSoSaleTypeId char(10), @lcSoPlpricelnk char(10), @lcSoUniqueln char(10), 
			@lcSoPl_gl_nbr char(13), @lcSoCog_gl_nbr char(13), @m_invqty numeric(6,0), @m_amyqty numeric(6,0)=0.00,
			@m_amortchg numeric(12,5)=0.00, @lcSodetUniq_key char(10), @lcSodetCategory char(10), @llFirstFlat bit,
			@lcPk char(10), @lcNewUniqNbrPrice char(10), @lnPlpriceQtySum numeric(10,2), @lnDiff numeric(10,2),
			@lnShippedQty numeric(10,2), @lnSoPriceFC numeric(14,5), @lnSoExtendedFC numeric(20,2), @lFCInstalled bit, 
			@PlFcUsed_uniq char(10), @PlFchist_key char(10), @lnSoPricePR numeric(14,5), @lnSoExtendedPR numeric(20,2), 
			@PlFuncFcused_uniq char(10), @PlPrFcused_uniq char(10), @plPrice numeric(14,5), @soPrice numeric(14,5), -- 8/26/2019 Nitesh B : Added @plPrice and @soPrice for getting Price from PLPRICES and SOPRICES
	        @isSFBL bit -- 02/18/2020 Nitesh B : Added @isSFBL for checking sales order is SFBL true
			,@Sono char(10), @Ar_gl_no char(13)

	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	-- 	10/05/16 VL added @PlFuncFcused_uniq, @PlPrFcused_uniq
	-- 01/25/21 VL added @Sono
   	SELECT @PlFcUsed_uniq = FcUsed_uniq, @PlFchist_key = Fchist_key, @PlFuncFcused_uniq = FuncFcused_uniq, @PlPrFcused_uniq = PrFcused_uniq, @Sono = Sono
		FROM PLMAIN
		WHERE PACKLISTNO = (SELECT packlistno FROM Inserted)

	-- 01/25/21 VL added @Ar_gl_no
	SELECT @Ar_gl_no = Ar_gl_no FROM Arsetup
	
	-- 12/18/14 VL added PriceFC and ExtendedFC	
	-- 10/05/16 VL added PricePR and ExtendedPR
	DECLARE @ZSoprices TABLE (nrecno int identity, Sono char(10), Descriptio char(45), Quantity numeric(10,2),
			Price numeric(14,5), Extended numeric(20,2), Taxable bit, Flat bit, RecordType char(1), 
			SaleTypeId char(10), Plpricelnk char(10), Uniqueln char(10), Pl_gl_nbr char(13), Cog_gl_nbr char(13),
			PriceFC numeric(14,5), ExtendedFC numeric(20,2), PricePR numeric(14,5), ExtendedPR numeric(20,2));
	
	SELECT @PlPacklistno = Inserted.Packlistno, @PlUniqueln = Inserted.Uniqueln, 
			@PlShippedQty = Inserted.ShippedQty, @PlPl_gl_nbr = Inserted.PlPl_gl_nbr,
			@PlCog_gl_nbr = Inserted.PlCog_gl_nbr, @PlcDescr = Inserted.cDescr, 
			@PlInv_link = Inserted.Inv_link
		FROM Inserted
	
	
	/* Update PlAdj */
	WHILE (1=1)
	BEGIN
		EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
		SELECT @lcChkUniqValue = PladjUnique FROM Pladj WHERE PladjUnique = @lcNewUniqNbr
		IF (@@ROWCOUNT<>0)
			CONTINUE
		ELSE
			BREAK
	END			
	INSERT INTO PlAdj (Packlistno,Uniqueln,SavedDate,ShippedQty, PladjUnique,fk_userId)
	--11/11/2017 : Satish B : Insert fk_userId into PlAdj table
		SELECT @PlPacklistno,@PlUniqueln,GETDATE(),@PlShippedQty, @lcNewUniqNbr,saveUserId FROM inserted i INNER JOIN PLMAIN PL ON I.PACKLISTNO = PL.PACKLISTNO 
		--VALUES (@PlPacklistno,@PlUniqueln,GETDATE(),@PlShippedQty, @lcNewUniqNbr,(SELECT saveUserId FROM PLMAIN WHERE PACKLISTNO=(SELECT PACKLISTNO FROM inserted)))

	/* Update Plprices */
	/* Check Pldetail.Uniqueln to decide where it's from */
	IF SUBSTRING(@PlUniqueln,1,1) = '*'
		BEGIN
			-- Get unique value for PlUniqLnk
			WHILE (1=1)
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbrPrice OUTPUT
				SELECT @lcChkUniqValue = PlUniqlnk FROM Plprices WHERE PlUniqlnk = @lcNewUniqNbrPrice
				IF (@@ROWCOUNT<>0)
					CONTINUE
				ELSE
					BREAK
			END	
						
			-- Pldetail Manaul Item
			--12/18/14 VL added ExtendedFC
			-- 12/26/2019 Nitesh B : Insert record into PLPRICE when Manual Packing List only
			-- 01/25/21 VL comment out the code Nitesh B added on 12/26/19, we will still add the plprices if the manual pk item is linked to a SO
			--DECLARE @plType char(20), @InvoiceType char(20);
			--Select @plType = plType, @InvoiceType = InvoiceType FROM PLMAIN WHERE PACKLISTNO = @PlPacklistno;
			--IF(@plType = 'Manual' AND @InvoiceType = 'Manual')
			--BEGIN
				-- 01/25/21 VL changed for Cog_gl_nbr, if it's stand alone PK, the it's always from arsetup.Ar_gl_no, found now in cube PK, it doesn't ask for GL numbers
				INSERT INTO plprices (Packlistno,Uniqueln,Descript,Price,Quantity,Flat,Extended,ExtendedFC,
								Taxable,Inv_link,RecordType, Pl_gl_nbr, Cog_gl_nbr, PlUniqLnk)
						VALUES (@PlPacklistno,@PlUniqueln,@PlcDescr,0,@PlShippedQty,0,0,0,0,
								@PlInv_link,'O', @PlPl_gl_nbr, CASE WHEN @Sono<>'' THEN @PlCog_gl_nbr ELSE @Ar_gl_no END ,@lcNewUniqNbrPrice)
			--END	
		END
	ELSE
		BEGIN
		-- Need to check if Soprices.Recordtype = 'P' or 'O'
		-- Get Sodetail info
		SELECT @lcSodetUniq_key = Uniq_key, @lcSodetCategory = Category, @isSFBL = isSFBL -- 02/18/2020 Nitesh B : Added @isSFBL for checking sales order is SFBL true
			FROM Sodetail 
			WHERE Uniqueln = @PlUniqueln

		-- Error, no sodetail is found
		SET @lnTotalNo = @@ROWCOUNT;	
		IF @lnTotalNo = 0	
			BEGIN
			--set @lRollBack=1
			RAISERROR('Programming error, can not find associated sales order items. This operation will be cancelled. Please try again',1,1)
			ROLLBACK TRANSACTION
		END
		
		-- Get Amortizaton -- 12/11/2019 Nitesh B : Change the Prichead to priceCustomer table to get Amortizaton
			-- 11/05/20 YS the pldetail will have packing list number from this ionsert already. Have to exclude it to calculate 
			--- qty shipped or remove qty shipped this time
			
			--- 11/06/20 YS get the qty from the plprice for the records with amortfglag='A' 
			
			--select  @m_invqty=isnull(sum(pd.SHIPPEDQTY),0.0)
			--from pldetail pd inner join plmain pm on pm.PACKLISTNO = pd.PACKLISTNO 
			--where pd.uniq_key=@lcSodetUniq_key and pm.CUSTNO = @lcSodetCategory
			--and pm.PACKLISTNO<>@PlPacklistno  

			select  @m_invqty=isnull(sum(pr.QUANTITY),0.0)
			from pldetail pd inner join plmain pm on pm.PACKLISTNO = pd.PACKLISTNO
			inner join plprices pr on pd.INV_LINK=pr.INV_LINK
			where pd.uniq_key=@lcSodetUniq_key and pm.CUSTNO = @lcSodetCategory
			and pr.AMORTFLAG='A'
			and pm.PACKLISTNO<>@PlPacklistno  

			
			--- 11/05/20 the @m_amortchg AmortAmount is for the total amortization qty @m_amyqty need to find price per unit
			SELECT @m_amyqty = ISNULL(AmortQty,0), @m_amortchg = ISNULL(round(AmortAmount/AmortQty,5),0.00)
			FROM priceheader ph
			join priceCustomer pc on ph.uniqprhead = pc.uniqprhead
			WHERE ph.uniq_key = @lcSodetUniq_key
			AND pc.custno = @lcSodetCategory
			and AmortQty<>0
			
	


		--SELECT @m_invqty = ISNULL(Invqty,0), @m_amyqty = ISNULL(Amyqty,0), @m_amortchg = ISNULL(Amortchg,0)
		--	FROM Prichead
		--	WHERE Uniq_key = @lcSodetUniq_key
		--	AND Category = @lcSodetCategory
			
		-- Get Soprices info
		-- 12/18/14 VL added PriceFC and ExtendedFC
		-- 10/05/16 VL added PricePR and ExtendedPR
		INSERT @ZSoprices
		SELECT Sono, Descriptio, Quantity, Price, Extended, Taxable, Flat, RecordType, 
				SaleTypeId, Plpricelnk, Uniqueln, Pl_gl_nbr, Cog_gl_nbr, PRICEFC, ExtendedFC, PricePR, ExtendedPR
			FROM SoPrices 
			WHERE Uniqueln = @PlUniqueln;

		-- Error, no soprices is found
		SET @lnTotalNo = @@ROWCOUNT;	
		IF @lnTotalNo = 0	
			BEGIN
			--set @lRollBack=1
			RAISERROR('Programming error, can not find associated sales order price items. This operation will be cancelled. Please try again',1,1)
			ROLLBACK TRANSACTION
		END
		
		-- SCAN through Soprices
		SET @lnCount=0;
		WHILE @lnTotalNo>@lnCount
		BEGIN	
			SET @lnCount=@lnCount+1;
			-- 12/18/14 VL added SopriceFC and SoExtendedFC
			-- 10/05/16 VL added PricePR and ExtendedPR
			-- 02/18/2020 Nitesh B : Added @isSFBL for checking sales order is SFBL true and make price 0
			SELECT @lcSoSono = Sono, @lcSoDescriptio = Descriptio, @lnSoQuantity = Quantity,
					@lnSoPrice = CASE WHEN @isSFBL = 1 THEN 0 ELSE Price END, @lnSoExtended = CASE WHEN @isSFBL = 1 THEN 0 ELSE Extended END, @llSoTaxable = Taxable, 
					@llSoFlat = Flat, @lcSoRecordType = RecordType, @lcSoSaleTypeId = SaleTypeId, 
					@lcSoPlpricelnk = Plpricelnk, @lcSoUniqueln = Uniqueln, @lcSoPl_gl_nbr = Pl_gl_nbr,
					@lcSoCog_gl_nbr = Cog_gl_nbr, @lnSoPriceFC = CASE WHEN @isSFBL = 1 THEN 0 ELSE PriceFC END, 
					@lnSoExtendedFC = CASE WHEN @isSFBL = 1 THEN 0 ELSE ExtendedFC END, 
					@lnSoPricePR = CASE WHEN @isSFBL = 1 THEN 0 ELSE PricePR END, @lnSoExtendedPR = CASE WHEN @isSFBL = 1 THEN 0 ELSE ExtendedPR END 
			FROM @ZSoprices WHERE nrecno = @lnCount
			IF (@@ROWCOUNT<>0)
			BEGIN
				-- Set up for Flat
				SET @llFirstFlat = 1
				BEGIN
				IF @llSoFlat = 1
				
					SELECT @lcPk = Packlistno 
						FROM Plprices 
						WHERE Plpricelnk = @lcSoPlpricelnk

					IF (@@ROWCOUNT=0)
						SET @llFirstFlat = 1
					ELSE 
					   BEGIN -- 8/26/2019 Nitesh B : Change for Flat scenario "When Flat is Check AND if already invoice is created and we added SOAMOUNT/PRICE then the remaining amount left for sales order should be the invoice total for next PL"
							SELECT @plPrice = SUM(PRICE) FROM PLPRICES WHERE PLPRICELNK = @lcSoPlpricelnk
							SELECT @soPrice = SUM(PRICE) FROM SOPRICES WHERE PLPRICELNK = @lcSoPlpricelnk
							IF((@soPrice - @plPrice) > 0)
							BEGIN
								SET @lnSoPrice = (@soPrice - @plPrice)
								SET @llFirstFlat = 1
							END
							ELSE
								SET @llFirstFlat = 0
					   END

				END
				
				-- Get unique value for PlUniqLnk
				BEGIN
					WHILE (1=1)
					BEGIN
						EXEC sp_GenerateUniqueValue @lcNewUniqNbrPrice OUTPUT
						SELECT @lcChkUniqValue = PlUniqlnk FROM Plprices WHERE PlUniqlnk = @lcNewUniqNbrPrice
						IF (@@ROWCOUNT<>0)
							CONTINUE
						ELSE
							BREAK
					END			
				END
				
				BEGIN
				IF @lcSoRecordType = 'P'
				/* Inventory item*/
				
					BEGIN
					IF @m_invqty < @m_amyqty		--&& Find record in Prichead
						BEGIN
						IF @m_invqty+@PlShippedQty <= @m_amyqty		--&& One line for amorization
							BEGIN
							-- 12/18/14 VL added priceFC and ExtendedFC
							INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity, Flat, Extended,
										Taxable, Inv_Link, RecordType, AmortFlag, Pl_gl_nbr, PlPriceLnk, Cog_gl_nbr, PlUniqlnk, PRICEFC, EXTENDEDFC)
							VALUES (@PlPacklistno, @PlUniqueln, @lcSoDescriptio, CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice+@m_amortchg ELSE 0.00000 END,
									@PlShippedQty, @llSoFlat, 
									CASE WHEN @llSoFlat = 1 THEN
										CASE WHEN @PlShippedQty <> 0 THEN 
											CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice+@m_amortchg ELSE 0.00000 END 
										ELSE 0 END
									ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice+@m_amortchg ELSE 0.00000 END END,
									@llSoTaxable, @PlInv_link, @lcSoRecordType, 'A', @lcSoPl_gl_nbr, @lcSoPlpricelnk, @lcSoCog_gl_nbr, @lcNewUniqNbrPrice,
									CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END,
									CASE WHEN @llSoFlat = 1 THEN
									CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END END)
							
							-- [12/19/14 VL Added code to update Plprices.price and extended by converting pricefc and extendedfc
							-- 10/05/16 VL added PricePR and ExtendedPR
							IF @lFCInstalled = 1
							BEGIN
							-- 10/05/16 VL added 4th @PlFuncFcused_uniq as 4th basecurkey parameter and added for PricePR and ExtendedPR convert from PriceFC and Extended
							UPDATE PLPRICES SET 
								PRICE = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END,@PlFuncFcused_uniq,@PlFchist_key),
								EXTENDED = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
									CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END END
									,@PlFuncFcused_uniq,@PlFchist_key),
								PRICEPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END,@PlPRFcused_uniq,@PlFchist_key),
								EXTENDEDPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
									CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END END
									,@PlPRFcused_uniq,@PlFchist_key)
								WHERE PLUNIQLNK = @lcNewUniqNbrPrice
							END
							-- 12/19/14 VL End}
							
							--UPDATE PricHead SET InvQty = InvQty + @PlShippedQty
							--	WHERE Uniq_key = @lcSodetUniq_key
							--	AND Category = @lcSodetCategory
							END
						ELSE		
							BEGIN									--&& Two line with amorization and not
							--** Amortizaton part
							-- 12/18/14 VL added SopriceFC and SoExtendedFC
							INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity, Flat, Extended,
										Taxable, Inv_Link, RecordType, AmortFlag, Pl_gl_nbr, PlPriceLnk, Cog_gl_nbr, PlUniqlnk, PRICEFC, EXTENDEDFC)
							VALUES (@PlPacklistno, @PlUniqueln, @lcSoDescriptio, CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice+@m_amortchg ELSE 0.00000 END,
									---11/05/20 YS the quantity of what left to amortize
									@m_amyqty-@m_invqty, @llSoFlat, 
									CASE WHEN @llSoFlat = 1 THEN
									---11/05/20 YS use @m_amyqty-@m_invqty instead of the @PlShippedQty
										CASE WHEN @m_amyqty-@m_invqty <> 0 THEN 
											CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice+@m_amortchg ELSE 0.00000 END 
										ELSE 0 END
									---11/05/20 YS the quantity of what left to amortize
									--ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice+@m_amortchg ELSE 0.00000 END END,
									ELSE (@m_amyqty-@m_invqty)* CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice+@m_amortchg ELSE 0.00000 END END,
									@llSoTaxable, @PlInv_link, @lcSoRecordType, 'A', @lcSoPl_gl_nbr, @lcSoPlpricelnk, @lcSoCog_gl_nbr, @lcNewUniqNbrPrice,
									CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END,
									CASE WHEN @llSoFlat = 1 THEN
									---11/05/20 YS use @m_amyqty-@m_invqty instead of the @PlShippedQty
									--CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END ELSE 0 END
									CASE WHEN @m_amyqty-@m_invqty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END END)

							-- [12/19/14 VL Added code to update Plprices.price and extended by converting pricefc and extendedfc
							IF @lFCInstalled = 1
							BEGIN
							-- 10/05/16 VL added 4th @PlFuncFcused_uniq as 4th basecurkey parameter and added for PricePR and ExtendedPR convert from PriceFC and Extended
							UPDATE PLPRICES SET 
								PRICE = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END,@PlFuncFcused_uniq,@PlFchist_key),
								EXTENDED = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
								---11/05/20 YS the quantity of what left to amortize
									CASE WHEN @llSoFlat = 1 THEN CASE WHEN @m_amyqty-@m_invqty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END ELSE 0 END
									ELSE @m_amyqty-@m_invqty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END END
									,@PlFuncFcused_uniq,@PlFchist_key),
								PRICEPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END,@PlPrFcused_uniq,@PlFchist_key),
								EXTENDEDPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
									CASE WHEN @llSoFlat = 1 THEN CASE WHEN @m_amyqty-@m_invqty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END ELSE 0 END
									ELSE @m_amyqty-@m_invqty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC+@m_amortchg ELSE 0.00000 END END
									,@PlPRFcused_uniq,@PlFchist_key)
								WHERE PLUNIQLNK = @lcNewUniqNbrPrice
							END
							-- 12/19/14 VL End}
							
							--UPDATE PricHead SET InvQty = Amyqty
							--	WHERE Uniq_key = @lcSodetUniq_key
							--	AND Category = @lcSodetCategory
								
							--** Not amortization part
							-- Get unique value for PlUniqLnk
							BEGIN
								WHILE (1=1)
								BEGIN
									EXEC sp_GenerateUniqueValue @lcNewUniqNbrPrice OUTPUT
									SELECT @lcChkUniqValue = PlUniqlnk FROM Plprices WHERE PlUniqlnk = @lcNewUniqNbrPrice
									IF (@@ROWCOUNT<>0)
										CONTINUE
									ELSE
										BREAK
								END			
							END	
							-- 12/18/14 VL added SopriceFC and SoExtendedFC							
							INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity, Flat, Extended,
										Taxable, Inv_Link, RecordType, Pl_gl_nbr, PlPriceLnk, Cog_gl_nbr, PlUniqlnk, PRICEFC, EXTENDEDFC)
							VALUES (@PlPacklistno, @PlUniqueln, @lcSoDescriptio, CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END,
									---11/05/20 YS find the qty after applying amortization
									---@m_invqty+@PlShippedQty-@m_amyqty, 
									@PlShippedQty-(@m_amyqty-@m_invqty),
									@llSoFlat, 
									CASE WHEN @llSoFlat = 1 THEN 
										CASE WHEN @PlShippedQty <> 0 THEN 
											CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END 
										ELSE 0 END
									--11/05/20 YS calculate correct qty after amortization
									---ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END END,
									ELSE @PlShippedQty-(@m_amyqty-@m_invqty) * CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END END,
									@llSoTaxable, @PlInv_link, @lcSoRecordType, @lcSoPl_gl_nbr, @lcSoPlpricelnk, @lcSoCog_gl_nbr, @lcNewUniqNbrPrice,
									CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,
									CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END)
									
							-- [12/19/14 VL Added code to update Plprices.price and extended by converting pricefc and extendedfc
							IF @lFCInstalled = 1
							BEGIN
							-- 10/05/16 VL added 4th @PlFuncFcused_uniq as 4th basecurkey parameter and added for PricePR and ExtendedPR convert from PriceFC and Extended
							UPDATE PLPRICES SET 
								PRICE = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,@PlFuncFcused_uniq,@PlFchist_key),
								EXTENDED = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
								--11/05/20 YS calculate correct qty after amortization
									---CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
									CASE WHEN @llSoFlat = 1 THEN 
										CASE WHEN @PlShippedQty-(@m_amyqty-@m_invqty) <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty-(@m_amyqty-@m_invqty) * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END
									,@PlFuncFcused_uniq,@PlFchist_key),
								PRICEPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,@PlPRFcused_uniq,@PlFchist_key),
								EXTENDEDPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
									CASE WHEN @llSoFlat = 1 THEN 
									--11/05/20 YS calculate correct qty after amortization
									CASE WHEN @PlShippedQty-(@m_amyqty-@m_invqty) <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty-(@m_amyqty-@m_invqty) * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END
									,@PlPRFcused_uniq,@PlFchist_key)
								WHERE PLUNIQLNK = @lcNewUniqNbrPrice
							END
							-- 12/19/14 VL End}
																
							END								
						END
					ELSE
						BEGIN
						--**	Not find record in Prichead or find but invqty = amyqty
						-- 12/18/14 VL added SopriceFC and SoExtendedFC							
						INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity, Flat, Extended,
									Taxable, Inv_Link, RecordType, Pl_gl_nbr, PlPriceLnk, Cog_gl_nbr, PlUniqlnk, PRICEFC, EXTENDEDFC)
						VALUES (@PlPacklistno, @PlUniqueln, @lcSoDescriptio, CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END,
								@PlShippedQty, @llSoFlat, CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END ELSE 0 END
								ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END END,
								@llSoTaxable, @PlInv_link, @lcSoRecordType, @lcSoPl_gl_nbr, @lcSoPlpricelnk, @lcSoCog_gl_nbr, @lcNewUniqNbrPrice,
								CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,
								CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
								ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END)

							-- [12/19/14 VL Added code to update Plprices.price and extended by converting pricefc and extendedfc
							IF @lFCInstalled = 1
							BEGIN
							-- 10/05/16 VL added 4th @PlFuncFcused_uniq as 4th basecurkey parameter and added for PricePR and ExtendedPR convert from PriceFC and Extended
							UPDATE PLPRICES SET 
								PRICE = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,@PlFuncFcused_uniq,@PlFchist_key),
								EXTENDED = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
									CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END
									,@PlFuncFcused_uniq,@PlFchist_key),
								PRICEPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,@PlPRFcused_uniq,@PlFchist_key),
								EXTENDEDPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
									CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
									ELSE @PlShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END
									,@PlPRFcused_uniq,@PlFchist_key)
								WHERE PLUNIQLNK = @lcNewUniqNbrPrice
							END
							-- 12/19/14 VL End}								
						END		
					END

				ELSE
				/* lcSoRecordType <> 'P'*/
					BEGIN
					SELECT @lnPlpriceQtySum = ISNULL(SUM(Quantity),0)
						FROM Plprices
						WHERE PlpriceLnk = @lcSoPlpricelnk		

					SET @lnDiff = @lnSoQuantity - @lnPlpriceQtySum
					IF @lnDiff <> 0
						BEGIN
						-- 05/23/12 VL added code to consider if @lnDiff become negative because user might decrease @lnSoQuantity
						--SET @lnShippedQty = CASE WHEN @lnDiff < @PlShippedQty THEN @lnDiff ELSE @PlShippedQty END
						SET @lnShippedQty = CASE WHEN @lnDiff < @PlShippedQty THEN 
							CASE WHEN @lnDiff >= 0 THEN @lnDiff ELSE 0 END 
							ELSE @PlShippedQty END

						-- 12/18/14 VL added SopriceFC and SoExtendedFC		
						INSERT INTO Plprices (Packlistno, Uniqueln, Descript, Price, Quantity, Flat, Extended,
									Taxable, Inv_Link, RecordType, Pl_gl_nbr, Plpricelnk, Cog_gl_nbr, PlUniqlnk, PRICEFC, EXTENDEDFC)
						VALUES (@PlPacklistno, @PlUniqueln, @lcSoDescriptio, CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END,
								@lnShippedQty, @llSoFlat, CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END ELSE 0 END
								ELSE @lnShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPrice ELSE 0.00000 END END,
								@llSoTaxable, @PlInv_link, @lcSoRecordType, @lcSoPl_gl_nbr, @lcSoPlpricelnk, @lcSoCog_gl_nbr, @lcNewUniqNbrPrice,
								CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,
								CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
								ELSE @lnShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END)

						-- [12/19/14 VL Added code to update Plprices.price and extended by converting pricefc and extendedfc
						IF @lFCInstalled = 1
						BEGIN
						-- 10/05/16 VL added 4th @PlFuncFcused_uniq as 4th basecurkey parameter and added for PricePR and ExtendedPR convert from PriceFC and Extended
						UPDATE PLPRICES SET 
							PRICE = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,@PlFuncFcused_uniq,@PlFchist_key),
							EXTENDED = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
								CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
								ELSE @lnShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END
								,@PlFuncFcused_uniq,@PlFchist_key),
							PRICEPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END,@PlPRFcused_uniq,@PlFchist_key),
							EXTENDEDPR = dbo.fn_Convert4FCHC('F',@PlFcUsed_uniq,
								CASE WHEN @llSoFlat = 1 THEN CASE WHEN @PlShippedQty <> 0 THEN CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END ELSE 0 END
								ELSE @lnShippedQty * CASE WHEN @llFirstFlat = 1 THEN @lnSoPriceFC ELSE 0.00000 END END
								,@PlPRFcused_uniq,@PlFchist_key)
							WHERE PLUNIQLNK = @lcNewUniqNbrPrice
						END
						-- 12/19/14 VL End}								

						END
					END
				END
			END	-- IF (@@ROWCOUNT<>0)
		END -- SCAN END
		
		-- {12/19/14 VL added to insert PlpricesTax from SopricesTax, if uniqueln = '*' should not need tax??
		-- 02/27/15 VL added 5 logical tax fields
		-- 11/19/20 VL added 4 new tax fields in inserting PlpricesTax
		INSERT PlpricesTax (UniqPlpricesTax, Packlistno, Inv_link, Pluniqlnk, Tax_id, Tax_rate, TaxType, Ptprod, PtFrt, StProd, StFrt, Sttx, 
			SetupTaxType, TaxApplicableTo, IsFreightTotals, IsProductTotal)
		SELECT dbo.fn_GenerateUniqueNumber() AS UniqPlpricesTax, Packlistno, Inv_link, Pluniqlnk, Tax_id, Tax_rate, TaxType, Ptprod, PtFrt, StProd, StFrt, Sttx,
			SetupTaxType, TaxApplicableTo, IsFreightTotals, IsProductTotal
			FROM SopricesTax, Plprices 
			WHERE SopricesTax.Plpricelnk = Plprices.Plpricelnk
			AND Plprices.Taxable = 1
			AND Plprices.Inv_link = @PlInv_link
		-- 12/19/14 VL End}			
	END
		
	EXEC sp_Invoice_Total @PlPacklistno
	COMMIT
	
END





