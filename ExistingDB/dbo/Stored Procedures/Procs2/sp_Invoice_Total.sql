-- =============================================
-- Author:		Vicky Lu
-- Create date: 2010/08/02
-- Description:	Recalculate Invoice and update invoice total
-- Modification:
-- 05/29/12 VL changed all tax from numeric(17,2) to (17,5) so the rounding won't cause $0.01 difference (to work the same as CM)
-- 05/30/12 VL found if @llForeignSttx = 1, then the @lnMFPTax already got rounded, will get another variable to keep the not rounded value
-- 04/19/13 VL Comment out code that revert changes if no Plprices is found, if user has only one plprices and delete it, still need to re-calculate invoice total, 
--				also, no need to update Invstdtx.pluniqlnk field if it's shipping tax
-- 12/22/14 VL added FC and GST code
-- 01/06/15 VL Added to update FC fiels with 0 if FC is not installed
-- 02/27/15 VL Now Plpricestax has 5 logical tax fields will use itself to calculate tax with setting
-- 04/08/16 VL Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0	
-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
-- 10/05/16 VL Added presentation currency code
-- 11/19/20 VL Change tax calculation for new tax in cube
-- =============================================
CREATE PROCEDURE [dbo].[sp_Invoice_Total] @lcPacklistno AS char(10) = '', @llUpdateFromSo AS bit = 0
AS
BEGIN


-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
-- Declare variables
--12/22/14 VL added FC and GST fields
-- 03/20/15 VL added @lnMSPTaxNoRound and @lnMSPTaxFCNoRound to avoid multiple rounding
-- 10/05/16 VL added presentation fields
-- 11/19/20 VL Added 4 new fields for new tax
DECLARE @lnTotExten numeric(20,2), @lcSLinkAdd char(10), @llForeignTax bit, @lnTotalNo int, @lnCount int,
		@lnPlpricesExtended numeric(20,2), @llPlpricesTaxable bit, @llPlpricesFlat bit, @llPlpricesPlUniqLnk char(10),
		@lnTotalNo2 int, @lnCount2 int, @lcTxTax_id char(8), @lcTxTaxDesc char(25), @lcTxGl_nbr_in char(13), 
		@lcTxGl_nbr_out char(13), @lnTxTax_rate numeric(8,4), @lcTxTaxtype char(1), @llTxPtProd bit, @llTxPtfrt bit, 
		@llTxStprod bit, @llTxStFrt bit, @llTxStTx bit, @lnSalesDiscount numeric(5,2), @lcCustno char(10), 
		@lnTotalNo3 int, @lnCount3 int, @llForeignSttx bit, @lnForeignTax_rate numeric(8,4), @lcForeignTax_id char(8),
		@lcForeignTaxtype char(1), @lcForeignGl_nbr_in char(13), @lcForeignGl_nbr_out char(13), @lcForeignTaxDesc char(25), 
		@lcNewUniqNbr char(10), @lcChkUniqValue char(10), @lnmPTax numeric(17,5), @lnmSTax numeric(17,5), 
		@lnmSPTaxt numeric(17,5), @lnmSSTaxt numeric(17,5), @lnmFPTax numeric(17,5), @lnmFSTax numeric(17,5), 
		@lnMsPtax numeric(17,5), @lnMsStax numeric(17,5), @lnMTax numeric(17,5), @lnTotalNo4 int, @lnCount4 int,
		@lnFreightAmt numeric(10,2), @lnmFright_Tax numeric(17,5), @lnTotalNo5 int, @lnCount5 int, 
		@lnDsctamt numeric(17,2), @lnInvTotal numeric(20,2), @lcInvoiceno char(10), @lnTotaltax numeric(17,5), @lnmPTaxNoRound numeric(17,5),
		@lnTotExtenFC numeric(20,2), @lnPlpricesExtendedFC numeric(20,2), @lnTableVarCnt int, @lnMTaxFC numeric(17,5), @lnMSPTaxFC numeric(17,5),
		@lnMSSTaxFC numeric(17,5), @lnMSPTaxTFC numeric(17,5), @lnMSSTaxTFC numeric(17,5), @lnTotaltaxFC numeric(17,5), @lnmFright_TaxFC numeric(17,5),
		@lnFreightAmtFC numeric(17,5), @lnMFPTaxFC numeric(17,5),@lnmPTaxNoRoundFC numeric(17,5), @lnMFSTaxFC numeric(17,5), @lnInvTotalFC numeric(20,2),
		@lnDsctamtFC numeric(17,2), @lnMPTaxFC numeric(17,5), @lnMSTaxFC numeric(17,5), @lnForeignETaxRate numeric(8,4), @lFCInstalled bit,
		@llForeignPtProd bit, @llForeignPtFrt bit, @llForeignStProd bit, @llForeignStFrt bit, @lnMSPTaxNoRound numeric(17,5), @lnMSPTaxFCNoRound numeric(17,5),
		@lnMSSTaxNoRound numeric(17,5), @lnMSSTaxFCNoRound numeric(17,5), @lnMFSTaxNoRound numeric(17,5), @lnMFSTaxFCNoRound numeric(17,5),
		-- 10/05/16 VL added presentation fields
		@lnTotExtenPR numeric(20,2), @lnPlpricesExtendedPR numeric(20,2), @lnMTaxPR numeric(17,5), @lnMSPTaxPR numeric(17,5),
		@lnMSSTaxPR numeric(17,5), @lnMSPTaxTPR numeric(17,5), @lnMSSTaxTPR numeric(17,5), @lnTotaltaxPR numeric(17,5), @lnmFright_TaxPR numeric(17,5),
		@lnFreightAmtPR numeric(17,5), @lnMFPTaxPR numeric(17,5),@lnmPTaxNoRoundPR numeric(17,5), @lnMFSTaxPR numeric(17,5), @lnInvTotalPR numeric(20,2),
		@lnDsctamtPR numeric(17,2), @lnMPTaxPR numeric(17,5), @lnMSTaxPR numeric(17,5), @lnMSPTaxPRNoRound numeric(17,5),
		@lnMSSTaxPRNoRound numeric(17,5), @lnMFSTaxPRNoRound numeric(17,5),
		-- 11/19/20 VL Added 4 new fields for new tax
		@lcSetupTaxType char(15), @lcTaxApplicableTo char(10), @llIsFreightTotals bit, @llIsProductTotal bit, @lnPTaxRate numeric(8,4)

-- 12/22/14 VL added for FC
-- 10/05/16 VL added presentation fields
DECLARE @ZPlprices TABLE (nrecno int identity, Extended numeric (20,2), ExtendedFC numeric(20,2), Taxable bit, Flat bit, PlUniqLnk char(10), ExtendedPR numeric(20,2));
--12/22/14 VL changed nRecno from int identity to just int and update every time in the loop
-- 11/19/20 VL Comment out @ZShipTaxSR because it's comment out, we don't have foreign tax or not foreign tax anymore in cube, I left @ZShipTaxSF to use
--DECLARE @ZShipTaxSR TABLE (Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Taxtype char(1), PtProd bit, Ptfrt bit, Stprod bit, StFrt bit, StTx bit, nrecno int);
-- 11/19/20 VL Added 4 new fields for new tax, this table variable used for item tax
DECLARE @ZShipTaxSF TABLE (Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
						Tax_rate numeric(8,4), Taxtype char(1), PtProd bit, Ptfrt bit, Stprod bit, StFrt bit, StTx bit, 
						SetupTaxType char(15), TaxApplicableTo char(10), IsFreightTotals bit, IsProductTotal bit,
						nrecno int);
-- 11/19/20 VL Added 4 new fields for new tax
DECLARE @ZShipTaxCR TABLE (Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
						Tax_rate numeric(8,4), Taxtype char(1), PtProd bit, Ptfrt bit, Stprod bit, StFrt bit, StTx bit,
						SetupTaxType char(15), TaxApplicableTo char(10), IsFreightTotals bit, IsProductTotal bit,
						nrecno int identity);
-- Get values
-- 03/20/15 VL added @lnMSPTaxNoRound to avoid multiple rounding
SELECT @lnmPTax = 0, @lnmSTax = 0, @lnmSPTaxt = 0, @lnmSSTaxt = 0, @lnmFPTax = 0, @lnmFSTax = 0, @lnMsPtax = 0,	
		@lnMsStax = 0, @lnMTax = 0, @lnmFright_Tax = 0, @lnTotaltax = 0, @lnmPTaxNoRound = 0,
		@lnMTaxFC = 0, @lnMSPTaxFC = 0, @lnMSPTaxTFC = 0, @lnMSSTaxTFC = 0, @lnTotaltaxFC = 0, @lnmFright_TaxFC = 0, 
		@lnMFPTaxFC = 0, @lnmPTaxNoRoundFC = 0, @lnMFSTaxFC = 0, @lnMPTaxFC = 0, @lnMSTaxFC = 0, @lnForeignETaxRate = 0,
		@lnMSSTaxFC = 0, @lnMSPTaxNoRound = 0, @lnMSPTaxFCNoRound = 0, @lnMSSTaxNoRound = 0, @lnMSSTaxFCNoRound = 0,
		@lnMFSTaxNoRound = 0, @lnMFSTaxFCNoRound = 0,
		-- 10/05/16 VL added presentation currency fields
		@lnMTaxPR = 0, @lnMSPTaxPR = 0, @lnMSPTaxTPR = 0, @lnMSSTaxTPR = 0, @lnTotaltaxPR = 0, @lnmFright_TaxPR = 0, 
		@lnMFPTaxPR = 0, @lnmPTaxNoRoundPR = 0, @lnMFSTaxPR = 0, @lnMPTaxPR = 0, @lnMSTaxPR = 0, @lnMSSTaxPR = 0, @lnMSPTaxPRNoRound = 0, 
		@lnMSSTaxPRNoRound = 0,	@lnMFSTaxPRNoRound = 0 ; 

-- 01/06/15 VL added to get if FC is installed or not
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

-- 12/22/14 VL aded @lnFreightAmtFC	
-- 10/05/16 VL added presentation currency fields	
SELECT @lcSLinkAdd = LinkAdd, @lcCustno = Custno, @lnFreightAmt = FREIGHTAMT, @lnFreightAmtFC = FREIGHTAMTFC, @lnFreightAmtPR = FREIGHTAMTPR FROM PLMAIN WHERE PACKLISTNO = @lcPacklistno
-- 11/19/20 VL comment out the code, we don't have foreign tax or non foreign tax anymore in cube
--SELECT @llForeignTax = ForeignTax FROM Shipbill	WHERE LinkAdd = @lcSLinkAdd

-- 02/27/15 VL changed to get 2nd tax info from plpricestax, not shiptax, also add 5 tax logical fields
--SELECT @llForeignSttx = ShipTax.Sttx, @lnForeignTax_rate = ShipTax.Tax_rate, @lcForeignTax_id = ShipTax.Tax_id,	
--		@lcForeignTaxtype = ShipTax.Taxtype, @lcForeignGl_nbr_in = Gl_nbr_in, @lcForeignGl_nbr_out = Gl_nbr_out, @lcForeignTaxDesc = ShipTax.TaxDesc
--	FROM ShipTax, TaxTabl
--	WHERE ShipTax.Tax_id = TaxTabl.Tax_id  
--	AND LINKADD = @lcSLinkAdd
--	AND CUSTNO = @lcCustno
--	AND ShipTax.TaxType = 'E' 
	-- Just to pick one

-- 11/19/20 VL comment out the code, we don't have foreign tax or non foreign tax anymore in cube
	--SELECT TOP 1 @llForeignSttx = PlpricesTax.Sttx, @lnForeignTax_rate = PlpricesTax.Tax_rate, @lcForeignTax_id = PlpricesTax.Tax_id,	
	--	@lcForeignTaxtype = PlpricesTax.Taxtype, @lcForeignGl_nbr_in = Gl_nbr_in, @lcForeignGl_nbr_out = Gl_nbr_out, @lcForeignTaxDesc = TaxTabl.TaxDesc,
	--	@llForeignPtProd = PlpricesTax.PtProd, @llForeignPtFrt = PlpricesTax.PtFrt, @llForeignStProd = PlpricesTax.StProd, @llForeignStFrt = PlpricesTax.StFrt
	--FROM PlpricesTax, TaxTabl
	--WHERE PlpricesTax.Tax_id = TaxTabl.Tax_id  
	--AND PACKLISTNO = @lcPacklistno
	--AND PlpricesTax.TaxType = 'E'
	--ORDER BY Packlistno, Inv_link

SELECT @lnSalesDiscount = Discount FROM SaleDsct, Customer WHERE SaleDsct.SALEDSCTID = CUSTOMER.SALEDSCTID AND Customer.Custno = @lcCustno

IF @@ROWCOUNT = 0
	SELECT @lnSalesDiscount = 0;

-- 12/22/14 VL comment out and will insert only for selected plprices in below loop
--INSERT @ZShipTaxSR SELECT ShipTax.Tax_id, ShipTax.TaxDesc, Gl_nbr_in, Gl_nbr_out, ShipTax.Tax_rate, ShipTax.Taxtype, 
--		ShipTax.PtProd, ShipTax.Ptfrt, ShipTax.Stprod, ShipTax.StFrt, ShipTax.StTx 
--					FROM ShipTax, TaxTabl
--					WHERE ShipTax.Tax_id = TaxTabl.Tax_id
--					AND LINKADD = @lcSLinkAdd
--					AND CUSTNO = @lcCustno 
--					AND ShipTax.TAXTYPE = 'S'
--					AND RECORDTYPE = 'S'
--SET @lnTotalNo2 = @@ROWCOUNT;		
--INSERT @ZShipTaxSF SELECT ShipTax.Tax_id, ShipTax.TaxDesc, Gl_nbr_in, Gl_nbr_out, ShipTax.Tax_rate, ShipTax.Taxtype, 
--		ShipTax.PtProd, ShipTax.Ptfrt, ShipTax.Stprod, ShipTax.StFrt, ShipTax.StTx 
--					FROM ShipTax, TaxTabl
--					WHERE ShipTax.Tax_id = TaxTabl.Tax_id 
--					AND LINKADD = @lcSLinkAdd
--					AND CUSTNO = @lcCustno 
--					AND (ShipTax.TAXTYPE = 'P'
--					OR ShipTax.TaxType = 'E')
--SET @lnTotalNo3 = @@ROWCOUNT;		
--SET @lnTotalNo5 = @lnTotalNo3;	
-- 12/22/14 VL End}

-- 02/27/15 VL changed to use PlFreightTax to calculate
--INSERT @ZShipTaxCR SELECT ShipTax.Tax_id, ShipTax.TaxDesc, Gl_nbr_in, Gl_nbr_out, ShipTax.Tax_rate, ShipTax.Taxtype, 
--		ShipTax.PtProd, ShipTax.Ptfrt, ShipTax.Stprod, ShipTax.StFrt, ShipTax.StTx 
--					FROM ShipTax, TaxTabl
--					WHERE ShipTax.Tax_id = TaxTabl.Tax_id
--					AND LINKADD = @lcSLinkAdd
--					AND CUSTNO = @lcCustno 
--					AND ShipTax.TAXTYPE = 'C'
--					AND RECORDTYPE = 'S'

-- 11/19/20 VL we decided not to update PlFreightTax table anymore in cube, so here wil get info from Shiptax and Taxtabl again
--INSERT @ZShipTaxCR SELECT PlFreightTax.Tax_id, TaxTabl.TaxDesc, Gl_nbr_in, Gl_nbr_out, PlFreightTax.Tax_rate, PlFreightTax.Taxtype, 
--		PlFreightTax.PtProd, PlFreightTax.Ptfrt, PlFreightTax.Stprod, PlFreightTax.StFrt, PlFreightTax.StTx 
--					FROM PlFreightTax, TaxTabl
--					WHERE PlFreightTax.Tax_id = TaxTabl.Tax_id
--					AND Packlistno = @lcPacklistno
INSERT @ZShipTaxCR SELECT ShipTax.Tax_id, ShipTax.TaxDesc, Gl_nbr_in, Gl_nbr_out, ShipTax.Tax_rate, ShipTax.Taxtype, 
		ShipTax.PtProd, ShipTax.Ptfrt, ShipTax.Stprod, ShipTax.StFrt, ShipTax.StTx, Taxtabl.Taxtype AS SetupTaxType, TaxApplicableTo, IsFreightTotals, IsProductTotal 
					FROM ShipTax, TaxTabl
					WHERE ShipTax.Tax_id = TaxTabl.Tax_id
					AND LINKADD = @lcSLinkAdd
					AND CUSTNO = @lcCustno 
					AND ShipTax.TAXTYPE = 'C'
					AND RECORDTYPE = 'S'

SET @lnTotalNo4 = @@ROWCOUNT;		

------------------------------------------------------------------------------
/* Update all Plprices */
-------------------------
-- 12/22/14 VL added to updated ExtendedFC
-- 10/05/16 VL added presentation currency fields
UPDATE PLPRICES 
	SET EXTENDED = CASE WHEN FLAT = 1 THEN CASE WHEN QUANTITY <> 0 THEN PRICE ELSE 0 END ELSE QUANTITY * PRICE END,
		EXTENDEDFC = CASE WHEN FLAT = 1 THEN CASE WHEN QUANTITY <> 0 THEN PRICEFC ELSE 0 END ELSE QUANTITY * PRICEFC END,
		EXTENDEDPR = CASE WHEN FLAT = 1 THEN CASE WHEN QUANTITY <> 0 THEN PRICEPR ELSE 0 END ELSE QUANTITY * PRICEPR END
	WHERE PACKLISTNO = @lcPacklistno

/* TotExten*/
-------------------------
-- 04/19/13 VL added ISNULL() to prevent getting null value (eg, no record in plprices)
-- 12/22/14 VL added for @lnTotExtenFC
SELECT @lnTotExten = ISNULL(SUM(Extended),0) FROM PLPRICES WHERE PACKLISTNO = @lcPacklistno
SELECT @lnTotExtenFC = ISNULL(SUM(ExtendedFC),0) FROM PLPRICES WHERE PACKLISTNO = @lcPacklistno
-- 10/05/16 VL added presentation currency fields
SELECT @lnTotExtenPR = ISNULL(SUM(ExtendedPR),0) FROM PLPRICES WHERE PACKLISTNO = @lcPacklistno

/* Dsctamt*/
------------------------------
SET @lnDsctamt = ROUND(@lnTotExten*@lnSalesDiscount/100,2)
-- 12/22/14 VL added for FC
SET @lnDsctamtFC = ROUND(@lnTotExtenFC*@lnSalesDiscount/100,2)
-- 10/05/16 VL added presentation currency fields
SET @lnDsctamtPR = ROUND(@lnTotExtenPR*@lnSalesDiscount/100,2)
		
/* TotTaxe*/
-------------------------
-- Delete first, will insert later		
DELETE FROM InvStdTx WHERE Packlistno = @lcPacklistno AND Tax_Type = 'S'

-- 12/22/14 VL added ExtendedFC
-- 10/05/16 VL added presentation currency fields
INSERT @ZPlprices 
	SELECT Extended, ExtendedFC, Taxable, Flat, Pluniqlnk, ExtendedPR 
	FROM PLPRICES 
	WHERE PACKLISTNO = @lcPacklistno
	
--Error, no Plprices is found
SET @lnTotalNo = @@ROWCOUNT;	
-- {04/19/13 VL comment out error code of if no record found in Plprices, found a situation that user only has 1 Plprices record, and 
--				the user deletes this record
--IF @lnTotalNo = 0	
--	BEGIN
--	--set @lRollBack=1
--	RAISERROR('Programming error, can not find associated sales order price items. This operation will be cancelled. Please try again',11,1)
--	ROLLBACK TRANSACTION
--	RETURN
--END
-- 04/19/13 End}

-- SCAN through Plprices
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		-- 10/05/16 VL added presentation currency fields
		SELECT @lnPlpricesExtended = Extended, @lnPlpricesExtendedFC = ExtendedFC, @lnPlpricesExtendedPR = ExtendedPR, @llPlpricesTaxable = Taxable, @llPlpricesFlat = Flat, @llPlpricesPlUniqLnk = PlUniqLnk
			FROM @ZPlprices WHERE nrecno = @lnCount
		BEGIN
		IF (@@ROWCOUNT<>0)
			-- 12/22/14 VL added @lnMTaxFC, @lnMSPTaxFC, @lnMSSTax
			-- 03/20/15 VL added @lnMSPTaxNoRound and @lnMSPTaxFCNoRound to avoid multiple rounding
			-- 10/05/16 VL added presentation currency fields
			SELECT @lnMsPtax = 0, @lnMsSTax = 0, @lnMTax = 0, @lnMTaxFC = 0, @lnMSPTaxFC = 0, @lnMSPTaxNoRound = 0, @lnMSPTaxFCNoRound = 0, 
			@lnMSSTaxNoRound = 0, @lnMSSTaxFCNoRound = 0, @lnMSSTaxFC = 0,
			@lnMTaxPR = 0, @lnMSPTaxPR = 0, @lnMSPTaxPRNoRound = 0, @lnMSSTaxPRNoRound = 0, @lnMSSTaxPR = 0 ;
				
			IF @llPlpricesTaxable = 1
				-- 11/19/20 VL comment out old code, we don't use foreign tax anymore, has new tax for cube
				/*
				BEGIN
				IF @llForeignTax = 0 -- Regular tax
					BEGIN
					-- 12/22/14 VL get records from plpricestax, not from shiptax and taxabl in case tax rate is changed
					SET @lnTableVarCnt = 0
					DELETE FROM @ZShipTaxSR WHERE 1 = 1
					-- 02/27/15 VL changed to only use PlpricesTax because now those 5 logical fields are added to PlpricesTax
					--INSERT @ZShipTaxSR SELECT PlpricesTax.Tax_id AS Tax_id, ShipTax.TaxDesc AS TaxDesc, Taxtabl.Gl_nbr_in, Taxtabl.Gl_nbr_out, 
					--		PlpricesTax.Tax_rate AS Tax_rate, PlpricesTax.Taxtype AS Taxtype, ShipTax.PtProd AS Ptprod, ShipTax.Ptfrt AS Ptfrt, 
					--		ShipTax.Stprod AS Stprod, ShipTax.StFrt AS StFrt, ShipTax.StTx AS StTx, 0 AS nRecno 
					--					FROM ShipTax, TaxTabl, PlpricesTax
					--					WHERE ShipTax.Tax_id = TaxTabl.Tax_id
					--					AND TAXTABL.TAX_ID = PlpricesTax.Tax_id
					--					AND LINKADD = @lcSLinkAdd
					--					AND CUSTNO = @lcCustno 
					--					AND ShipTax.TAXTYPE = 'S'
					--					AND RECORDTYPE = 'S'
					--					AND PlpricesTax.PLUNIQLNK = @llPlpricesPlUniqLnk
					INSERT @ZShipTaxSR SELECT PlpricesTax.Tax_id AS Tax_id, Taxtabl.TaxDesc AS TaxDesc, Taxtabl.Gl_nbr_in, Taxtabl.Gl_nbr_out, 
							PlpricesTax.Tax_rate AS Tax_rate, PlpricesTax.Taxtype AS Taxtype, PlpricesTax.PtProd AS Ptprod, PlpricesTax.Ptfrt AS Ptfrt, 
							PlpricesTax.Stprod AS Stprod, PlpricesTax.StFrt AS StFrt, PlpricesTax.StTx AS StTx, 0 AS nRecno 
										FROM TaxTabl, PlpricesTax
										WHERE TAXTABL.TAX_ID = PlpricesTax.Tax_id
										AND PlpricesTax.Taxtype = 'S'
										AND PlpricesTax.PLUNIQLNK = @llPlpricesPlUniqLnk
					-- 02/27/15 VL End}

					UPDATE @ZShipTaxSR SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
					SET @lnTotalNo2 = @@ROWCOUNT;	
					-- 12/22/14 VL End}															
												
					SET @lnCount2=0;
					WHILE @lnTotalNo2>@lnCount2
						BEGIN
						SET @lnCount2=@lnCount2+1;
						
						SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
								@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
								@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx
						FROM @ZShipTaxSR WHERE nrecno = @lnCount2

						IF (@@ROWCOUNT<>0)
						BEGIN
							-- Get unique value for PlUniqLnk
							BEGIN
								WHILE (1=1)
								BEGIN
									EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
									SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
									IF (@@ROWCOUNT<>0)
										CONTINUE
									ELSE
										BREAK
								END			
							END
							
							-- 12/22/14 VL added @lnMTaxFC
							SET @lnMTax = @lnMTax + ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);				
							SET @lnMTaxFC = @lnMTaxFC + ROUND(@lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
							-- 10/05/16 VL added presentation currency fields
							SET @lnMTaxPR = @lnMTaxPR + ROUND(@lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
							-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
							IF @lnPlpricesExtended <>0
							-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0				
							--IF ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
								-- 03/02/15 VL added 5 logical tax fields
								-- 10/05/16 VL added presentation currency fields
								INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_AmtPR, Tax_type, InvStdtxUniq,
									PtProd, Ptfrt, Stprod, StFrt, StTx) 
									VALUES (@lcPacklistno, @llPlpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
										ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 
										ROUND(@lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2),
										ROUND(@lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2),
										@lcTxTaxtype, @lcNewUniqNbr,
										@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
						END
						END
					END
				ELSE
				-- Foreign tax
					BEGIN
					-- 12/22/14 VL get records from plpricestax, not from shiptax and taxabl in case tax rate is changed
					SET @lnTableVarCnt = 0
					DELETE FROM @ZShipTaxSF WHERE 1 = 1
					-- 02/27/15 VL changed to only use PlpricesTax because now those 5 logical fields are added to PlpricesTax
					--INSERT @ZShipTaxSF SELECT ShipTax.Tax_id, ShipTax.TaxDesc, Gl_nbr_in, Gl_nbr_out, PlpricesTax.Tax_rate, ShipTax.Taxtype, 
					--		ShipTax.PtProd, ShipTax.Ptfrt, ShipTax.Stprod, ShipTax.StFrt, ShipTax.StTx, 0 AS nRecno 
					--					FROM ShipTax, TaxTabl, PlpricesTax
					--					WHERE ShipTax.Tax_id = TaxTabl.Tax_id 
					--					AND TAXTABL.TAX_ID = PlpricesTax.Tax_id
					--					AND LINKADD = @lcSLinkAdd
					--					AND CUSTNO = @lcCustno 
					--					AND (ShipTax.TAXTYPE = 'P'
					--					OR ShipTax.TaxType = 'E')
					--					AND PlpricesTax.PLUNIQLNK = @llPlpricesPlUniqLnk
					INSERT @ZShipTaxSF SELECT PlpricesTax.Tax_id, TaxTabl.TaxDesc, Gl_nbr_in, Gl_nbr_out, PlpricesTax.Tax_rate, PlpricesTax.Taxtype, 
							PlpricesTax.PtProd, PlpricesTax.Ptfrt, PlpricesTax.Stprod, PlpricesTax.StFrt, PlpricesTax.StTx, 0 AS nRecno 
										FROM TaxTabl, PlpricesTax
										WHERE TAXTABL.TAX_ID = PlpricesTax.Tax_id
										AND (PlpricesTax.Taxtype = 'P' 
										OR PlpricesTax.TaxType = 'E')
										AND PlpricesTax.PLUNIQLNK = @llPlpricesPlUniqLnk
					-- 02/27/15 VL End}
					
					UPDATE @ZShipTaxSF SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
					SET @lnTotalNo3 = @@ROWCOUNT;	
					-- 03/02/15 VL comment out next line, do not use @ZShipTaxSF for Freight tax anymore	
					--SET @lnTotalNo5 = @lnTotalNo3;	
					-- 12/22/14 VL End}
					
					SET @lnCount3=0;
					WHILE @lnTotalNo3>@lnCount3
					BEGIN
						SET @lnCount3=@lnCount3+1;
						
						SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
								@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
								@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx
						FROM @ZShipTaxSF WHERE nrecno = @lnCount3
						BEGIN
						IF (@@ROWCOUNT<>0)
							-- Get unique value for PlUniqLnk
							BEGIN
								WHILE (1=1)
								BEGIN
									EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
									SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
									IF (@@ROWCOUNT<>0)
										CONTINUE
									ELSE
										BREAK
								END			
							END
							-- check if primary
							
							IF @lcTxTaxtype = 'P' AND @llTxPtProd = 1
							BEGIN
								SET @lnMSPTax = @lnMSPTax + ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								-- 03/20/15 VL added @lnMSPTaxNoRound and @lnMSPTaxFCNoRound to avoid multiple rounding
								SET @lnMSPTaxNoRound = @lnMSPTaxNoRound + @lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100
								--- 12/22/14 VL added @lnMSPTaxFC
								SET @lnMSPTaxFC = @lnMSPTaxFC + ROUND(@lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								SET @lnMSPTaxFCNoRound = @lnMSPTaxFCNoRound + @lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100
								-- 10/05/16 VL added presentation currency fields
								SET @lnMSPTaxPR = @lnMSPTaxPR + ROUND(@lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								SET @lnMSPTaxPRNoRound = @lnMSPTaxPRNoRound + @lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100
								
								-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
								IF @lnPlpricesExtended <> 0
								-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0				
								--IF ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
									-- 03/02/15 VL added 5 logical tax fields
									-- 10/05/16 VL added presentation currency fields
									INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_AmtPR, Tax_type, InvStdtxUniq, TxTypeForn,
										PtProd, Ptfrt, Stprod, StFrt, StTx) 
										VALUES (@lcPacklistno, @llPlpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
											ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 
											ROUND(@lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2),
											ROUND(@lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2),
											'S', @lcNewUniqNbr, @lcTxTaxtype, 
											@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
							END
							
									
							IF @lcTxTaxtype = 'E' AND @llTxStProd = 1
							BEGIN	
								SET @lnMSSTax = @lnMSSTax + ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								-- 12/22/14 VL added @lnMSSTaxFC
								SET @lnMSSTaxFC = @lnMSSTaxFC + ROUND(@lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								-- 10/05/16 VL added presentation currency fields
								SET @lnMSSTaxPR = @lnMSSTaxPR + ROUND(@lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								-- 03/20/15 VL added @lnMSSTaxNoRound and @lnMSSTaxFCNoRound to avoid multiple rounding
								SET @lnMSSTaxNoRound = @lnMSSTaxNoRound + @lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100
								SET @lnMSSTaxFCNoRound = @lnMSSTaxFCNoRound + @lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100
								-- 10/05/16 VL added presentation currency fields
								SET @lnMSSTaxPRNoRound = @lnMSSTaxPRNoRound + @lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100

								IF @llForeignSttx = 0
								BEGIN
									-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
									IF @lnPlpricesExtended <> 0
									-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0				
									--IF ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
										-- 03/02/15 VL added 5 logical tax fields
										-- 10/05/16 VL added presentation currency fields
										INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_amtPR, Tax_type, InvStdtxUniq, TxTypeForn,
											PtProd, Ptfrt, Stprod, StFrt, StTx) 
											VALUES (@lcPacklistno, @llPlpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
												ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 
												ROUND(@lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2),
												ROUND(@lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2),
												'S', @lcNewUniqNbr, @lcTxTaxtype,
												@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
								END
							END		
						END
					END
					
					IF @llForeignSttx = 1
						BEGIN
						-- 12/22/14 VL added code to get secondary from plprices although in case it's different from Shiptax
						SELECT @lnForeignETaxRate = Tax_rate FROM @ZShipTaxSF WHERE Taxtype = 'E'
						SELECT @lnForeignTax_rate = CASE WHEN @lnForeignETaxRate > 0 THEN @lnForeignETaxRate ELSE @lnForeignTax_rate END
						-- 12/22/14 VL so now the @lnForeignTax_rate should have tax rate from plpricestax if it found record
						-- 03/20/15 VL changed to use @lnMSPTaxNoRound and @lnMSSTaxFCNoRound to calculate, so won't have multiple rounding apply to @lnMSSTax
						--SET @lnMSSTax = @lnMSSTax + ROUND(@lnMSPTax * @lnForeignTax_rate/100,2)
						SET @lnMSSTax = ROUND(@lnMSSTaxNoRound + @lnMSPTaxNoRound * @lnForeignTax_rate/100,2)
						-- 12/22/14 VL added @lnMSSTaxFC
						--SET @lnMSSTaxFC = @lnMSSTaxFC + ROUND(@lnMSPTaxFC * @lnForeignTax_rate/100,2)
						SET @lnMSSTaxFC = ROUND(@lnMSSTaxFCNoRound + @lnMSPTaxFCNoRound * @lnForeignTax_rate/100,2)
						-- 10/05/16 VL added presentation currency fields
						SET @lnMSSTaxPR = ROUND(@lnMSSTaxPRNoRound + @lnMSPTaxPRNoRound * @lnForeignTax_rate/100,2)

						-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
						-- 10/05/16 VL added presentation currency fields
						IF (@lnMSSTaxNoRound <> 0 OR @lnMSPTaxNoRound <> 0) OR (@lnMSSTaxFCNoRound <> 0 OR @lnMSPTaxFCNoRound <> 0) OR (@lnMSSTaxPRNoRound <> 0 OR @lnMSPTaxPRNoRound <> 0)
						-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0				
						--IF @lnMSSTax <> 0 OR @lnMSSTaxFC <> 0
							BEGIN
							-- Get unique value for PlUniqLnk
							BEGIN
								WHILE (1=1)
								BEGIN
									EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
									SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
									IF (@@ROWCOUNT<>0)
										CONTINUE
									ELSE
										BREAK
								END			
							END	
							-- 03/02/15 VL added 5 logical tax fields		
							-- 10/05/16 VL added presentation currency fields			
							INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_amtPR, Tax_type, InvStdtxUniq, TxTypeForn,
									PtProd, Ptfrt, Stprod, StFrt, StTx) 
								VALUES (@lcPacklistno, @llPlpricesPlUniqLnk, @lcSLinkAdd, @lcForeignTax_id, @lcForeignTaxDesc, @lcForeignGl_nbr_in, @lcForeignGl_nbr_out, @lnForeignTax_rate, 
									@lnMSSTax, @lnMSSTaxFC, @lnMSSTaxPR, 'S', @lcNewUniqNbr, @lcForeignTaxtype, @llForeignPtProd, @llForeignPtfrt, @llForeignStprod, @llForeignStFrt, @llForeignStTx)

						END
					END
					
					-- 12/22/14 VL added FC
					SET @lnMTAX = @lnMSPTax + @lnMSSTax 
					SET @lnMTAXFC = @lnMSPTaxFC + @lnMSSTaxFC 
					-- 10/05/16 VL added presentation currency fields	
					SET @lnMTAXPR = @lnMSPTaxPR + @lnMSSTaxPR 
					END
				END
				*/
				-- 11/19/20 VL End}

				-- 11/19/20 VL start new code
				---------------------------------
				BEGIN
					-- 12/22/14 VL get records from plpricestax, not from shiptax and taxabl in case tax rate is changed
					SET @lnTableVarCnt = 0
					DELETE FROM @ZShipTaxSF WHERE 1 = 1
					-- 11/19/20 VL added 4 new tax fields
					INSERT @ZShipTaxSF SELECT PlpricesTax.Tax_id, TaxTabl.TaxDesc, Gl_nbr_in, Gl_nbr_out, PlpricesTax.Tax_rate, PlpricesTax.Taxtype, 
							PlpricesTax.PtProd, PlpricesTax.Ptfrt, PlpricesTax.Stprod, PlpricesTax.StFrt, PlpricesTax.StTx, 
							PlpricesTax.SetupTaxType, PlpricesTax.TaxApplicableTo, PlpricesTax.IsFreightTotals, PlpricesTax.IsProductTotal,
							0 AS nRecno 
										FROM TaxTabl, PlpricesTax
										WHERE TAXTABL.TAX_ID = PlpricesTax.Tax_id
										AND PlpricesTax.PLUNIQLNK = @llPlpricesPlUniqLnk
					
					UPDATE @ZShipTaxSF SET @lnTableVarCnt = nrecno = @lnTableVarCnt + 1
					SET @lnTotalNo3 = @@ROWCOUNT;	
					-- 03/02/15 VL comment out next line, do not use @ZShipTaxSF for Freight tax anymore	
					--SET @lnTotalNo5 = @lnTotalNo3;	
					-- 12/22/14 VL End}
					
					SET @lnCount3=0;
					WHILE @lnTotalNo3>@lnCount3
					BEGIN
						SET @lnCount3=@lnCount3+1;
						
						SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
								@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
								@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx,
								-- 11/19/20 VL added 4 new tax fields
								@lcSetupTaxType = SetupTaxType, @lcTaxApplicableTo = TaxApplicableTo, @llIsFreightTotals = IsFreightTotals, @llIsProductTotal = IsProductTotal
						FROM @ZShipTaxSF WHERE nrecno = @lnCount3
						BEGIN
						IF (@@ROWCOUNT<>0)
							-- Get unique value for PlUniqLnk
							BEGIN
								WHILE (1=1)
								BEGIN
									EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
									SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
									IF (@@ROWCOUNT<>0)
										CONTINUE
									ELSE
										BREAK
								END			
							END
							-- check if primary
							
							IF @lcSetupTaxType = 'Tax On Goods' AND @llIsProductTotal = 1
							BEGIN
								SET @lnMSPTax = @lnMSPTax + ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								-- 03/20/15 VL added @lnMSPTaxNoRound and @lnMSPTaxFCNoRound to avoid multiple rounding
								SET @lnMSPTaxNoRound = @lnMSPTaxNoRound + @lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100
								--- 12/22/14 VL added @lnMSPTaxFC
								SET @lnMSPTaxFC = @lnMSPTaxFC + ROUND(@lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								SET @lnMSPTaxFCNoRound = @lnMSPTaxFCNoRound + @lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100
								-- 10/05/16 VL added presentation currency fields
								SET @lnMSPTaxPR = @lnMSPTaxPR + ROUND(@lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
								SET @lnMSPTaxPRNoRound = @lnMSPTaxPRNoRound + @lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100
								
								-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
								IF @lnPlpricesExtended <> 0
									INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_AmtPR, Tax_type, InvStdtxUniq, TxTypeForn,
										PtProd, Ptfrt, Stprod, StFrt, StTx) 
										VALUES (@lcPacklistno, @llPlpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
											ROUND(@lnPlpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 
											ROUND(@lnPlpricesExtendedFC*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2),
											ROUND(@lnPlpricesExtendedPR*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2),
											'S', @lcNewUniqNbr, @lcTxTaxtype, 
											@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
							END
							
									
							IF @lcSetupTaxType = 'Secondary Tax'
							BEGIN	
								-- 11/19/20 VL get the tax rate of primary tax this secondary tax applicable to
								-- 11/19/20 VL changed to get from plpricesTax to get the tax rate of primary tax
								SELECT @lnPTaxRate = Tax_Rate FROM PLPRICESTAX WHERE PLUNIQLNK = @llPlpricesPlUniqLnk AND Tax_id = LEFT(@lcTaxApplicableTo,8)
								
								SET @lnMSSTax = @lnMSSTax + 
									CASE WHEN @llIsProductTotal = 1 
										THEN ROUND((@lnPlpricesExtended+@lnPlpricesExtended*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
										ELSE ROUND((@lnPlpricesExtended*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END

								SET @lnMSSTaxFC = @lnMSSTaxFC + 
									CASE WHEN @llIsProductTotal = 1 
										THEN ROUND((@lnPlpricesExtendedFC+@lnPlpricesExtendedFC*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
										ELSE ROUND((@lnPlpricesExtendedFC*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END

								SET @lnMSSTaxPR = @lnMSSTaxPR + 
									CASE WHEN @llIsProductTotal = 1 
										THEN ROUND((@lnPlpricesExtendedPR+@lnPlpricesExtendedPR*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
										ELSE ROUND((@lnPlpricesExtendedPR*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END
								-- 03/20/15 VL added @lnMSSTaxNoRound and @lnMSSTaxFCNoRound to avoid multiple rounding

								SET @lnMSSTaxNoRound = @lnMSSTaxNoRound + 
									CASE WHEN @llIsProductTotal = 1 
										THEN (@lnPlpricesExtended+@lnPlpricesExtended*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100
										ELSE (@lnPlpricesExtended*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100 END

								SET @lnMSSTaxFCNoRound = @lnMSSTaxFCNoRound + 
									CASE WHEN @llIsProductTotal = 1 
										THEN (@lnPlpricesExtendedFC+@lnPlpricesExtendedFC*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100
										ELSE (@lnPlpricesExtendedFC*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100 END

								SET @lnMSSTaxPRNoRound = @lnMSSTaxPRNoRound + 
									CASE WHEN @llIsProductTotal = 1 
										THEN (@lnPlpricesExtendedPR+@lnPlpricesExtendedPR*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100
										ELSE (@lnPlpricesExtendedPR*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100 END

								-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
								IF @lnPlpricesExtended <> 0 OR @lnPlpricesExtendedFC <> 0 OR @lnPlpricesExtendedPR <> 0
									BEGIN

									INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_amtPR, Tax_type, InvStdtxUniq, TxTypeForn,
										PtProd, Ptfrt, Stprod, StFrt, StTx) 
										VALUES (@lcPacklistno, @llPlpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
												CASE WHEN @llIsProductTotal = 1 
													THEN ROUND((@lnPlpricesExtended+@lnPlpricesExtended*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
													ELSE ROUND((@lnPlpricesExtended*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END,
												CASE WHEN @llIsProductTotal = 1 
													THEN ROUND((@lnPlpricesExtendedFC+@lnPlpricesExtendedFC*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
													ELSE ROUND((@lnPlpricesExtendedFC*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END,
												CASE WHEN @llIsProductTotal = 1 
													THEN ROUND((@lnPlpricesExtendedPR+@lnPlpricesExtendedPR*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
													ELSE ROUND((@lnPlpricesExtendedPR*(100-@lnSalesDiscount)/100*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END,
												'S', @lcNewUniqNbr, @lcTxTaxtype,
												@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
								END
							END		
						END
					END
					
					-- 12/22/14 VL added FC
					SET @lnMTAX = @lnMSPTax + @lnMSSTax 
					SET @lnMTAXFC = @lnMSPTaxFC + @lnMSSTaxFC 
					-- 10/05/16 VL added presentation currency fields	
					SET @lnMTAXPR = @lnMSPTaxPR + @lnMSSTaxPR 
				END-- End of @llPlpricesTaxable = 1
				---------------------------------
				-- 11/19/20 VL End
		END
		SET @lnMSPTaxT = @lnMSPTaxT + @lnMSPTax;
		SET @lnMSSTaxT = @lnMSSTaxT + @lnMSSTax;
		SET @lnTotaltax = @lnTotaltax + @lnMTAX;
		
		-- 12/22/14 VL added FC
		SET @lnMSPTaxTFC = @lnMSPTaxTFC + @lnMSPTaxFC
		SET @lnMSSTaxTFC = @lnMSSTaxTFC + @lnMSSTaxFC
		SET @lnTotaltaxFC = @lnTotaltaxFC + @lnMTaxFC

		-- 10/05/16 VL added presentation currency fields	
		SET @lnMSPTaxTPR = @lnMSPTaxTPR + @lnMSPTaxPR
		SET @lnMSSTaxTPR = @lnMSSTaxTPR + @lnMSSTaxPR
		SET @lnTotaltaxPR = @lnTotaltaxPR + @lnMTaxPR

	END
END

/* TOTTAXF  @lnmFright_Tax*/
---------------
-- Delete first, will insert later		
DELETE FROM InvStdTx WHERE Packlistno = @lcPacklistno AND Tax_Type = 'C'

-- 11/19/20 VL comment out old tax code, now has new tax in cube
/*
BEGIN
IF @llForeignTax = 0 -- Regular tax
	BEGIN
	SET @lnCount4=0;
	WHILE @lnTotalNo4>@lnCount4
	BEGIN	
		SET @lnCount4=@lnCount4+1;
		
		SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
				@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
				@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx
		FROM @ZShipTaxCR WHERE nrecno = @lnCount4
			
		IF (@@ROWCOUNT<>0)
		BEGIN		
			-- Get unique value for PlUniqLnk
			BEGIN
				WHILE (1=1)
				BEGIN
					EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
					SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
					IF (@@ROWCOUNT<>0)
						CONTINUE
					ELSE
						BREAK
				END			
			END
			
			SET @lnmFright_Tax = @lnmFright_Tax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2)
			-- 12/22/14 VL added @lnmFright_TaxFC
			SET @lnmFright_TaxFC = @lnmFright_TaxFC + ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2)
			-- 10/05/16 VL added presentation currency fields	
			SET @lnmFright_TaxPR = @lnmFright_TaxPR + ROUND(@lnFreightAmtPR*@lnTxTax_rate/100,2)

			-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
			IF @lnFreightAmt <> 0
			-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0				
			--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0
				-- 04/19/13 VL found for shippint tax, no need to update PlUniqLnk field, don't use @llPlpricesPlUniqLnk, use SPACE(10)
				-- 03/02/15 VL added 5 logical tax fields	
				-- 10/05/16 VL added presentation currency fields
				INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_AmtFC, Tax_AmtPR, Tax_type, InvStdtxUniq,
						PtProd, Ptfrt, Stprod, StFrt, StTx) 
					VALUES (@lcPacklistno, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
						ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2), ROUND(@lnFreightAmtPR*@lnTxTax_rate/100,2), @lcTxTaxtype, @lcNewUniqNbr,
						@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
		END
	END
	END
ELSE
-- Foreign tax
	BEGIN
	
	SET @lnCount5=0;
	WHILE @lnTotalNo4>@lnCount5
		BEGIN
		SET @lnCount5=@lnCount5+1;
		
		-- 02/27/15 VL changed to use from @ZShipTaxSF (the same as foreign tax sales tax table) to use @ZShipTaxCF for freight foreign tax
		-- now use PlFreightTax to save the freight tax, can use @ZShipTaxCR for both regular tax and foreign tax
		SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
				@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
				@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx
		FROM @ZShipTaxCR WHERE nrecno = @lnCount5
		
		IF (@@ROWCOUNT<>0)
		BEGIN
			-- Get unique value for PlUniqLnk
			WHILE (1=1)
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
				SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
				IF (@@ROWCOUNT<>0)
					CONTINUE
				ELSE
					BREAK
			END			
	
			-- check if primary
			IF @lcTxTaxtype = 'P' AND @llTxPtfrt = 1
				BEGIN
				SET @lnMFPTax = @lnMFPTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
				-- 05/30/12 VL created another variable to keep not rounded value for if @llForeignSttx = 1 case use
				SET @lnmPTaxNoRound = @lnmPTaxNoRound + @lnFreightAmt*@lnTxTax_rate/100

				-- 12/22/14 VL added @lnMFPTaxFC and @lnmPTaxNoRoundFC
				SET @lnMFPTaxFC = @lnMFPTaxFC + ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2);
				SET @lnmPTaxNoRoundFC = @lnmPTaxNoRoundFC + @lnFreightAmtFC*@lnTxTax_rate/100
				
				-- 10/05/16 VL added presentation currency fields
				SET @lnMFPTaxPR = @lnMFPTaxPR + ROUND(@lnFreightAmtPR*@lnTxTax_rate/100,2);
				SET @lnmPTaxNoRoundPR = @lnmPTaxNoRoundPR + @lnFreightAmtPR*@lnTxTax_rate/100

				-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
				IF @lnFreightAmt <> 0
				-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0				
				--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0 OR ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2) <> 0
					-- 04/19/13 VL found for shippint tax, no need to update PlUniqLnk field, don't use @llPlpricesPlUniqLnk, use SPACE(10)
					-- 03/02/15 VL added 5 logical tax fields	
					-- 10/05/16 VL added presentation currency fields
					INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_amtPR, Tax_type, InvStdtxUniq, TxTypeForn,
							PtProd, Ptfrt, Stprod, StFrt, StTx) 
						VALUES (@lcPacklistno, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
							ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2), ROUND(@lnFreightAmtPR*@lnTxTax_rate/100,2), 'C', @lcNewUniqNbr, @lcTxTaxtype,
							@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
			END
			
			IF @lcTxTaxtype = 'E' AND @llTxStFrt = 1
				BEGIN
				SET @lnMFSTax = @lnMFSTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
				-- 12/22/14 VL added FC
				SET @lnMFSTaxFC = @lnMFSTaxFC + ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2);
				-- 10/05/16 VL added presentation currency fields
				SET @lnMFSTaxPR = @lnMFSTaxPR + ROUND(@lnFreightAmtPR*@lnTxTax_rate/100,2);
				-- 03/20/15 VL added @lnMFSTaxNoRound and @lnMFSTaxFCNoRound to avoid multiple rounding
				SET @lnMFSTaxNoRound = @lnMFSTaxNoRound + @lnFreightAmt*@lnTxTax_rate/100
				SET @lnMFSTaxFCNoRound = @lnMFSTaxFCNoRound + @lnFreightAmtFC*@lnTxTax_rate/100
				-- 10/05/16 VL added presentation currency fields
				SET @lnMFSTaxPRNoRound = @lnMFSTaxPRNoRound + @lnFreightAmtPR*@lnTxTax_rate/100

				IF @llForeignSttx = 0
				BEGIN
					-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
					IF @lnFreightAmt <> 0
					-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0				
					--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0 OR ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2) <> 0
						-- 04/19/13 VL found for shippint tax, no need to update PlUniqLnk field, don't use @llPlpricesPlUniqLnk, use SPACE(10)
						-- 03/02/15 VL added 5 logical tax fields	
						-- 10/05/16 VL added presentation currency fields
						INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_amtPR, Tax_type, InvStdtxUniq, TxTypeForn,
								PtProd, Ptfrt, Stprod, StFrt, StTx) 
							VALUES (@lcPacklistno, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
								ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2), ROUND(@lnFreightAmtPR*@lnTxTax_rate/100,2), 'C', @lcNewUniqNbr, @lcTxTaxtype,
								@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
				END
			END		
		END
	END
	
	IF @llForeignSttx = 1
		BEGIN
		-- 05/30/12 VL changed to use @@lnmPTaxNoRound
		--SET @lnMFSTax = @lnMFSTax + ROUND(@lnMFPTax * @lnForeignTax_rate/100,2);
		-- 03/20/15 VL use @lnMFSTaxNoRound to avoid multiple rounding
		--SET @lnMFSTax = @lnMFSTax + ROUND(@lnmPTaxNoRound * @lnForeignTax_rate/100,2);
		SET @lnMFSTax = ROUND(@lnMFSTaxNoRound + @lnmPTaxNoRound * @lnForeignTax_rate/100,2);
		
		-- 12/22/14 VL added FC
		-- 03/20/15 VL use @lnMFSTaxNoRound to avoid multiple rounding
		--SET @lnMFSTaxFC = @lnMFSTaxFC + ROUND(@lnmPTaxNoRoundFC * @lnForeignTax_rate/100,2);
		SET @lnMFSTaxFC = ROUND(@lnMFSTaxFCNoRound + @lnmPTaxNoRoundFC * @lnForeignTax_rate/100,2);
		-- 10/05/16 VL added presentation currency fields
		SET @lnMFSTaxPR = ROUND(@lnMFSTaxPRNoRound + @lnmPTaxNoRoundPR * @lnForeignTax_rate/100,2);

		-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
		-- 10/05/16 VL added presentation currency fields
		IF (@lnMFSTaxNoRound <> 0 OR @lnmPTaxNoRound <> 0) OR (@lnMFSTaxFCNoRound <> 0 OR @lnmPTaxNoRoundFC <> 0) OR (@lnMFSTaxPRNoRound <> 0 OR @lnmPTaxNoRoundPR <> 0)
		-- 06/28/16 VL removed the criteria that tax has to be > 0, Penang has rate = 0 records but still need to insert invstdtx to make other module like CM works with taxrate=0				
		--IF @lnMFSTax <> 0 OR @lnMFSTaxFC <> 0
		BEGIN
			-- Get unique value for PlUniqLnk
			BEGIN
				WHILE (1=1)
				BEGIN
					EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
					SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
					IF (@@ROWCOUNT<>0)
						CONTINUE
					ELSE
						BREAK
				END			
			END		
			-- 04/19/13 VL found for shippint tax, no need to update PlUniqLnk field, don't use @llPlpricesPlUniqLnk, use SPACE(10)
			-- 03/02/15 VL added 5 logical tax fields	
			-- 10/05/16 VL added presentation currency fields
			INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_amtPR, Tax_type, InvStdtxUniq, TxTypeForn,
					PtProd, Ptfrt, Stprod, StFrt, StTx) 
				VALUES (@lcPacklistno, SPACE(10), @lcSLinkAdd, @lcForeignTax_id, @lcForeignTaxDesc, @lcForeignGl_nbr_in, @lcForeignGl_nbr_out, @lnForeignTax_rate, 
					@lnMFSTax, @lnMFSTaxFC, @lnMFSTaxPR, 'C', @lcNewUniqNbr, @lcForeignTaxtype, @llForeignPtProd, @llForeignPtfrt, @llForeignStprod, @llForeignStFrt, @llForeignStTx)

		END
	END

	SET @lnmFright_Tax = @lnMFPTax + @lnMFSTax;
	-- 12/22/14 VL added FC
	SET @lnmFright_TaxFC = @lnMFPTaxFC + @lnMFSTaxFC;
	-- 10/05/16 VL added presentation currency fields
	SET @lnmFright_TaxPR = @lnMFPTaxPR + @lnMFSTaxPR;
	END
END	
*/

-- 11/19/20 VL added new freight tax code
	BEGIN
	
	SET @lnCount5=0;
	WHILE @lnTotalNo4>@lnCount5
		BEGIN
		SET @lnCount5=@lnCount5+1;
		
		SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
				@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
				@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx,
				-- 11/19/20 VL added 4 new tax fields
				@lcSetupTaxType = SetupTaxType, @lcTaxApplicableTo = TaxApplicableTo, @llIsFreightTotals = IsFreightTotals, @llIsProductTotal = IsProductTotal

		FROM @ZShipTaxCR WHERE nrecno = @lnCount5
		
		IF (@@ROWCOUNT<>0)
		BEGIN
			-- Get unique value for PlUniqLnk
			WHILE (1=1)
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
				SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
				IF (@@ROWCOUNT<>0)
					CONTINUE
				ELSE
					BREAK
			END			
	
			-- check if primary
			IF @lcSetupTaxType = 'Tax On Goods' AND @llIsFreightTotals = 1
				BEGIN
				SET @lnMFPTax = @lnMFPTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
				-- 05/30/12 VL created another variable to keep not rounded value for if @llForeignSttx = 1 case use
				SET @lnmPTaxNoRound = @lnmPTaxNoRound + @lnFreightAmt*@lnTxTax_rate/100

				-- 12/22/14 VL added @lnMFPTaxFC and @lnmPTaxNoRoundFC
				SET @lnMFPTaxFC = @lnMFPTaxFC + ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2);
				SET @lnmPTaxNoRoundFC = @lnmPTaxNoRoundFC + @lnFreightAmtFC*@lnTxTax_rate/100
				
				-- 10/05/16 VL added presentation currency fields
				SET @lnMFPTaxPR = @lnMFPTaxPR + ROUND(@lnFreightAmtPR*@lnTxTax_rate/100,2);
				SET @lnmPTaxNoRoundPR = @lnmPTaxNoRoundPR + @lnFreightAmtPR*@lnTxTax_rate/100

				-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
				IF @lnFreightAmt <> 0
					INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_amtPR, Tax_type, InvStdtxUniq, TxTypeForn,
							PtProd, Ptfrt, Stprod, StFrt, StTx) 
						VALUES (@lcPacklistno, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
							ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), ROUND(@lnFreightAmtFC*@lnTxTax_rate/100,2), ROUND(@lnFreightAmtPR*@lnTxTax_rate/100,2), 'C', @lcNewUniqNbr, @lcTxTaxtype,
							@llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
			END
			
			IF @lcSetupTaxType = 'Secondary Tax'
				BEGIN
				-- Get the primary tax rate of this secondary tax applicable to
				SELECT @lnPTaxRate = Tax_Rate FROM Taxtabl WHERE TAXUNIQUE = @lcTaxApplicableTo -- This variable is from Taxtabl which saves the TaxUnique of the primary tax

				SET @lnMFSTax = @lnMFSTax + 
					CASE WHEN @llIsFreightTotals = 1 
						THEN ROUND((@lnFreightAmt+@lnFreightAmt*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
						ELSE ROUND((@lnFreightAmt*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END
				
				SET @lnMFSTaxFC = @lnMFSTaxFC + 
					CASE WHEN @llIsFreightTotals = 1 
						THEN ROUND((@lnFreightAmtFC+@lnFreightAmtFC*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
						ELSE ROUND((@lnFreightAmtFC*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END

				SET @lnMFSTaxPR = @lnMFSTaxPR + 
					CASE WHEN @llIsFreightTotals = 1 
						THEN ROUND((@lnFreightAmtPR+@lnFreightAmtPR*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
						ELSE ROUND((@lnFreightAmtPR*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END

				SET @lnMFSTaxNoRound = @lnMFSTaxNoRound + 
					CASE WHEN @llIsFreightTotals = 1 
						THEN (@lnFreightAmt+@lnFreightAmt*@lnPTaxRate/100)*@lnTxTax_rate/100
						ELSE (@lnFreightAmt*@lnPTaxRate/100)*@lnTxTax_rate/100 END

				SET @lnMFSTaxFCNoRound = @lnMFSTaxFCNoRound + 
					CASE WHEN @llIsFreightTotals = 1 
						THEN (@lnFreightAmtFC+@lnFreightAmtFC*@lnPTaxRate/100)*@lnTxTax_rate/100
						ELSE (@lnFreightAmtFC*@lnPTaxRate/100)*@lnTxTax_rate/100 END

				SET @lnMFSTaxPRNoRound = @lnMFSTaxPRNoRound + 
					CASE WHEN @llIsFreightTotals = 1 
						THEN (@lnFreightAmtPR+@lnFreightAmtPR*@lnPTaxRate/100)*@lnTxTax_rate/100
						ELSE (@lnFreightAmtPR*@lnPTaxRate/100)*@lnTxTax_rate/100 END





				IF @llForeignSttx = 0
				BEGIN
					-- 07/13/16 VL Found should not totally removed the tax>0 criteria, if the sales amount or freight amount is 0, then no need to insert invstdtx (no matter the tax rate is 0 or not), so added to check amount, not amount*tax_rate			
					IF @lnFreightAmt <> 0 OR @lnFreightAmtFC <> 0 OR @lnFreightAmtPR <> 0
						INSERT INTO InvStdTx (Packlistno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_amtPR, Tax_type, InvStdtxUniq, TxTypeForn,
								PtProd, Ptfrt, Stprod, StFrt, StTx) 
							VALUES (@lcPacklistno, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
									CASE WHEN @llIsFreightTotals = 1 
										THEN ROUND((@lnFreightAmt+@lnFreightAmt*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
										ELSE ROUND((@lnFreightAmt*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END,
									CASE WHEN @llIsFreightTotals = 1 
										THEN ROUND((@lnFreightAmtFC+@lnFreightAmtFC*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
										ELSE ROUND((@lnFreightAmtFC*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END,
									CASE WHEN @llIsFreightTotals = 1 
										THEN ROUND((@lnFreightAmtPR+@lnFreightAmtPR*@lnPTaxRate/100)*@lnTxTax_rate/100,2)
										ELSE ROUND((@lnFreightAmtPR*@lnPTaxRate/100)*@lnTxTax_rate/100,2) END,
									'C', @lcNewUniqNbr, @lcTxTaxtype, @llTxPtProd, @llTxPtfrt, @llTxStprod, @llTxStFrt, @llTxStTx)
				END
			END		
		END
	END
	

	SET @lnmFright_Tax = @lnMFPTax + @lnMFSTax;
	-- 12/22/14 VL added FC
	SET @lnmFright_TaxFC = @lnMFPTaxFC + @lnMFSTaxFC;
	-- 10/05/16 VL added presentation currency fields
	SET @lnmFright_TaxPR = @lnMFPTaxPR + @lnMFSTaxPR;
	END
-- 11/19/20 VL new freight tax code End}

				
/* InvTotal @lnInvTotal*/
SET @lnInvTotal = CASE WHEN 
	ROUND(@lnTotExten,2) + ROUND(@lnTotaltax,2) + ROUND(@lnFreightAmt,2) + ROUND(@lnmFright_Tax,2) - ROUND(@lnDsctamt,2) >  999999999999999.99
	THEN 999999999999999.99 
	ELSE ROUND(@lnTotExten,2) + ROUND(@lnTotaltax,2) + ROUND(@lnFreightAmt,2) + ROUND(@lnmFright_Tax,2) - ROUND(@lnDsctamt,2)
	END
-- 12/22/14 VL added for FC
SET @lnInvTotalFC = CASE WHEN 
	ROUND(@lnTotExtenFC,2) + ROUND(@lnTotaltaxFC,2) + ROUND(@lnFreightAmtFC,2) + ROUND(@lnmFright_TaxFC,2) - ROUND(@lnDsctamtFC,2) >  999999999999999.99
	THEN 999999999999999.99 
	ELSE ROUND(@lnTotExtenFC,2) + ROUND(@lnTotaltaxFC,2) + ROUND(@lnFreightAmtFC,2) + ROUND(@lnmFright_TaxFC,2) - ROUND(@lnDsctamtFC,2)
	END		
-- 10/05/16 VL added presentation currency fields
SET @lnInvTotalPR = CASE WHEN 
	ROUND(@lnTotExtenPR,2) + ROUND(@lnTotaltaxPR,2) + ROUND(@lnFreightAmtPR,2) + ROUND(@lnmFright_TaxPR,2) - ROUND(@lnDsctamtPR,2) >  999999999999999.99
	THEN 999999999999999.99 
	ELSE ROUND(@lnTotExtenPR,2) + ROUND(@lnTotaltaxPR,2) + ROUND(@lnFreightAmtPR,2) + ROUND(@lnmFright_TaxPR,2) - ROUND(@lnDsctamtPR,2)
	END		
		
SET @lnMPTax = @lnMSPTaxT + @lnMFPTax
SET @lnMSTax = @lnMSSTaxT + @lnMFSTax
-- 12/22/14 VL added for FC
SET @lnMPTaxFC = @lnMSPTaxTFC + @lnMFPTaxFC
SET @lnMSTaxFC = @lnMSSTaxTFC + @lnMFSTaxFC		
-- 10/05/16 VL added presentation currency fields						
SET @lnMPTaxPR = @lnMSPTaxTPR + @lnMFPTaxPR
SET @lnMSTaxPR = @lnMSSTaxTPR + @lnMFSTaxPR		

/* Update Plmain from all variables*/
--12/22/14 VL added FC fields
-- 10/05/16 VL added presentation currency fields						
UPDATE PLMAIN SET TOTEXTEN = @lnTotExten, TOTTAXE = @lnTotaltax, TOTTAXF = @lnmFright_Tax, DSCTAMT = @lnDsctamt,
	INVTOTAL = @lnInvTotal, 
	-- 11/19/20 VL removed the  @llForeignTax = 1 criteria, no longer use foreign tax in cube
	--PTAX = CASE WHEN @llForeignTax = 1 THEN @lnmPTax ELSE 0 END, 
	--STAX = CASE WHEN @llForeignTax = 1 THEN @lnmSTax ELSE 0 END,
	PTAX = @lnmPTax, 
	STAX = @lnmSTax,
	TOTEXTENFC = CASE WHEN @lFCInstalled = 1 THEN @lnTotExtenFC ELSE 0 END, 
	TOTTAXEFC = CASE WHEN @lFCInstalled = 1 THEN @lnTotaltaxFC ELSE 0 END, 
	TOTTAXFFC = CASE WHEN @lFCInstalled = 1 THEN @lnmFright_TaxFC ELSE 0 END, 
	DSCTAMTFC = CASE WHEN @lFCInstalled = 1 THEN @lnDsctamtFC ELSE 0 END,
	INVTOTALFC = CASE WHEN @lFCInstalled = 1 THEN @lnInvTotalFC ELSE 0 END, 
	-- 11/19/20 VL removed the  @llForeignTax = 1 criteria, no longer use foreign tax in cube
	--PTAXFC = CASE WHEN @lFCInstalled = 1 THEN (CASE WHEN @llForeignTax = 1 THEN @lnmPTaxFC ELSE 0 END) ELSE 0 END, 
	--STAXFC = CASE WHEN @lFCInstalled = 1 THEN (CASE WHEN @llForeignTax = 1 THEN @lnmSTaxFC ELSE 0 END) ELSE 0 END,
	PTAXFC = CASE WHEN @lFCInstalled = 1 THEN @lnmPTaxFC ELSE 0 END, 
	STAXFC = CASE WHEN @lFCInstalled = 1 THEN @lnmSTaxFC ELSE 0 END,
	-- 10/05/16 VL added presentation currency fields	
	TOTEXTENPR = CASE WHEN @lFCInstalled = 1 THEN @lnTotExtenPR ELSE 0 END, 
	TOTTAXEPR = CASE WHEN @lFCInstalled = 1 THEN @lnTotaltaxPR ELSE 0 END, 
	TOTTAXFPR = CASE WHEN @lFCInstalled = 1 THEN @lnmFright_TaxPR ELSE 0 END, 
	DSCTAMTPR = CASE WHEN @lFCInstalled = 1 THEN @lnDsctamtPR ELSE 0 END,
	INVTOTALPR = CASE WHEN @lFCInstalled = 1 THEN @lnInvTotalPR ELSE 0 END, 
	-- 11/19/20 VL removed the  @llForeignTax = 1 criteria, no longer use foreign tax in cube
	--PTAXPR = CASE WHEN @lFCInstalled = 1 THEN (CASE WHEN @llForeignTax = 1 THEN @lnmPTaxPR ELSE 0 END) ELSE 0 END, 
	--STAXPR = CASE WHEN @lFCInstalled = 1 THEN (CASE WHEN @llForeignTax = 1 THEN @lnmSTaxPR ELSE 0 END) ELSE 0 END
	PTAXPR = CASE WHEN @lFCInstalled = 1 THEN @lnmPTaxPR ELSE 0 END, 
	STAXPR = CASE WHEN @lFCInstalled = 1 THEN @lnmSTaxPR ELSE 0 END

	WHERE PACKLISTNO = @lcPacklistno

/*-- 09/08/10 VL added to update Acctsrec */
SELECT @lcInvoiceno = Invoiceno 
	FROM PLMAIN
	WHERE PACKLISTNO = @lcPacklistno

-- 10/05/16 VL added presentation currency fields	
UPDATE ACCTSREC SET INVTOTAL = @lnInvTotal, INVTOTALFC = CASE WHEN @lFCInstalled = 1 THEN @lnInvTotalFC ELSE 0 END, INVTOTALPR = CASE WHEN @lFCInstalled = 1 THEN @lnInvTotalPR ELSE 0 END
	WHERE INVNO = @lcInvoiceno
	
COMMIT
END