-- =============================================
-- Modification
-- 03/05/15 VL will get 5 logical tax setting from Invstdtx, not from Shiptax if the pcmType = 'I' and it's not stand alone RMA, also added 5 tax setting into result SQL
-- 03/11/15 VL need to add one more paramter for FC field:@lnLineExtendedFC, also added FC fields
-- 03/20/15 VL added code to combine two 'E' foreign records if Sttx = 1
-- 04/13/16 VL Added IF ((SELECT StTx FROM @pShipTaxTblE)=0) with one more criteria to check the reccount too, in Penang's case they didn't set up secondary tax, so it' will not return 0, it would not retun anything, so changed to <>1
-- 10/31/16 VL added PR fields
-- 03/06/17 VL Remove ROUND() when calculting foreign type 'E' tax when sttx = 1, don't round() for each two record, round at the end
-- =============================================

CREATE PROCEDURE [dbo].[GetForeignTax4OneLine] 
	-- Add the parameters for the stored procedure here
	@lcInvPacklistno as char(10)=' ',   --- original packing list number if RMA create CMmain table will have a different packlistno doubled as rma receiver
	@lnLineExtended as numeric(12,2)=0.00,   --- based on this number calculate the tax
	@lnLineExtendedFC as numeric(12,2)=0.00,   --- based on this number calculate the tax
	@lnLineExtendedPR as numeric(12,2)=0.00,   --- based on this number calculate the tax
	@lcPlUniqLnk as char(10)=' ',  -- link to the original PlPrices record
	--@pIsForeignTax as bit=0,       -- indicate if foreign tax applies -02/21/12 ys removed this parameter will find if foriegn tax here
	@pcmType as char(1)=' ',    -- credit memo type
    @pIsStandAloneRMA as bit=0 ,  -- indicates if RMA is standalone RMA
   --- @gcInv_link as char(10)=' ', no need for this parameter
   -- @pcPackListNo as char(10)=' ',  -- no need to use packing list created by CM
    @pcLinkAdd as char(10)=' ', -- link to shiptax table
    @pcCustno as char(10)=' ',  -- custno
    @lSalesTaxOnly bit=0  -- 02/20/12 ys if sales tax only against invoice just grub records in invstdtx for the amount 
AS
BEGIN
DECLARE @pIsForeignTax bit=0
SELECT @pIsForeignTax =ForeignTax  
		FROM ShipBill 
		WHERE LinkAdd = @pcLinkAdd

IF (@pIsForeignTax=0)
BEGIN
	IF (@pcmType='I' and @pIsStandAloneRMA=0 and @lSalesTaxOnly=0)
  		-- 03/11/15 VL added FC Fields
		-- 10/31/16 VL added PR fields
  		SELECT CAST(1 as bit) AS YesNo,PackListNo,PlUniqLnk,
			@pcLinkAdd AS LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
			Gl_nbr_out,Tax_rate, Tax_type,
			ROUND((@lnLineExtended*Tax_rate/100),2)  AS Tax_amt , ROUND((@lnLineExtendedFC*Tax_rate/100),2)  AS Tax_amtFC, 
			Invstdtx.TXTYPEFORN, PtProd, PtFrt, StProd, StFrt, Sttx, ROUND((@lnLineExtendedPR*Tax_rate/100),2)  AS Tax_amtPR
			FROM Invstdtx 
			WHERE Packlistno = @lcInvPacklistno   
			AND PluniqLnk = @lcPlUniqLnk 
			AND Invoiceno=' '
			AND Tax_Type = 'S' 
	if (@pcmType='I' and @pIsStandAloneRMA=0 and @lSalesTaxOnly=1)	
		--02/20/12 ys  when CM against invoice and cm is for sales tax only @lnLineExtended=0 and @lcPlUniqLnk=' '
		-- 03/11/15 VL added FC Fields
		-- 10/31/16 VL added PR fields
		SELECT CAST(1 as bit) AS YesNo,PackListNo,PlUniqLnk,
			@pcLinkAdd AS LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
			Gl_nbr_out,Tax_rate, Tax_type,
			Invstdtx.Tax_amt, Invstdtx.Tax_amtFC, Invstdtx.TXTYPEFORN, PtProd, PtFrt, StProd, StFrt, Sttx, Invstdtx.Tax_amtPR 
			FROM Invstdtx 
			WHERE Packlistno = @lcInvPacklistno   
			AND Invoiceno=' '
			AND Tax_Type = 'S' 
		
	IF (@pcmType='M' OR @pIsStandAloneRMA=1)
		-- This is a standalone RMA or @pcmType='M'
		-- 04/03/07 VL added ROUND(), it caused 1 cent difference
		-- 03/11/15 VL added FC Fields
		-- 10/31/16 VL added PR fields
		SELECT CAST(1 as bit) AS YesNo,@lcInvPacklistno AS PackListNo,@lcPlUniqLnk AS PlUniqLnk,
			ShipTax.LinkAdd,ShipTax.Tax_id,TaxTabl.TaxDesc,TaxTabl.Gl_nbr_in,
			TaxTabl.Gl_nbr_out,ShipTax.Tax_rate,'S' AS Tax_type,
			ROUND((@lnLineExtended*ShipTax.Tax_rate/100),2) AS Tax_amt, ROUND((@lnLineExtendedFC*ShipTax.Tax_rate/100),2) AS Tax_amtFC, 
			' ' as TXTYPEFORN, ShipTax.PtProd, ShipTax.PtFrt, ShipTax.StProd, ShipTax.StFrt, ShipTax.Sttx,
			ROUND((@lnLineExtendedPR*ShipTax.Tax_rate/100),2) AS Tax_amtPR
			FROM ShipTax,TaxTabl
			WHERE ShipTax.LinkAdd=@pcLinkAdd AND ShipTax.Custno=@pcCustno
			AND ShipTax.TaxType='S' AND RecordType='S'
			AND ShipTax.Tax_id=TaxTabl.Tax_id
			

  --END	-- @pcmType='I' and @pIsStandAloneRMA=0
END -- (@pIsForeignTax=0)
ELSE -- (@pIsForeignTax=0)
BEGIN
	-- @pisForeignTax=1
	-- 04/25/07 VL found if the credit memo is from invoice, the credit memo sales tax has to be the same as invoice ;
	--				sales tax, so no need to find current tax rate, just use invoice tax amount, if cmtype= "M", then calculate tax from current setup
	-- 09/18/07 VL added one more criteria because now change Cmtype back to "I" even the RMA is stand alone RMA
	-- 05/08/07 VL use @lcInvPacklistno intead of @pcPacklistno because if the CM is created from RMA receiver, the packlistno is the RMA receiverno, not original PK no
	-- 05/18/07 VL realized forgot to consider those 5 checkbox to calculate the StTx tax
	DECLARE @pShipTaxTblE as Table (PtProd bit,StProd bit ,StTx bit,PtFrt bit,StFrt bit,Tax_Rate numeric(8,4),TaxType char(1),Tax_id char(8))
	-- 04/13/16 VL added to save the recount count of @pShipTaxTblE
	DECLARE @ShipTaxTblECnt int

	-- 03/05/15 VL changed, if @pCmType = 'I' AND @pIsStandAloneRMA=0, will insert @pShipTaxTblE from Invstdtx which has original tax setting, otherwise, still from fn_ShipTaxForeignView
	BEGIN
	IF @pcmType = 'I' AND @pIsStandAloneRMA=0 
		BEGIN
			INSERT INTO @pShipTaxTblE SELECT TOP 1 PtProd,StProd,StTx,PtFrt,StFrt,Tax_Rate, TxTypeForn AS Taxtype,Tax_id
				FROM Invstdtx 
				WHERE Packlistno = @lcInvPacklistno   
				AND Invoiceno=' '
				AND Tax_Type = 'S' 
				AND TxTypeForn = 'E'
				ORDER BY Packlistno
			-- 04/13/16 VL saves the reccount 
			SET @ShipTaxTblECnt = @@ROWCOUNT
		END
	ELSE
		BEGIN
			--03/08/12 YS use table-valued function (inline function)
			INSERT INTO @pShipTaxTblE SELECT * FROM fn_ShipTaxForeignView(@pcCustno,'E',@pcLinkAdd)
			--INSERT INTO  @pShipTaxTblE EXEC ShipTaxForeignView @pcCustno,'E',@pcLinkAdd
			-- 04/13/16 VL saves the reccount 
			SET @ShipTaxTblECnt = @@ROWCOUNT
		END
	END		
	-- 03/05/15 VL End}

	DECLARE @pShipTaxTblP as Table (PtProd bit,StProd bit ,StTx bit,PtFrt bit,StFrt bit,Tax_Rate numeric(8,4),TaxType char(1),TAX_id char(8))
	
	-- 03/05/15 VL changed, if @pCmType = 'I' AND @pIsStandAloneRMA=0, will insert @pShipTaxTblE from Invstdtx which has original tax setting, otherwise, still from fn_ShipTaxForeignView
	BEGIN
	IF @pcmType = 'I' AND @pIsStandAloneRMA=0 
		BEGIN
			INSERT INTO @pShipTaxTblP SELECT TOP 1 PtProd,StProd,StTx,PtFrt,StFrt,Tax_Rate, TxTypeForn AS Taxtype,Tax_id
				FROM Invstdtx 
				WHERE Packlistno = @lcInvPacklistno   
				AND Invoiceno=' '
				AND Tax_Type = 'S' 
				AND TxTypeForn = 'P'
				ORDER BY Packlistno
		END
	ELSE
		BEGIN
			--03/08/12 YS use table-valued function (inline function)
			INSERT INTO @pShipTaxTblP SELECT * FROM fn_ShipTaxForeignView(@pcCustno,'P',@pcLinkAdd)
			--INSERT INTO  @pShipTaxTblP EXEC ShipTaxForeignView @pcCustno,'P',@pcLinkAdd
		END
	END		
	-- 03/05/15 VL End}
		
	IF (@pcmType = 'I' AND @pIsStandAloneRMA=0 and @lSalesTaxOnly=0)	-- so it's not stand alone RMA, it's associated with invoice 02/20/12 ys and not just for sales tax only
	BEGIN
		-- 04/13/16 VL Changed IF ((SELECT StTx FROM @pShipTaxTblE)=0) with one more reccount criteria, in Penang's case they didn't set up secondary tax, so it' will not return 0, it would not retun anything, so changed to <>1	
		--IF ((SELECT StTx FROM @pShipTaxTblE)=0)  -- no secondary tax applied to the primary tax
		IF ((SELECT StTx FROM @pShipTaxTblE)=0) OR @ShipTaxTblECnt = 0 -- no secondary tax applied to the primary tax			
		BEGIN	
			-- 05/31/07 VL found only can take for that item, so added PluniqLnk = ZPL_PluniqLnk.PluniqLnk criteria		
			-- 07/10/07 VL found that if the invoice has credit memo created before, then next SQL will get multiple records, should filter out records from credit memo: EMPTY(Invoiceno)
			--02/20/12 ys  when CM against invoice and cm is for sales tax only @lnLineExtended=0 and @lcPlUniqLnk=' '
			-- 03/05/15 VL changed, don't need to use @pShipTaxTblP and @pShipTaxTblE, because now 5 logical tax setting are saved in Invstdtx
			--SELECT CAST(1 as bit) AS YesNo,PackListNo,PlUniqLnk,
			--	@pcLinkAdd AS LinkAdd,Invstdtx.TAX_ID,TaxDesc,Gl_nbr_in,Gl_nbr_out,InvStdtx.Tax_rate, InvStdtx.Tax_type,
			--	case when @lnLineExtended<>0.00 then ROUND((@lnLineExtended*InvStdtx.Tax_rate/100),2) else Invstdtx.TAX_AMT end AS Tax_amt, TxTypeForn
			--	FROM Invstdtx CROSS JOIN @pShipTaxTblP P
			--		CROSS JOIN @pShipTaxTblE E
			--	WHERE Packlistno = @lcInvPacklistno 
			--	AND PluniqLnk = case when @lcPlUniqLnk<>' ' then @lcPlUniqLnk else INVSTDTX.PLUNIQLNK end 
			--	AND Invoiceno=' '
			--	AND Tax_Type = 'S' 
			--	AND ((TxTypeForn = 'P' AND TxTypeForn =P.TaxType AND P.PtProd=1) 
			--	OR (TxTypeForn = 'E' AND TxTypeForn =E.TaxType AND  E.StProd=1)) 

			-- 03/11/15 VL added FC Fields
			-- 10/31/16 VL added PR fields
			SELECT CAST(1 as bit) AS YesNo,PackListNo,PlUniqLnk,
				@pcLinkAdd AS LinkAdd,Invstdtx.TAX_ID,TaxDesc,Gl_nbr_in,Gl_nbr_out,InvStdtx.Tax_rate, InvStdtx.Tax_type,
				case when @lnLineExtended<>0.00 then ROUND((@lnLineExtended*InvStdtx.Tax_rate/100),2) else Invstdtx.TAX_AMT end AS Tax_amt, 
				case when @lnLineExtendedFC<>0.00 then ROUND((@lnLineExtendedFC*InvStdtx.Tax_rate/100),2) else Invstdtx.TAX_AMTFC end AS Tax_amtFC, 
				TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx,
				case when @lnLineExtendedPR<>0.00 then ROUND((@lnLineExtendedPR*InvStdtx.Tax_rate/100),2) else Invstdtx.TAX_AMTPR end AS Tax_amtPR
				FROM Invstdtx
				WHERE Packlistno = @lcInvPacklistno 
				AND PluniqLnk = case when @lcPlUniqLnk<>' ' then @lcPlUniqLnk else INVSTDTX.PLUNIQLNK end 
				AND Invoiceno=' '
				AND Tax_Type = 'S' 
				AND ((TxTypeForn = 'P' AND PtProd=1) 
				OR (TxTypeForn = 'E' AND StProd=1)) 



		END		-- ((SELECT StTx FROM @pShipTaxTblE)=0)	
		ELSE -- ((SELECT StTx FROM @pShipTaxTblE)=0)
		BEGIN	
			-- Has Secondary tax set up and StTx = .T., has to get primary tax first, then use it to calcualte with 2nd tax
			-- Get primary tax first
			-- 05/31/07 VL has to get original invoice PlUniqLnk to get onle correct invstdtx records
			
			-- 04/03/07 VL added ROUND(), it caused 1 cent difference
			-- 05/31/07 VL found only can take for that item, so added PluniqLnk = ZPL_PluniqLnk.PluniqLnk criteria
			-- 07/10/07 VL found that if the invoice has credit memo created before, then next SQL will get multiple records, should filter out records from credit memo: EMPTY(Invoiceno)
			
			WITH zTaxInfo AS 
			(
			--02/20/12 ys  when CM against invoice and cm is for sales tax only @lnLineExtended=0 and @lcPlUniqLnk=' '
			-- 03/05/15 VL changed, don't need to use @pShipTaxTblP and @pShipTaxTblE, because now 5 logical tax setting are saved in Invstdtx
			--SELECT CAST(1 as bit) AS YesNo,PackListNo,PlUniqLnk,
			--	@pcLinkAdd AS LinkAdd,Invstdtx.Tax_id,TaxDesc,Gl_nbr_in,Gl_nbr_out,Invstdtx.TAX_RATE,'S' AS Tax_type,
			--	ROUND((@lnLineExtended*Invstdtx.TAX_RATE/100),2) AS Tax_amt, TxTypeForn 
			--	FROM Invstdtx CROSS JOIN @pShipTaxTblP P
			--	WHERE Packlistno = @lcInvPacklistno 
			--	AND PluniqLnk = @lcPlUniqLnk
			--	AND Invoiceno=' '
			--	AND Invstdtx.Tax_Type = 'S'
			--	AND TxTypeForn = 'P'	
			--	AND TxTypeForn =P.Taxtype AND P.PtProd =1
			-- 03/11/15 VL added FC Fields
			-- 10/31/16 VL added PR fields
			SELECT CAST(1 as bit) AS YesNo,PackListNo,PlUniqLnk,
				@pcLinkAdd AS LinkAdd,Invstdtx.Tax_id,TaxDesc,Gl_nbr_in,Gl_nbr_out,Invstdtx.TAX_RATE,'S' AS Tax_type,
				ROUND((@lnLineExtended*Invstdtx.TAX_RATE/100),2) AS Tax_amt, ROUND((@lnLineExtendedFC*Invstdtx.TAX_RATE/100),2) AS Tax_amtFC, 
				TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, ROUND((@lnLineExtendedPR*Invstdtx.TAX_RATE/100),2) AS Tax_amtPR
				FROM Invstdtx
				WHERE Packlistno = @lcInvPacklistno 
				AND PluniqLnk = @lcPlUniqLnk
				AND Invoiceno=' '
				AND Invstdtx.Tax_Type = 'S'
				AND TxTypeForn = 'P'	
				AND PtProd =1
				)
	
			--INTO CURSOR ZtaxInfo READWRITE
			-- Secondary tax
			-- 04/03/07 VL added ROUND(), it caused 1 cent difference
			-- 05/31/07 VL found only can take for that item, so added PluniqLnk = ZPL_PluniqLnk.PluniqLnk criteria
			-- 07/10/07 VL found that if the invoice has credit memo created before, then next SQL will get multiple records, should filter out records from credit memo: EMPTY(Invoiceno)
			-- 03/05/15 VL changed, don't need to use @pShipTaxTblP and @pShipTaxTblE, because now 5 logical tax setting are saved in Invstdtx
			--SELECT CAST(1 as Bit) AS YesNo,PackListNo,PlUniqLnk,
			--	@pcLinkAdd AS LinkAdd,Invstdtx.TAX_ID,TaxDesc,Gl_nbr_in,Gl_nbr_out,Invstdtx.TAX_RATE,'S' AS Tax_type,
			--	ROUND((@lnLineExtended*Invstdtx.TAX_RATE/100),2) AS Tax_amt, TxTypeForn 
			--	FROM Invstdtx CROSS JOIN @pShipTaxTblE E
			--	WHERE Packlistno = @lcInvPacklistno 
			--	AND PluniqLnk = @lcPlUniqLnk
			--	AND Invoiceno=' '
			--	AND Tax_Type = 'S'
			--	AND TxTypeForn = 'E'
			--	AND TxTypeForn=	E.TaxType				
			--	AND E.StProd =1		
			--UNION ALL 
			--	SELECT CAST(1 as bit)AS YesNo,Invstdtx.PackListNo,Invstdtx.PlUniqLnk,
			--	@pcLinkAdd AS LinkAdd,Invstdtx.TAX_ID,Invstdtx.TAXDESC,Invstdtx.GL_NBR_IN,Invstdtx.GL_NBR_OUT,Invstdtx.TAX_RATE,'S' AS Tax_type,
			--	ROUND(((@lnLineExtended*Invstdtx.TAX_RATE/100)*(z.Tax_rate/100)),2) AS Tax_amt, Invstdtx.TXTYPEFORN
			--	FROM Invstdtx CROSS JOIN @pShipTaxTblE E
			--		CROSS JOIN zTaxInfo Z
			--	WHERE Invstdtx.Packlistno = @lcInvPacklistno 
			--	AND Invstdtx.PluniqLnk =@lcPlUniqLnk
			--	AND Invstdtx.Invoiceno=' '
			--	AND Invstdtx.Tax_Type = 'S'
			--	AND Invstdtx.TxTypeForn = 'E'	
			--	AND Invstdtx.TxTypeForn=E.TaxType
			--	AND E.Sttx = 1
			--UNION ALL
			--SELECT YesNo,PackListNo,PlUniqLnk,LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,Gl_nbr_out,Tax_rate, Tax_type,
			-- Tax_amt, TxTypeForn FROM zTaxInfo
			-- 03/05/15 VL start new code 
			-- 03/11/15 VL added FC Fields
			, ZForeignTaxDetail AS
			(
			-- 10/31/16 VL added PR fields
			-- 03/06/17 VL remove the ROUND() here and ROUND at final SQL to work the same as SO and Invoice
			SELECT CAST(1 as Bit) AS YesNo,PackListNo,PlUniqLnk,
				@pcLinkAdd AS LinkAdd,Invstdtx.TAX_ID,TaxDesc,Gl_nbr_in,Gl_nbr_out,Invstdtx.TAX_RATE,'S' AS Tax_type,
				--ROUND((@lnLineExtended*Invstdtx.TAX_RATE/100),2) AS Tax_amt, ROUND((@lnLineExtendedFC*Invstdtx.TAX_RATE/100),2) AS Tax_amtFC, 
				(@lnLineExtended*Invstdtx.TAX_RATE/100) AS Tax_amt, (@lnLineExtendedFC*Invstdtx.TAX_RATE/100) AS Tax_amtFC, 
				TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, --ROUND((@lnLineExtendedPR*Invstdtx.TAX_RATE/100),2) AS Tax_amtPR
				(@lnLineExtendedPR*Invstdtx.TAX_RATE/100) AS Tax_amtPR
				FROM Invstdtx
				WHERE Packlistno = @lcInvPacklistno 
				AND PluniqLnk = @lcPlUniqLnk
				AND Invoiceno=' '
				AND Tax_Type = 'S'
				AND TxTypeForn = 'E'
				AND StProd =1		
			UNION ALL 
				-- 10/31/16 VL added PR fields
				-- 03/06/17 VL remove the ROUND() here and ROUND at final SQL to work the same as SO and Invoice
				SELECT CAST(1 as bit)AS YesNo,Invstdtx.PackListNo,Invstdtx.PlUniqLnk,
				@pcLinkAdd AS LinkAdd,Invstdtx.TAX_ID,Invstdtx.TAXDESC,Invstdtx.GL_NBR_IN,Invstdtx.GL_NBR_OUT,Invstdtx.TAX_RATE,'S' AS Tax_type,
				--ROUND(((@lnLineExtended*Invstdtx.TAX_RATE/100)*(z.Tax_rate/100)),2) AS Tax_amt, 
				--ROUND(((@lnLineExtendedFC*Invstdtx.TAX_RATE/100)*(z.Tax_rate/100)),2) AS Tax_amtFC, 
				((@lnLineExtended*Invstdtx.TAX_RATE/100)*(z.Tax_rate/100)) AS Tax_amt, 
				((@lnLineExtendedFC*Invstdtx.TAX_RATE/100)*(z.Tax_rate/100)) AS Tax_amtFC, 
				Invstdtx.TXTYPEFORN, Invstdtx.PtProd, Invstdtx.PtFrt, 
				Invstdtx.StProd, Invstdtx.StFrt, Invstdtx.Sttx, 
				--ROUND(((@lnLineExtendedPR*Invstdtx.TAX_RATE/100)*(z.Tax_rate/100)),2) AS Tax_amtPR
				((@lnLineExtendedPR*Invstdtx.TAX_RATE/100)*(z.Tax_rate/100)) AS Tax_amtPR
				FROM Invstdtx CROSS JOIN zTaxInfo Z
				WHERE Invstdtx.Packlistno = @lcInvPacklistno 
				AND Invstdtx.PluniqLnk =@lcPlUniqLnk
				AND Invstdtx.Invoiceno=' '
				AND Invstdtx.Tax_Type = 'S'
				AND Invstdtx.TxTypeForn = 'E'	
				AND Invstdtx.Sttx = 1
			UNION ALL
			-- 10/31/16 VL added PR fields
			SELECT YesNo,PackListNo,PlUniqLnk,LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,Gl_nbr_out,Tax_rate, Tax_type,
			 Tax_amt, Tax_amtFC, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, Tax_amtPR FROM zTaxInfo)

			-- 03/20/15 VL tried to combine two type 'E' records into one
			-- 10/31/16 VL added PR fields
			-- 03/06/17 VL added ROUND at final SQL ( for the type 'E' with STtx=1)
			SELECT YesNo, Packlistno, Pluniqlnk, Linkadd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_type, 
				ROUND(ISNULL(SUM(Tax_amt),0),2) AS Tax_amt, ROUND(ISNULL(SUM(Tax_amtFC),0),2) AS Tax_amtFC, 
					TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, ROUND(ISNULL(SUM(Tax_amtPR),0),2) AS Tax_amtPR
				FROM ZForeignTaxDetail
				GROUP BY YesNo, Packlistno, Pluniqlnk, Linkadd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_type, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx

		END -- else ((SELECT StTx FROM @pShipTaxTblE)=0)
	END -- if @pcmType = 'I' AND @pIsStandAloneRMA=0 
	-- 02/20/12 ys if sales tax only just find appropriate records in the invstdtx 
	IF (@pcmType = 'I' AND @pIsStandAloneRMA=0 and @lSalesTaxOnly=1)	-- 02/20/12 ys s it's not stand alone RMA, it's associated with invoice  and not just for sales tax only 
	BEGIN
		--02/20/12 ys  when CM against invoice and cm is for sales tax only @lnLineExtended=0 and @lcPlUniqLnk=' '
		-- 03/11/15 VL added FC Fields
		-- 10/31/16 VL added PR fields
		SELECT CAST(1 as bit) AS YesNo,PackListNo,PlUniqLnk,
			@pcLinkAdd AS LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
			Gl_nbr_out,Tax_rate, Tax_type,
			Invstdtx.Tax_amt, Invstdtx.Tax_amtFC, Invstdtx.TXTYPEFORN, PtProd, PtFrt, StProd, StFrt, Sttx, Invstdtx.Tax_amtPR
			FROM Invstdtx 
			WHERE Packlistno = @lcInvPacklistno   
			AND Invoiceno=' '
			AND Tax_Type = 'S' 
	
	END -- IF (@pcmType = 'I' AND @pIsStandAloneRMA=0 and @lSalesTaxOnly=1)
	IF (@pcmType = 'M' OR @pIsStandAloneRMA=1) 	
	-- This is a standalone RMA or @pcmType='M'
	BEGIN	
		IF (SELECT StTx	FROM @pShipTaxTblE)=0 -- No secondary tax set up or Sttx is .F.
			-- 03/13/07 VL added TxTypeForn for tax type of foreign tax
			-- 04/03/07 VL added ROUND(), it caused 1 cent difference
			-- 03/11/15 VL added FC Fields
			-- 10/31/16 VL added PR fields
			-- 03/06/17 VL remove the ROUND() here and ROUND at final SQL to work the same as SO and Invoice
			SELECT CAST(1 as bit) AS YesNo,@lcInvPacklistno AS PackListNo,@lcPlUniqLnk AS PlUniqLnk,
				@pcLinkAdd AS LinkAdd,E.Tax_id,TaxTabl.TaxDesc,TaxTabl.Gl_nbr_in,
				TaxTabl.Gl_nbr_out,E.Tax_rate,'S' AS Tax_type,
				ROUND((@lnLineExtended*E.Tax_rate/100),2) AS Tax_amt, ROUND((@lnLineExtendedFC*E.Tax_rate/100),2) AS Tax_amtFC, 
				E.Taxtype AS TxTypeForn, E.PtProd, E.PtFrt, E.StProd, E.StFrt, E.Sttx,
				ROUND((@lnLineExtendedPR*E.Tax_rate/100),2) AS Tax_amtPR 
				FROM @pShipTaxTblE E,TaxTabl
				WHERE E.Stprod=1
				AND E.Tax_id=TaxTabl.Tax_id
			UNION ALL
				-- 10/31/16 VL added PR fields
				SELECT CAST(1 as bit) AS YesNo,@lcInvPacklistno AS PackListNo,@lcPlUniqLnk AS PlUniqLnk,
				@pcLinkAdd AS LinkAdd,P.Tax_id ,TaxTabl.TaxDesc,TaxTabl.Gl_nbr_in,
				TaxTabl.Gl_nbr_out,P.Tax_rate,'S' AS Tax_type,
				ROUND((@lnLineExtended*P.Tax_rate/100),2) AS Tax_amt, ROUND((@lnLineExtendedFC*P.Tax_rate/100),2) AS Tax_amtFC, 
				P.Taxtype AS TxTypeForn, P.PtProd, P.PtFrt, P.StProd, P.StFrt, P.Sttx,
				ROUND((@lnLineExtendedPR*P.Tax_rate/100),2) AS Tax_amtPR
				FROM @pShipTaxTblP P,TaxTabl
				WHERE P.PtProd=1
				AND P.Tax_id=TaxTabl.Tax_id
		ELSE --(SELECT StTx	FROM @pShipTaxTblE)=0 
		BEGIN
			-- Get primary tax first
			-- 04/03/07 VL added ROUND(), it caused 1 cent difference
			-- 03/11/15 VL added FC Fields
			-- 10/31/16 VL added PR fields
			WITH zTaxInfo AS 
			(
			SELECT CAST(1 as bit) AS YesNo,@lcInvPacklistno AS PackListNo,@lcPlUniqLnk AS PlUniqLnk,
				@pcLinkAdd AS LinkAdd,P.Tax_id,TaxTabl.TaxDesc,TaxTabl.Gl_nbr_in,
				TaxTabl.Gl_nbr_out,P.Tax_rate,'S' AS Tax_type,
				ROUND((@lnLineExtended*P.Tax_rate/100),2) AS Tax_amt, ROUND((@lnLineExtendedFC*P.Tax_rate/100),2) AS Tax_amtFC, 
				P.Taxtype AS TxTypeForn, P.PtProd, P.PtFrt, P.StProd, P.StFrt, P.Sttx,
				ROUND((@lnLineExtendedPR*P.Tax_rate/100),2) AS Tax_amtPR 
				FROM @pShipTaxTblP P,TaxTabl
				WHERE P.Tax_id=TaxTabl.Tax_id
				AND P.PtProd=1
			),	
			--Secondary tax
			--** 04/03/07 VL added ROUND(), it caused 1 cent difference
			-- 03/11/15 VL added FC Fields
			-- 10/31/16 VL added PR fields
			ZForeignTaxDetail AS
			(
			-- 03/06/17 VL remove the ROUND() here and ROUND at final SQL to work the same as SO and Invoice
			SELECT CAST(1 AS bit) as YesNo,@lcInvPacklistno AS PackListNo,@lcPlUniqLnk AS PlUniqLnk,
					@pcLinkAdd AS LinkAdd,E.Tax_id,TaxTabl.TaxDesc,TaxTabl.Gl_nbr_in,
					TaxTabl.Gl_nbr_out,E.Tax_rate,'S' AS Tax_type,
					--ROUND((@lnLineExtended*E.Tax_rate/100),2) AS Tax_amt, ROUND((@lnLineExtendedFC*E.Tax_rate/100),2) AS Tax_amtFC, 
					(@lnLineExtended*E.Tax_rate/100) AS Tax_amt, (@lnLineExtendedFC*E.Tax_rate/100) AS Tax_amtFC, 
					E.Taxtype AS TxTypeForn, E.PtProd, E.PtFrt, E.StProd, E.StFrt, E.Sttx,
					--ROUND((@lnLineExtendedPR*E.Tax_rate/100),2) AS Tax_amtPR 
					(@lnLineExtendedPR*E.Tax_rate/100) AS Tax_amtPR 
					FROM @pShipTaxTblE E,TaxTabl
					WHERE E.StProd =1
					AND E.Tax_id=TaxTabl.Tax_id
				UNION ALL 
				-- 10/31/16 VL added PR fields
				-- 03/06/17 VL remove the ROUND() here and ROUND at final SQL to work the same as SO and Invoice
				SELECT CAST( 1 as bit) AS YesNo,@lcInvPacklistno AS PackListNo,@lcPlUniqLnk AS PlUniqLnk,
					@pcLinkAdd AS LinkAdd,E.Tax_id,TaxTabl.TaxDesc,TaxTabl.Gl_nbr_in,
					TaxTabl.Gl_nbr_out,E.Tax_rate,'S' AS Tax_type,
					--ROUND(((@lnLineExtended*E.Tax_rate/100)*(Z.Tax_Rate/100)),2) AS Tax_amt, 
					--ROUND(((@lnLineExtendedFC*E.Tax_rate/100)*(Z.Tax_Rate/100)),2) AS Tax_amtFC, 
					((@lnLineExtended*E.Tax_rate/100)*(Z.Tax_Rate/100)) AS Tax_amt, 
					((@lnLineExtendedFC*E.Tax_rate/100)*(Z.Tax_Rate/100)) AS Tax_amtFC, 
					E.Taxtype AS TxTypeForn, E.PtProd, E.PtFrt, E.StProd, E.StFrt, E.Sttx,
					--ROUND(((@lnLineExtendedPR*E.Tax_rate/100)*(Z.Tax_Rate/100)),2) AS Tax_amtPR 
					((@lnLineExtendedPR*E.Tax_rate/100)*(Z.Tax_Rate/100)) AS Tax_amtPR 
					FROM @pShipTaxTblE E,TaxTabl CROSS JOIN zTaxInfo Z
					WHERE E.StTx = 1
					AND E.Tax_id=TaxTabl.Tax_id
				UNION ALL 	
				-- 10/31/16 VL added PR fields
				SELECT YesNo,PackListNo,PlUniqLnk,LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
					Gl_nbr_out,Tax_rate,'S' AS Tax_type,Tax_amt, Tax_amtFC, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, Tax_amtPR 
				FROM zTaxInfo
			)
			-- 03/20/15 VL tried to combine two type 'E' records into one
			-- 10/31/16 VL added PR fields
			-- 03/06/17 VL added ROUND at final SQL
			SELECT YesNo, Packlistno, Pluniqlnk, Linkadd, Tax_id, TaxDesc,Gl_nbr_in,
				Gl_nbr_out,Tax_rate, Tax_type, ROUND(ISNULL(SUM(Tax_amt),0),2) AS Tax_amt, ROUND(ISNULL(SUM(Tax_amtFC),0),2) AS Tax_amtFC, 
					TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, ISNULL(SUM(Tax_amtPR),0) AS Tax_amtPR
				FROM ZForeignTaxDetail
				GROUP BY YesNo, Packlistno, Pluniqlnk, Linkadd, Tax_id, TaxDesc,Gl_nbr_in,Gl_nbr_out,Tax_rate,Tax_type, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx
		END	----(SELECT StTx	FROM @pShipTaxTblE)=0 
	
	END -- -- else @pcmType = 'I' AND @pIsStandAloneRMA=0 
	
END -- (@pIsForeignTax=0)	

END