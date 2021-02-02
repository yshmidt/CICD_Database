-- =============================================
-- Author:		Vicky Lu
-- Create date: 2010/12/14
-- Description:	Update Tax info and re-calculate credit memo total
-- 02/07/12 VL comment out code that update invstdtx table, because once CM is approved, the invstdtx will be re-created, just calculate tax amount here only
-- 02/13/12 VL changed, now Cmprices.PluniqLnk will save the original pluniqlnk, so can get the tax directly, not through inv_link
-- 03/07/12 VL Fix freight tax calculation and change rouding adjustment from 0.01 to 0.05
-- 03/09/12 VL Re-arrange @ZFreightTax field sequence to get right value from GetFreightTax4CM
-- 01/14/14 YS  reverse the changes made on 07/05/12. Do not mark as released if total =0. There are still trnasactions for cost of goods that has to take place
-- 03/20/14 VL Fix the problem that recordtype = 'O' with different qty copared to CM qty, that might cause CM with 0 price because the cm total exceeds
-- 03/27/14 VL found only need to insert to @ZSalesTax if the cmprices.taxable = 1
-- 03/05/15 VL changed in 'GetForeignTax4OneLine' sp, also comment out lots of code which are replaced by 'GetForeignTax4oneLine'
-- 03/20/15 VL added DISTINCT if sttx = 1, will have two type 'E' record (with different Tax_amt) in @ZSalesTax2
-- 01/19/17 VL Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[sp_Cmemo_Total] @gcCmUnique AS char(10) = '',@lcSaveZeroCm char(1)

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.

SET NOCOUNT ON;

BEGIN TRANSACTION
-- Declare variables
-- 03/08/12 VL changed all tax from numeric(17,2) to (17,5) so the rounding won't cause $0.01 difference
DECLARE @lnTotExten numeric(20,2), @lcSLinkAdd char(10), @llForeignTax bit, @lnTotalNoCMPR int, @lnCountCMPR int,
		@lnCmpricesExtended numeric(20,2), @llCmpricesTaxable bit, @llCmpricesFlat bit, @llCmpricesPluniqlnk char(10), @llCmpricesCmPrUniq char(10),
		@lnTotalNoSR int, @lnCounttx2 int, @lcTxTax_id char(8), @lcTxTaxDesc char(25), @lcTxGl_nbr_in char(13), 
		@lcTxGl_nbr_out char(13), @lnTxTax_rate numeric(8,4), @lcTxTaxtype char(1), @llTxPtProd bit, @llTxPtfrt bit, 
		@llTxStprod bit, @llTxStFrt bit, @llTxStTx bit, @lcTxTxTypeForn char(1), @lnSalesDiscount numeric(5,2), @lcCustno char(10), 
		@lnTotalNoSF int, @lnCount3 int, @llForeignSttx bit, @lnForeignTax_rate numeric(8,4), @lcForeignTax_id char(8),
		@lcForeignTaxtype char(1), @lcForeignGl_nbr_in char(13), @lcForeignGl_nbr_out char(13), @lcForeignTaxDesc char(25), 
		@lcNewUniqNbr char(10), @lcChkUniqValue char(10), @lnmPTax numeric(17,5), @lnmSTax numeric(17,5), 
		@lnmSPTaxt numeric(17,5), @lnmSSTaxt numeric(17,5), @lnmFPTax numeric(17,5), @lnmFSTax numeric(17,5), 
		@lnMsPtax numeric(17,5), @lnMsStax numeric(17,5), @lnMTax numeric(17,5), @lnTotalNoCR int, @lnCount4 int,
		@lnFreightAmt numeric(10,2), @lnmFright_Tax numeric(17,5), @lnCount5 int, 
		@lnDsctamt numeric(17,2), @lnCmTotal numeric(20,2), @lnTotaltax numeric(17,5),
		@lcCmmainPacklistno char(10), @lcCmMainCmType char(1), @lcCmMainCmemono char(10), @lnTotalNoINVS int, @lnCount6 int,
		@lnTotalNoINVS_P int, @lnCount7 int, @lnTotalNoINVS_E int, @lnCount8 int, @lnTotalNoINVC int, @lnCount9 int,
		@llPtProd bit, @llStProd bit, @llPtFrt bit, @llStFrt bit, @lnTotalNoINVC_P int, @lnCount10 int, @lnTotalNoINVC_E int, @lnCount11 int,
		@lnCmTotal4Inv numeric (20,2), @lnPlmainInvtotal numeric (20,2), @lcRundVar_gl char(13), @lcNewUniqNbr2 char(10), @lcNewUniqNbr3 char(10),
		@lnTotalNoCmd int, @lnCount int, @CmdCmemono char(10), @CmdPacklistno char(10), @CmdUniqueln char(10), @CmdCmQty numeric(9,2),
		@CmdInv_link char(10), @CmdCmdescr char(45), @CmdCmpricelnk char(10), @CmdPluniqlnk char(10), @CmdCmUnique char(10),
		@lcNewUniqNbrCmpr char(10), @lcNewUniqNbrCmpr2 char(10), @SopDescriptio char(45), @SopQuantity numeric(10,2), @SopPrice numeric(14,5), @SopTaxable bit, 
		@SopFlat bit, @SopRecordtype char(1), @SopSaletypeid char(10), @SopPl_gl_nbr char(13), @SopPlpricelnk char(13), 
		@SopCog_gl_nbr char(13), @lnTotalNo2 int, @lnCount2 int, @lcChkPlpricelnk char(10), @lcNewUniqNbrCmpr3 char(10), @lcNewUniqNbrCmpr4 char(10),
		@lnSumCmQty numeric(9,2), @lnDifferenceQty numeric(9,2), @lnRecvQty numeric(9,2), @lcFrt_gl_no char(13), @lcFc_gl_no char(13),
		@lcDisc_gl_no char(13), @lnTotalNo22 int, @lnCntTaxTotal int, @lnCntTax int, @lnCntTaxTotalINVS_E int, @lnCntTaxINVS_E int,
		@lnCntTaxTotalINVS_P int, @lnCntTaxINVS_P int, @lnCntTaxTotalINVC int, @lnCntTaxINVC int, @lnCntTaxTotalINVC_E int, @lnCntTaxINVC_E int,
		@lnCntTaxTotalINVC_P int, @lnCntTaxINVC_P int, @lcOriginInvoiceno char(10), @lcCmmainSono char(10), @lcOriginPacklistno char(10),
		@lnTotalNoSF_P int, @lnTotalNoSF_E int, @SopOrigPluniqlnk char(10), @pIsStandAloneRMA bit, @lcExecString char(100),
		@lnCmpricesExtended2 numeric(20,2), @llForeignPtProd bit, @llForeignPtFrt bit, @llForeignStProd bit, @llForeignStFrt bit, @lcCmpricesCmpricelnk char(10),
		@SopPriceFC numeric(14,5), @lnTotExtenFC numeric(20,2), @lnDsctamtFC numeric(17,2), @lnCmpricesExtendedFC numeric(20,2), @lnMSPTaxTFC numeric(17,5),
		@lnMSSTaxTFC numeric(17,5), @lnTotaltaxFC numeric(17,5), @lnmFPTaxFC numeric(17,5), @lnmFSTaxFC numeric(17,5), @lnmFright_TaxFC numeric(17,5),
		@lnCmTotalFC numeric(20,2), @lnFreightAmtFC numeric(10,2), @lnmPTaxFC numeric(17,5), @lnmSTaxFC numeric(17,5), @lnCmTotal4InvFC numeric (20,2),
		@lnPlmainInvtotalFC numeric (20,2), @lnMsPtaxFC numeric(17,5), @lnMsStaxFC numeric(17,5),
		-- 01/19/17 VL added functional currency fields
		@lnTotExtenPR numeric(20,2), @lnCmpricesExtendedPR numeric(20,2),@lnmPTaxPR numeric(17,5), @lnmSTaxPR numeric(17,5), @lnmSPTaxtPR numeric(17,5), 
		@lnmSSTaxtPR numeric(17,5), @lnmFPTaxPR numeric(17,5), @lnmFSTaxPR numeric(17,5), @lnMsPtaxPR numeric(17,5), @lnMsStaxPR numeric(17,5), @lnMTaxPR numeric(17,5),
		@lnFreightAmtPR numeric(10,2), @lnmFright_TaxPR numeric(17,5), @lnDsctamtPR numeric(17,2), @lnCmTotalPR numeric(20,2), @lnTotaltaxPR numeric(17,5),
		@lnCmTotal4InvPR numeric (20,2), @lnPlmainInvtotalPR numeric (20,2),@SopPricePR numeric(14,5),@lnCmpricesExtended2PR numeric(20,2) ;
 
-- in here the @@lcCmmainPacklistno is the RMAR Receiver no, in invstdtx, there is no CmUnique field, will use packlistno and Pluniqlnk to get right record

-- 03/11/15 VL added FC fields
-- 01/19/17 VL added functional currency fields
DECLARE @ZCmprices TABLE (nrecno int identity, CmExtended numeric (20,2), Taxable bit, Flat bit, PlUniqlnk char(10), CmPrUniq char(10), Cmpricelnk char(10), CmextendedFC numeric(20,2), CmextendedPR numeric(20,2));
-- 03/05/15 VL comment out, it's not used anymore
--DECLARE @ZShipTaxSR TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Taxtype char(1), PtProd bit, Ptfrt bit, Stprod bit, StFrt bit, StTx bit);
--DECLARE @ZShipTaxSF TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Taxtype char(1), PtProd bit, Ptfrt bit, Stprod bit, StFrt bit, StTx bit, TxTypeForn char(1));
--DECLARE @ZShipTaxSF_P TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Taxtype char(1), PtProd bit, Ptfrt bit, Stprod bit, StFrt bit, StTx bit, TxTypeForn char(1));
--DECLARE @ZShipTaxSF_E TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Taxtype char(1), PtProd bit, Ptfrt bit, Stprod bit, StFrt bit, StTx bit, TxTypeForn char(1));						
--DECLARE @ZShipTaxCR TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Taxtype char(1), PtProd bit, Ptfrt bit, Stprod bit, StFrt bit, StTx bit);
--DECLARE @ZShipTaxINVS TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Tax_Amt numeric(12,4), Tax_type char(1), TxTypeForn char(1));
--DECLARE @ZShipTaxINVS_P TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Tax_type char(1), TxTypeForn char(1));
--DECLARE @ZShipTaxINVS_E TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Tax_type char(1), TxTypeForn char(1));
--DECLARE @ZShipTaxINVC TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Tax_Amt numeric(12,4), Tax_type char(1), TxTypeForn char(1));
--DECLARE @ZShipTaxINVC_P TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Tax_type char(1), TxTypeForn char(1));
--DECLARE @ZShipTaxINVC_E TABLE (nrecno int identity, Tax_id char(8), TaxDesc char(25), Gl_nbr_in char(13), Gl_nbr_out char(13),
--						Tax_rate numeric(8,4), Tax_type char(1), TxTypeForn char(1));	
-- 03/05/15 VL End

-- 03/08/12 VL create a temp table to save the sales tax calculation result from EXEC GetForeignTax4OneLine (for each cmprices)
-- 03/11/15 VL added 5 tax setting fields and FC fields
-- 01/19/17 VL added functional currency fields
DECLARE @ZSalesTax TABLE (YesNo bit, Packlistno char(10), PluniqLnk char(10), Linkadd char(10), Tax_id char(8), TaxDesc char(25), 
							Gl_nbr_in char(13), Gl_nbr_out char(13), Tax_Rate numeric(8,4), Tax_Type char(1), Tax_Amt numeric(12,4), 
							Tax_AmtFC numeric(12,4), TxTypeForn char(1),	Ptprod bit, PtFrt bit, StProd bit, StFrt bit, Sttx bit,
							Tax_AmtPR numeric(12,4))			
																						
-- 03/05/15 VL added next one for updating Cmpricestax
-- 03/11/15 VL added Tax_AmtFC
-- 01/19/17 VL added functional currency fields
DECLARE @ZSalesTax2 TABLE (YesNo bit, Packlistno char(10), PluniqLnk char(10), Linkadd char(10), Tax_id char(8), TaxDesc char(25), 
							Gl_nbr_in char(13), Gl_nbr_out char(13), Tax_Rate numeric(8,4), Tax_Type char(1), Tax_Amt numeric(12,4), 
							Tax_AmtFC numeric(12,4), TxTypeForn char(1), Ptprod bit, PtFrt bit, StProd bit, StFrt bit, Sttx bit,
							Tax_AmtPR numeric(12,4))									

-- 03/08/12 VL create a temp table to save the freight tax calculation result from EXEC GetFreightTax4CM
-- 03/05/15 VL added 5 tax setting fields
-- 03/11/15 VL added FC fields
-- 01/19/17 VL added functional currency fields
DECLARE @ZFreightTax TABLE (YesNo bit, Invoiceno char(10), Packlistno char(10), Tax_id char(8), TaxDesc char(25), Linkadd char(10), 
							Gl_nbr_in char(13), Gl_nbr_out char(13), Tax_Rate numeric(8,4), Tax_Amt numeric(12,4), Tax_AmtFC numeric(12,4), 
							Tax_Type char(1), TxTypeForn char(1), Ptprod bit, PtFrt bit, StProd bit, StFrt bit, Sttx bit,
							Tax_AmtPR numeric(12,4))									
							
-- Get values
-- 03/11/15 VL assign 0 to FC fields
-- 01/19/17 VL added functional currency fields
SELECT @lnmPTax = 0, @lnmSTax = 0, @lnmSPTaxt = 0, @lnmSSTaxt = 0, @lnmFPTax = 0, @lnmFSTax = 0, @lnMsPtax = 0,	
		@lnMsStax = 0, @lnMTax = 0, @lnmFright_Tax = 0, @lnTotaltax = 0, @lnCntTaxINVC_P = 0, @lnCntTaxINVC_E = 0, 
		@lnTxTax_rate = 0, @lnmSPTaxtFC = 0, @lnmSSTaxtFC = 0, @lnTotaltaxFC = 0, @lnmFPTaxFC = 0, @lnmFSTaxFC = 0,
		@lnmFright_TaxFC = 0, @lnmPTaxFC = 0, @lnmSTaxFC = 0, @lnMsPtaxFC = 0, @lnMsStaxFC = 0,
		@lnmPTaxPR = 0, @lnmSTaxPR = 0, @lnmSPTaxtPR = 0, @lnmSSTaxtPR = 0, @lnmFPTaxPR = 0, @lnmFSTaxPR = 0, @lnMsPtaxPR = 0,	
		@lnMsStaxPR = 0, @lnMTaxPR = 0, @lnmFright_TaxPR = 0, @lnTotaltaxPR = 0 ;
		
SELECT @lcSLinkAdd = LinkAdd, @lcCustno = Custno, @lnFreightAmt = Cm_frt, @lcCmmainPacklistno = Packlistno, 
	@lcCmMainCmType = CmType, @lcCmmainSono = Sono, @lcCmMainCmemono = Cmemono, @lnFreightAmtFC = Cm_frtFC,
	-- 01/19/17 VL added functional currency fields
	@lnFreightAmtPR = Cm_frtPR
	FROM CmMain WHERE CmUnique = @gcCmUnique
	
SELECT @lcOriginInvoiceno = Invoiceno FROM SOMAIN WHERE SONO = @lcCmmainSono

IF @lcOriginInvoiceno<>''
	SELECT @lcOriginPacklistno = Packlistno FROM PLMAIN WHERE INVOICENO = @lcOriginInvoiceno
ELSE
	SELECT @lcOriginPacklistno=''

SET @pIsStandAloneRMA = CASE WHEN @lcOriginInvoiceno <> '' THEN 0 ELSE 1 END

SELECT @llForeignTax = ForeignTax FROM Shipbill	WHERE LinkAdd = @lcSLinkAdd
-- 03/05/15 VL comment out, it's not used anymore
--SELECT @llForeignSttx = ShipTax.Sttx, @lnForeignTax_rate = ShipTax.Tax_rate, @lcForeignTax_id = ShipTax.Tax_id,	
--		@lcForeignTaxtype = ShipTax.Taxtype, @lcForeignGl_nbr_in = Gl_nbr_in, @lcForeignGl_nbr_out = Gl_nbr_out, @lcForeignTaxDesc = ShipTax.TaxDesc
--	FROM ShipTax, TaxTabl
--	WHERE ShipTax.Tax_id = TaxTabl.Tax_id  
--	AND LINKADD = @lcSLinkAdd
--	AND CUSTNO = @lcCustno
	--AND ShipTax.TaxType = 'E' 

-- 03/04/15 VL comment out, found it's not used anymore
--SELECT @llPtProd = PtProd, @llPtFrt = PtFrt FROM ShipTax WHERE LINKADD = @lcSLinkAdd AND CUSTNO = @lcCustno AND TaxType = 'P'
--SELECT @llStProd = StProd, @llStFrt = StFrt FROM ShipTax WHERE LINKADD = @lcSLinkAdd AND CUSTNO = @lcCustno AND TaxType = 'E'

SELECT @lcRundVar_gl = RundVar_gl FROM InvSetup
SELECT @lcFrt_gl_no = Frt_gl_no, @lcFc_gl_no = Fc_gl_no, @lcDisc_gl_no = Disc_gl_no FROM ARSetup
	
SELECT @lnSalesDiscount = Discount FROM SaleDsct, Customer WHERE SaleDsct.SALEDSCTID = CUSTOMER.SALEDSCTID AND Customer.Custno = @lcCustno

IF @@ROWCOUNT = 0
	SELECT @lnSalesDiscount = 0;

-- 03/05/15 VL comment out, it's not used anymore
--INSERT @ZShipTaxSR SELECT ShipTax.Tax_id, ShipTax.TaxDesc, Gl_nbr_in, Gl_nbr_out, ShipTax.Tax_rate, ShipTax.Taxtype, 
--		ShipTax.PtProd, ShipTax.Ptfrt, ShipTax.Stprod, ShipTax.StFrt, ShipTax.StTx 
--					FROM ShipTax, TaxTabl
--					WHERE ShipTax.Tax_id = TaxTabl.Tax_id
--					AND LINKADD = @lcSLinkAdd
--					AND CUSTNO = @lcCustno 
--					AND ShipTax.TAXTYPE = 'S'
--					AND RECORDTYPE = 'S'
--SET @lnTotalNoSR = @@ROWCOUNT;		
			
--INSERT @ZShipTaxSF SELECT ShipTax.Tax_id, ShipTax.TaxDesc, Gl_nbr_in, Gl_nbr_out, ShipTax.Tax_rate, ShipTax.Taxtype, 
--		ShipTax.PtProd, ShipTax.Ptfrt, ShipTax.Stprod, ShipTax.StFrt, ShipTax.StTx, ShipTax.Taxtype
--					FROM ShipTax, TaxTabl
--					WHERE ShipTax.Tax_id = TaxTabl.Tax_id 
--					AND LINKADD = @lcSLinkAdd
--					AND CUSTNO = @lcCustno 
--					AND (ShipTax.TAXTYPE = 'P'
--					OR ShipTax.TaxType = 'E')
--SET @lnTotalNoSF = @@ROWCOUNT;		

--INSERT @ZShipTaxSF_P SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Taxtype, PtProd, Ptfrt, Stprod, StFrt, StTx, Taxtype
--					FROM @ZShipTaxSF
--					WHERE TAXTYPE = 'P'

--SET @lnTotalNoSF_P = @@ROWCOUNT;		

--INSERT @ZShipTaxSF_E SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Taxtype, PtProd, Ptfrt, Stprod, StFrt, StTx, Taxtype
--					FROM @ZShipTaxSF
--					WHERE TAXTYPE = 'E'

--SET @lnTotalNoSF_E = @@ROWCOUNT;		

--INSERT @ZShipTaxCR SELECT ShipTax.Tax_id, ShipTax.TaxDesc, Gl_nbr_in, Gl_nbr_out, ShipTax.Tax_rate, ShipTax.Taxtype, 
--		ShipTax.PtProd, ShipTax.Ptfrt, ShipTax.Stprod, ShipTax.StFrt, ShipTax.StTx 
--					FROM ShipTax, TaxTabl
--					WHERE ShipTax.Tax_id = TaxTabl.Tax_id
--					AND LINKADD = @lcSLinkAdd
--					AND CUSTNO = @lcCustno 
--					AND ShipTax.TAXTYPE = 'C'
--					AND RECORDTYPE = 'S'
--SET @lnTotalNoCR = @@ROWCOUNT;		


--INSERT @ZShipTaxINVC SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_Amt, Tax_type, TxTypeForn
--					FROM Invstdtx
--					WHERE PACKLISTNO IN 
--						(SELECT PACKLISTNO
--							FROM PLMAIN
--							WHERE INVOICENO = @lcOriginInvoiceno)
--					AND Invoiceno = ''
--					AND Tax_Type = 'C'

--SET @lnTotalNoINVC = @@ROWCOUNT;	

--INSERT @ZShipTaxINVC_P SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_type, TxTypeForn
--					FROM @ZShipTaxINVC
--					WHERE TxTypeForn = 'P'
--SET @lnTotalNoINVC_P = @@ROWCOUNT;
--SET @lnCntTaxTotalINVC_P = @lnTotalNoINVC_P + @lnCntTaxINVC_P;

--INSERT @ZShipTaxINVC_E SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_type, TxTypeForn
--					FROM @ZShipTaxINVC
--					WHERE TxTypeForn = 'E'
--SET @lnTotalNoINVC_E = @@ROWCOUNT;	
--SET @lnCntTaxTotalINVC_E = @lnTotalNoINVC_E + @lnCntTaxINVC_E;

-- 02/13/12 VL added OrigPlUniqlnk
-- 03/11/15 VL added FC fields
-- 01/19/17 VL added functional currency fields
DECLARE @ZSoPrices TABLE (nrecno int identity, Descriptio char(45), Quantity numeric(10,2), Price numeric(14,5), Taxable bit, Flat bit, Recordtype char(1),
		Saletypeid char(10), Pl_gl_nbr char(13), Plpricelnk char(13), Cog_gl_nbr char(13), OrigPluniqLnk char(10), PriceFC numeric(14,5), PricePR numeric(14,5))			

DECLARE @ZCmdetail TABLE (nrecno int identity, Cmemono char(10), Packlistno char(10), Uniqueln char(10), CmQty numeric(9,2),
		Inv_Link char(10), Cmdescr char(45), Cmpricelnk char(10), Pluniqlnk char(10), CmUnique char(10));

-----------------------------------------------------------------------------
/* Update Cmprices records*/
-----------------------------------------------------------------------------
-- @lnCount2 is used in counting record for Soprices, because use DELETE FROM, the nrecno will keep increase even delete those records, so need to 
-- change WHILE @lnTotalNo2>@lnCount2 later
SET @lnCount2=0; 

INSERT @ZCmdetail SELECT Cmemono, Packlistno, Uniqueln, CmQty, Inv_link, CmDescr, Cmpricelnk, Pluniqlnk, CmUnique
		FROM Cmdetail
		WHERE CmUnique = @gcCmUnique

SET @lnTotalNoCmd = @@ROWCOUNT;
-- First, check all soprices and insert or update plprices if necessary	
IF (@lnTotalNoCmd>0)
BEGIN
	SET @lnCount=0;
	WHILE @lnTotalNoCmd>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @CmdCmemono = Cmemono, @CmdPacklistno = Packlistno, @CmdUniqueln = Uniqueln, @CmdCmQty = CmQty,
			@CmdInv_link = Inv_link, @CmdCmdescr = Cmdescr, @CmdCmpricelnk = Cmpricelnk, @CmdPluniqlnk = Pluniqlnk, @CmdCmUnique = CmUnique
		FROM @ZCmdetail WHERE nrecno = @lnCount	
		IF (@@ROWCOUNT<>0)
		BEGIN
			-- Didn't find how to create Uniqueln with '*' now, but just convert from VFP for now, will check later
			IF SUBSTRING(@CmdUniqueln,1,1) = '*'
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbrCmpr OUTPUT
				EXEC sp_GenerateUniqueValue @lcNewUniqNbrCmpr2 OUTPUT
				-- 08/29/11 VL removed CmTaxable from cmprices table, use Taxable to calculate
				-- 02/13/12 VL don't save Pluniqlnk with new unique value any more, now will save original plprices.pluniqlnk
				-- 03/11/15 VL added FC fields
				-- 01/19/17 VL added functional currency fields
				INSERT INTO CMPRICES (Cmemono, Packlistno, Uniqueln, Descript, CmQuantity, Cmprice, Cmextended,  
								Taxable, Flat, Inv_link, Recordtype, Is_restock, RestockQty, Scrapqty, Amortflag, Salestype, 
								Pl_gl_nbr, Plpricelnk, Pluniqlnk, Cog_gl_nbr, Cmpricelnk, Cmpruniq, Cmunique, CmpriceFC, CmExtendedFC, CmpricePR, CmextendedPR) 
				VALUES (@CmdCmemono, @CmdPacklistno, @CmdUniqueln, @CmdCmdescr, @CmdCmQty, 0, 0, 
						0,0,@CmdInv_link, 'O', 1, @CmdCmQty, 0, '', '', 
						'','','','', @CmdCmpricelnk, @lcNewUniqNbrCmpr2, @CmdCmUnique,0,0,0,0)
			END
			
			-- From RMA, need to check Soprices.RecordType
			IF SUBSTRING(@CmdUniqueln,1,1) <> '*'
			BEGIN
				DELETE FROM @ZSoPrices WHERE 1=1	-- Delete all old records

				INSERT @ZSoPrices 
				-- 01/19/17 VL added functional currency fields
				SELECT Descriptio, Quantity, Price, Taxable, Flat, Recordtype, Saletypeid, Pl_gl_nbr, Plpricelnk, Cog_gl_nbr, OrigPlUniqlnk, PriceFC,PricePR
					FROM SOPRICES 
					WHERE UNIQUELN = @CmdUniqueln
				
				-- Check each soprices to decide what's the qty should be inserted to Cmprices (for each cmdetail.uniqueln)
				SET @lnTotalNo2 = @@ROWCOUNT
				SET @lnTotalNo22 =  @lnTotalNo2 + @lnCount2
				IF (@lnTotalNo2>0)
				BEGIN
					WHILE @lnTotalNo22>@lnCount2
					BEGIN	
						SET @lnCount2=@lnCount2+1;
						-- 02/13/12 VL added OrigPluniqlnk
						-- 03/11/15 VL added FC fields
						-- 01/19/17 VL added functional currency fields
						SELECT @SopDescriptio = Descriptio, @SopQuantity = Quantity, @SopPrice = Price, @SopTaxable = Taxable, 
							@SopFlat = Flat, @SopRecordtype = Recordtype, @SopSaletypeid = Saletypeid, @SopPl_gl_nbr = Pl_gl_nbr,
							@SopPlpricelnk = Plpricelnk, @SopCog_gl_nbr = Cog_gl_nbr, @SopOrigPluniqlnk = OrigPluniqLnk, @SopPriceFC = PriceFC,
							@SopPricePR = PricePR
						FROM @ZSoPrices WHERE nrecno = @lnCount2
						
						IF (@@ROWCOUNT<>0)
						BEGIN	
							BEGIN	
							IF @SopFlat = 1
								
								BEGIN
								
								-- Check if this Flat record has been created in other Cmprices record
								SELECT @lcChkPlpricelnk = Plpricelnk 
									FROM Cmprices 
									WHERE Cmprices.Plpricelnk = @SopPlpricelnk
								IF @@ROWCOUNT = 0	-- No other CM created for this flat price item
								BEGIN
									EXEC sp_GenerateUniqueValue @lcNewUniqNbrCmpr3 OUTPUT
									EXEC sp_GenerateUniqueValue @lcNewUniqNbrCmpr4 OUTPUT

									IF @SopRecordtype = 'P'
										BEGIN
										-- 08/29/11 VL removed CmTaxable from cmprices table, use Taxable to calculate
										-- 02/13/12 VL save cmprices.Pluniqlnk from @lcNewUniqNbrCmpr3 to OrigPluniqlnk
										-- 03/11/15 VL added FC fields
										-- 01/19/17 VL added functional currency fields
										INSERT INTO Cmprices (Cmemono, Packlistno, Uniqueln, Descript, CmQuantity, Cmprice, Cmextended,  
											Taxable, Flat, Inv_link, Recordtype, Is_restock, RestockQty, Scrapqty, Amortflag, Salestype, 
											Pl_gl_nbr, Plpricelnk, Pluniqlnk, Cog_gl_nbr, Cmpricelnk, Cmpruniq, CmUnique, CmpriceFC, CmextendedFC,CmpricePR, CmextendedPR) 
										VALUES (@CmdCmemono, @CmdPacklistno, @CmdUniqueln, @SopDescriptio, @CmdCmQty, 
												@SopPrice, @SopPrice, @SopTaxable, @SopFlat, @CmdInv_link, @SopRecordtype, 1, @CmdCmQty, 0, '', 
												@SopSaletypeid, @SopPl_gl_nbr, @SopPlpricelnk, @SopOrigPluniqlnk, @SopCog_gl_nbr, 
												@CmdCmpricelnk, @lcNewUniqNbrCmpr4, @CmdCmUnique, @SopPriceFC, @SopPriceFC,@SopPricePR, @SopPricePR)	
										END			
									ELSE
										-- @SopRecordtype = 'O'
										BEGIN
										-- 02/13/12 VL save cmprices.Pluniqlnk from @lcNewUniqNbrCmpr3 to OrigPluniqlnk
										-- 03/11/15 VL added FC fields
										-- 01/19/17 VL added functional currency fields
										INSERT INTO Cmprices (Cmemono, Packlistno, Uniqueln, Descript, CmQuantity, Cmprice, Cmextended, 
											Taxable, Flat, Inv_link, Recordtype, Is_restock, RestockQty, Scrapqty, Amortflag, Salestype, 
											Pl_gl_nbr, Plpricelnk, Pluniqlnk, Cog_gl_nbr, Cmpricelnk, Cmpruniq, CmUnique, CmpriceFC, CmextendedFC, CmpricePR, CmextendedPR) 
										VALUES (@CmdCmemono, @CmdPacklistno, @CmdUniqueln, @SopDescriptio, @CmdCmQty, 
												@SopPrice, @SopPrice, @SopTaxable, @SopFlat, @CmdInv_link, @SopRecordtype, 1, @CmdCmQty, 0, '', 
												@SopSaletypeid, @SopPl_gl_nbr, @SopPlpricelnk, @SopOrigPluniqlnk, @SopCog_gl_nbr, 
												@CmdCmpricelnk, @lcNewUniqNbrCmpr4, @CmdCmUnique, @SopPriceFC, @SopPriceFC, @SopPricePR, @SopPricePR)	
										END			
											
								END	
								END	
							ELSE
								
								-- @SopFlat = 0
								BEGIN
								
									EXEC sp_GenerateUniqueValue @lcNewUniqNbrCmpr3 OUTPUT
									EXEC sp_GenerateUniqueValue @lcNewUniqNbrCmpr4 OUTPUT

									IF @SopRecordtype = 'P'
										BEGIN
										-- 08/29/11 VL removed CmTaxable from cmprices table, use Taxable to calculate
										-- 02/13/12 VL save cmprices.Pluniqlnk from @lcNewUniqNbrCmpr3 to OrigPluniqlnk
										-- 03/11/15 VL added FC fields
										-- 01/19/17 VL added functional currency fields
										INSERT INTO Cmprices (Cmemono, Packlistno, Uniqueln, Descript, CmQuantity, Cmprice, Cmextended,  
											Taxable, Flat, Inv_link, Recordtype, Is_restock, RestockQty, Scrapqty, Amortflag, Salestype, 
											Pl_gl_nbr, Plpricelnk, Pluniqlnk, Cog_gl_nbr, Cmpricelnk, Cmpruniq, CmUnique, CmpriceFC, CmextendedFC,CmpricePR, CmextendedPR) 
										VALUES (@CmdCmemono, @CmdPacklistno, @CmdUniqueln, @SopDescriptio, @CmdCmQty, 
												@SopPrice, @CmdCmQty*@SopPrice, @SopTaxable, @SopFlat, @CmdInv_link, @SopRecordtype, 1, @CmdCmQty, 0, '', 
												@SopSaletypeid, @SopPl_gl_nbr, @SopPlpricelnk, @SopOrigPluniqlnk, @SopCog_gl_nbr, 
												@CmdCmpricelnk, @lcNewUniqNbrCmpr4, @CmdCmUnique, @SopPriceFC, @CmdCmQty*@SopPriceFC, @SopPricePR, @CmdCmQty*@SopPricePR)	
										END			
									ELSE
										-- @SopRecordtype = 'O'
										BEGIN
											SET @lnSumCmQty = 0;
											SET @lnDifferenceQty = 0;
											SET @lnRecvQty = 0;

											SELECT @lnSumCmQty = ISNULL(SUM(CmQuantity),0)
												FROM CMPRICES
												WHERE PlpriceLnk = @SopPlpricelnk
											-- 03/20/14 VL changed to add ABS() because in RMA, it's negative, but in cmprices, it uses positive
											SET @lnDifferenceQty = ABS(@SopQuantity) - @lnSumCmQty;
											
											IF @lnDifferenceQty <> 0
											BEGIN
												IF @lnDifferenceQty < @CmdCmQty
													SET @lnRecvQty = CASE WHEN @lnDifferenceQty >=0 THEN @lnDifferenceQty ELSE 0 END
												ELSE
													SET @lnRecvQty = @CmdCmQty
											-- 08/29/11 VL removed CmTaxable from cmprices table, use Taxable to calculate			
											-- 02/13/12 VL save cmprices.Pluniqlnk from @lcNewUniqNbrCmpr3 to OrigPluniqlnk		
											-- 03/20/14 VL changed insert value for CmQuantity from @CmdCmQty to @lnRecvQty							
											-- 03/11/15 VL added FC fields
											-- 01/19/17 VL added functional currency fields
											INSERT INTO Cmprices (Cmemono, Packlistno, Uniqueln, Descript, CmQuantity, Cmprice, Cmextended,  
												Taxable, Flat, Inv_link, Recordtype, Is_restock, RestockQty, Scrapqty, Amortflag, Salestype, 
												Pl_gl_nbr, Plpricelnk, Pluniqlnk, Cog_gl_nbr, Cmpricelnk, Cmpruniq, CmUnique, CmpriceFC, CmextendedFC,CmpricePR, CmextendedPR) 
											VALUES (@CmdCmemono, @CmdPacklistno, @CmdUniqueln, @SopDescriptio, @lnRecvQty, 
													@SopPrice, @lnRecvQty*@SopPrice, @SopTaxable, @SopFlat, @CmdInv_link, @SopRecordtype, 1, 
													@CmdCmQty, 0, '', @SopSaletypeid, @SopPl_gl_nbr, @SopPlpricelnk, @SopOrigPluniqlnk, @SopCog_gl_nbr, 
													@CmdCmpricelnk, @lcNewUniqNbrCmpr4, @CmdCmUnique, @SopPriceFC, @lnRecvQty*@SopPriceFC,@SopPricePR, @lnRecvQty*@SopPricePR)	
											END
										END			
											
								END									
							END
						END
					END	
				END
			END
			-- END of SUBSTRING(@CmdUniqueln,1,1) <> '*'
			
			INSERT INTO Cmadj (Packlistno,Uniqueln,SavedDate,RecvQty, CmUnique)
				VALUES (@CmdPacklistno,@CmdUniqueln,GETDATE(),@CmdCmQty, @CmdCmUnique)
	
		END
	END
END	
												
------------------------------------------------------------------------------
/* Update all Cmprices */
-------------------------

-- 03/11/15 VL added FC fields
-- 01/19/17 VL added functional currency fields
UPDATE CmPrices 
	SET CmEXTENDED = CASE WHEN FLAT = 1 THEN CASE WHEN Cmquantity <> 0 THEN Cmprice ELSE 0 END ELSE Cmquantity * Cmprice END,
		CmEXTENDEDFC = CASE WHEN FLAT = 1 THEN CASE WHEN Cmquantity <> 0 THEN CmpriceFC ELSE 0 END ELSE Cmquantity * CmpriceFC END,
		CmEXTENDEDPR = CASE WHEN FLAT = 1 THEN CASE WHEN Cmquantity <> 0 THEN CmpricePR ELSE 0 END ELSE Cmquantity * CmpricePR END
	WHERE Cmunique = @gcCmUnique

/* TotExten*/
-------------------------
-- 03/11/15 VL added FC fields
-- 01/19/17 VL added functional currency fields
SELECT @lnTotExten = SUM(CmExtended), @lnTotExtenFC = SUM(CmExtendedFC), @lnTotExtenPR = SUM(CmExtendedPR) FROM Cmprices WHERE Cmunique = @gcCmUnique

/* Dsctamt*/
------------------------------
-- 03/11/15 VL added FC fields
SET @lnDsctamt = ROUND(@lnTotExten*@lnSalesDiscount/100,2)
SET @lnDsctamtFC = ROUND(@lnTotExtenFC*@lnSalesDiscount/100,2)
-- 01/19/17 VL added functional currency fields
SET @lnDsctamtPR = ROUND(@lnTotExtenPR*@lnSalesDiscount/100,2)
		
/* TotTaxe*/
-------------------------
-- Delete first, will insert later	
-- 02/07/12 VL comment out here, see detail above	
--DELETE FROM InvStdTx WHERE Packlistno = @lcCmmainPacklistno AND Tax_Type = 'S'

-- 08/29/11 VL removed CmTaxable from cmprices table, use Taxable to calculate
-- 03/11/15 VL added FC fields
-- 01/19/17 VL added functional currency fields
INSERT @ZCmprices 
	SELECT CmExtended, Taxable, Flat, Pluniqlnk, CmPrUniq, Cmpricelnk, CmExtendedFC, CmExtendedPR
	FROM CMPRICES  
	WHERE Cmunique = @gcCmunique
	
--Error, no Cmprices is found
SET @lnTotalNoCMPR = @@ROWCOUNT;	
IF @lnTotalNoCMPR = 0	
	BEGIN
	--set @lRollBack=1
	RAISERROR('Programming error, can not find associated RMA order price items. This operation will be cancelled. Please try again',1,1)
	ROLLBACK TRANSACTION
	RETURN
END

SET @lnCntTax = 0;
SET @lnCntTaxINVS_P = 0;
SET @lnCntTaxINVS_E = 0;

-- SCAN through Cmprices
BEGIN	
	SET @lnCountCMPR=0;
	WHILE @lnTotalNoCMPR>@lnCountCMPR
	BEGIN	
		SET @lnCountCMPR=@lnCountCMPR+1;
		-- 03/05/15 VL added Cmpricelnk
		-- 03/11/15 VL added FC fields
		-- 01/19/17 VL added functional currency fields
		SELECT @lnCmpricesExtended = CmExtended, @llCmpricesTaxable = Taxable, @llCmpricesFlat = Flat, @llCmpricesPlUniqLnk = PlUniqLnk,
			@llCmpricesCmPrUniq = CmprUniq, @lcCmpricesCmpricelnk = Cmpricelnk, @lnCmpricesExtendedFC = CmExtendedFC, @lnCmpricesExtendedPR = CmExtendedPR
			FROM @ZCmprices WHERE nrecno = @lnCountCMPR
		BEGIN
		IF (@@ROWCOUNT<>0)
		-- 03/08/12 VL comment out old code to use the same tax calculation used in CM
			--DELETE FROM @ZShipTaxINVS WHERE 1=1
			--DELETE FROM @ZShipTaxINVS_P WHERE 1=1
			--DELETE FROM @ZShipTaxINVS_E WHERE 1=1
			
			---- re-generate tax for this cmprices records
			---- 02/13/12 VL changed, now Cmprices.PluniqLnk will save the original pluniqlnk, so can get the tax directly, not through inv_link
			----INSERT @ZShipTaxINVS SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_Amt, Tax_type, TxTypeForn
			----					FROM Invstdtx
			----					WHERE Pluniqlnk IN 
			----					(SELECT Pluniqlnk 
			----						FROM Plprices 
			----						WHERE Inv_link IN 
			----							(SELECT Inv_link 
			----								FROM Cmprices 
			----								WHERE CmprUniq = @llCmpricesCmPrUniq)
			----						AND Taxable = 1)
			----					AND Invoiceno= ''
			----					AND TAX_TYPE = 'S'
			--INSERT @ZShipTaxINVS SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_Amt, Tax_type, TxTypeForn
			--				FROM Invstdtx
			--				WHERE Pluniqlnk IN 
			--					(SELECT PlUniqlnk 
			--							FROM Cmprices 
			--							WHERE CmprUniq = @llCmpricesCmPrUniq
			--					AND Taxable = 1)
			--				AND Invoiceno= ''
			--				AND TAX_TYPE = 'S'
											
			--SET @lnTotalNoINVS = @@ROWCOUNT;	
			--SET @lnCntTaxTotal = @lnTotalNoINVS + @lnCntTax;

			--INSERT @ZShipTaxINVS_P SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_type, TxTypeForn
			--					FROM @ZShipTaxINVS
			--					WHERE TxTypeForn = 'P'
			--SET @lnTotalNoINVS_P = @@ROWCOUNT;
			--SET @lnCntTaxTotalINVS_P = @lnTotalNoINVS_P + @lnCntTaxINVS_P;

			--INSERT @ZShipTaxINVS_E SELECT Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_type, TxTypeForn
			--					FROM @ZShipTaxINVS
			--					WHERE TxTypeForn = 'E'
			--SET @lnTotalNoINVS_E = @@ROWCOUNT;	
			--SET @lnCntTaxTotalINVS_E = @lnTotalNoINVS_E + @lnCntTaxINVS_E;
			
			---- End of tax source
			
			--SELECT @lnMsPtax = 0, @lnMsSTax = 0, @lnMTax = 0;
				
			--IF @llCmpricesTaxable = 1
			--	BEGIN
				
			--	-- Regular Tax
			--	IF @llForeignTax = 0 -- Regular tax
			--		BEGIN
			--		IF @lcCmMainCmType = 'I' AND @lcOriginInvoiceno <> ''	-- credit memo from invoice, sales tax has to be the same as invoice
			--			BEGIN
			--				WHILE @lnCntTaxTotal>@lnCntTax
			--				BEGIN
			--				SET @lnCntTax=@lnCntTax+1;		
			--				SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
			--						@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Tax_type, @lcTxTxTypeForn = TxTypeForn
			--				FROM @ZShipTaxINVS WHERE nrecno = @lnCntTax
							
			--				IF (@@ROWCOUNT<>0)
			--				BEGIN
			--					-- Get unique value for PlUniqLnk
			--					BEGIN
			--						WHILE (1=1)
			--						BEGIN
			--							EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			--							SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
			--							IF (@@ROWCOUNT<>0)
			--								CONTINUE
			--							ELSE
			--								BREAK
			--						END			
			--					END
								
			--					SET @lnMTax = @lnMTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);	
			--					-- 02/07/12 VL comment out here, see detail above			
			--					--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
			--					--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq) 
			--					--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--					--			-ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), @lcTxTaxtype, @lcNewUniqNbr)
			--				END
			--				END
			--			END
			--		ELSE
			--		-- Not from invoice, just calculate with regular tax
			--			BEGIN
			--			SET @lnCounttx2=0;
			--			WHILE @lnTotalNoSR>@lnCounttx2
			--				BEGIN
			--				SET @lnCounttx2=@lnCounttx2+1;
							
			--				SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
			--						@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
			--						@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx
			--				FROM @ZShipTaxSR WHERE nrecno = @lnCounttx2

			--				IF (@@ROWCOUNT<>0)
			--				BEGIN
			--					-- Get unique value for PlUniqLnk
			--					BEGIN
			--						WHILE (1=1)
			--						BEGIN
			--							EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			--							SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
			--							IF (@@ROWCOUNT<>0)
			--								CONTINUE
			--							ELSE
			--								BREAK
			--						END			
			--					END
								
			--					SET @lnMTax = @lnMTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);	
			--					-- 02/07/12 VL comment out here, see detail above			
			--					--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
			--					--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq) 
			--					--		VALUES (@lcCmMainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--					--			-ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), @lcTxTaxtype, @lcNewUniqNbr)
			--				END
			--				END
			--			END
			--		END
			--	ELSE
			--	-- Foreign tax
			--		BEGIN
			--		IF @lcCmMainCmType = 'I' AND @lcOriginInvoiceno <> ''	-- credit memo from invoice, sales tax has to be the same as invoice
			--			BEGIN
			--			IF @llForeignSttx = 0
			--				BEGIN
			--				WHILE @lnCntTaxTotal>@lnCntTax
			--				BEGIN
			--					SET @lnCntTax=@lnCntTax+1;		
			--					SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
			--							@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Tax_type, @lcTxTxTypeForn = TxTypeForn
			--							FROM @ZShipTaxINVS WHERE nrecno = @lnCntTax
								
			--					IF (@@ROWCOUNT<>0)
			--					-- Get unique value for PlUniqLnk
			--					BEGIN
			--						WHILE (1=1)
			--						BEGIN
			--							EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			--							SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
			--							IF (@@ROWCOUNT<>0)
			--								CONTINUE
			--							ELSE
			--								BREAK
			--						END			
								
			--						-- 09/29/11 VL changed @lcTxTaxType to @lcTxTxTypeForn
			--						IF @lcTxTxTypeForn = 'P' AND @llPtProd = 1
			--						BEGIN
			--							SET @lnMSPTax = @lnMSPTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
			--							-- 02/07/12 VL comment out here, see detail above										
			--							--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
			--							--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
			--							--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--							--			-ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 'S', @lcNewUniqNbr, @lcTxTxTypeForn)
			--						END
								
			--						-- 09/29/11 VL changed @lcTxTaxType to @lcTxTxTypeForn
			--						IF @lcTxTxTypeForn = 'E' AND @llStProd = 1
			--						BEGIN	
			--							SET @lnMSSTax = @lnMSSTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
			--							-- 02/07/12 VL comment out here, see detail above
			--							--IF @llForeignSttx = 0
			--							--BEGIN
			--								--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
			--								--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
			--								--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--								--			-ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 'S', @lcNewUniqNbr, @lcTxTxTypeForn)
			--							--END
			--						END										
			--					END
			--				END
			--				END
			--			ELSE
			--				BEGIN
			--				IF @llPtProd = 1
			--					BEGIN
			--					WHILE @lnCntTaxTotalINVS_P > @lnCntTaxINVS_P
								
			--					BEGIN
			--						SET @lnCntTaxINVS_P=@lnCntTaxINVS_P+1;
			--						SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
			--								@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Tax_type, @lcTxTxTypeForn = TxTypeForn
			--								FROM @ZShipTaxINVS_P WHERE nrecno = @lnCntTaxINVS_P
									
			--						IF (@@ROWCOUNT<>0)
			--						-- Get unique value for PlUniqLnk
			--						BEGIN
			--							WHILE (1=1)
			--							BEGIN
			--								EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			--								SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
			--								IF (@@ROWCOUNT<>0)
			--									CONTINUE
			--								ELSE
			--									BREAK
			--							END			
																	
			--							SET @lnMSPTax = @lnMSPTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
			--							-- 02/07/12 VL comment out here, see detail above
			--							--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
			--							--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
			--							--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--							--			-ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 'S', @lcNewUniqNbr, @lcTxTxTypeForn)
			--						END
			--					END
			--					END
							
			--				IF @llStProd = 1
			--					BEGIN
			--					WHILE @lnCntTaxTotalINVS_E > @lnCntTaxINVS_E
								
			--					BEGIN
			--						SET @lnCntTaxINVS_E=@lnCntTaxINVS_E+1;
									
			--						SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
			--								@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Tax_type, @lcTxTxTypeForn = TxTypeForn
			--								FROM @ZShipTaxINVS_E WHERE nrecno = @lnCntTaxINVS_E
									
			--						IF (@@ROWCOUNT<>0)
			--							SET @lnMSSTax = @lnMSSTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);	
			--					END
			--					END
							
							
			--				SET @lnMSSTax = @lnMSSTax + ROUND(@lnMSPTax * @lnTxTax_rate/100,2)
							
			--				IF @lnMSSTax <> 0
			--					BEGIN
			--					-- Get unique value for PlUniqLnk
			--					WHILE (1=1)
			--					BEGIN
			--						EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			--						SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
			--						IF (@@ROWCOUNT<>0)
			--							CONTINUE
			--						ELSE
			--							BREAK
			--					END			

			--					-- 02/07/12 VL comment out here, see detail above
			--					--INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
			--					--	VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--					--		-@lnMSSTax, 'S', @lcNewUniqNbr, @lcTxTxTypeForn)
			--					END
			--				END
			--			END
			--		ELSE
			--			-- Forign tax for standard alone RMA
			--			-- Not from invoice, just calculate with regular tax
			--			BEGIN
			--			IF @llForeignSttx = 0
			--				BEGIN
			--				SET @lnCount3=0;
			--				WHILE @lnTotalNoSF>@lnCount3
			--				BEGIN
			--					SET @lnCount3=@lnCount3+1;
								
			--					SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
			--							@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
			--							@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx,
			--							@lcTxTxTypeForn = TxTypeForn
			--					FROM @ZShipTaxSF WHERE nrecno = @lnCount3
								
			--					IF (@@ROWCOUNT<>0)
			--					BEGIN
			--						-- Get unique value for PlUniqLnk
			--						WHILE (1=1)
			--						BEGIN
			--							EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			--							SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
			--							IF (@@ROWCOUNT<>0)
			--								CONTINUE
			--							ELSE
			--								BREAK
			--						END			
			--						-- check if primary
									
			--						IF @lcTxTaxtype = 'P' AND @llTxPtProd = 1
			--						BEGIN
			--							SET @lnMSPTax = @lnMSPTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
			--							-- 02/07/12 VL comment out here, see detail above
			--							--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
			--							--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
			--							--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--							--			-ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 'S', @lcNewUniqNbr, @lcTxTxTypeForn)
			--						END
									
											
			--						IF @lcTxTaxtype = 'E' AND @llTxStProd = 1
			--						BEGIN	
			--							SET @lnMSSTax = @lnMSSTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);	
			--							-- 02/07/12 VL comment out here, see detail above
			--							--IF @llForeignSttx = 0
			--							--BEGIN
			--								--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
			--								--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
			--								--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--								--			-ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 'S', @lcNewUniqNbr, @lcTxTxTypeForn)
			--							--END
			--						END	
									
			--					END
			--				END
			--				END
			--			ELSE
			--				BEGIN
			--				IF @llPtProd = 1
			--					BEGIN
								
			--					SET @lnCount3=0;
			--					WHILE @lnTotalNoSF_P>@lnCount3
			--					BEGIN
			--						SET @lnCount3=@lnCount3+1;
			--						SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
			--								@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, @lcTxTxTypeForn = TxTypeForn
			--								FROM @ZShipTaxSF_P WHERE nrecno = @lnCount3
									
			--						IF (@@ROWCOUNT<>0)
			--						-- Get unique value for PlUniqLnk
			--						BEGIN
			--							WHILE (1=1)
			--							BEGIN
			--								EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			--								SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
			--								IF (@@ROWCOUNT<>0)
			--									CONTINUE
			--								ELSE
			--									BREAK
			--							END			
																	
			--							SET @lnMSPTax = @lnMSPTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);
			--							-- 02/07/12 VL comment out here, see detail above										
			--							--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
			--							--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
			--							--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
			--							--			-ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2), 'S', @lcNewUniqNbr, @lcTxTxTypeForn)
			--						END
			--					END
			--					END

			--				IF @llStProd = 1
			--				BEGIN
			--					SET @lnCount3=0;
			--					WHILE @lnTotalNoSF_E>@lnCount3							
			--					BEGIN
			--						SET @lnCount3=@lnCount3+1;
			--						SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
			--								@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, @lcTxTxTypeForn = TxTypeForn
			--								FROM @ZShipTaxSF_E WHERE nrecno = @lnCount3
									
			--						IF (@@ROWCOUNT<>0)
			--							SET @lnMSSTax = @lnMSSTax + ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2);	
			--					END
			--				END
						
							
			--				SET @lnMSSTax = @lnMSSTax + ROUND(@lnMSPTax * @lnTxTax_rate/100,2)
							
			--				IF @lnMSSTax <> 0
			--				BEGIN
			--					-- Get unique value for PlUniqLnk
			--					WHILE (1=1)
			--					BEGIN
			--						EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			--						SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
			--						IF (@@ROWCOUNT<>0)
			--							CONTINUE
			--						ELSE
			--							BREAK
			--					END			
								
			--					-- 02/07/12 VL comment out here, see detail above		
			--					--INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
			--					--	VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, @llCmpricesPlUniqLnk, @lcSLinkAdd, @lcForeignTax_id, @lcForeignTaxDesc, @lcForeignGl_nbr_in, @lcForeignGl_nbr_out, @lnForeignTax_rate, 
			--					--		-@lnMSSTax, 'S', @lcNewUniqNbr, @lcForeignTaxtype)

			--				END
			--				END
			--			END
			--			SET @lnMTAX = @lnMSPTax + @lnMSSTax 
			--		END-- End of foreign tax or not
			--	END	--End of cmprice has tax
			
			-- 03/08/12 VL start new code, the stored procedure will insert all tax records for all cmprices records
			-- 03/11/15 VL added FC fields
			SET @lnCmpricesExtended = @lnCmpricesExtended*(100-@lnSalesDiscount)/100
			SET @lnCmpricesExtendedFC = @lnCmpricesExtendedFC*(100-@lnSalesDiscount)/100
			-- 01/19/17 VL added functional currency fields
			SET @lnCmpricesExtendedPR = @lnCmpricesExtendedPR*(100-@lnSalesDiscount)/100
			-- 03/27/14 VL found only need to insert to @ZSalesTax if the cmprices.taxable = 1
			IF @llCmpricesTaxable = 1
				BEGIN
				-- 03/11/15 VL added FC field as 3rd parameter
				-- 01/19/17 VL added functional currency field as 4th parameter
				INSERT @ZSalesTax EXEC [GetForeignTax4OneLine] @lcOriginPacklistno, @lnCmpricesExtended, @lnCmpricesExtendedFC, @lnCmpricesExtendedPR, @llCmpricesPlUniqLnk,'I', @pIsStandAloneRMA, @lcSLinkAdd, @lcCustno, 0

				-- {03/05/15 VL use the same code to insert CmpricesTax, found if CM was not approved, the Invstdtx will not be created, but still need to show in CM, so insert cmpricestax
				DELETE FROM @ZSalesTax2 WHERE 1=1
				-- 03/11/15 VL added FC field as 3rd parameter
				-- 01/19/17 VL added functional currency field as 4th parameter
				INSERT @ZSalesTax2 EXEC [GetForeignTax4OneLine] @lcOriginPacklistno, @lnCmpricesExtended, @lnCmpricesExtendedFC, @lnCmpricesExtendedPR, @llCmpricesPlUniqLnk,'I', @pIsStandAloneRMA, @lcSLinkAdd, @lcCustno, 0
				-- 03/05/15 VL added to update CmpricesTax
				-- 03/18/15 VL found TxTypeForn is empty when it's normal tax, so insert 'S' for it
				-- 03/20/15 VL added DISTINCT if sttx = 1, will have two type 'E' record (with different Tax_amt) in @ZSalesTax2
				;WITH ZDistSalesTax2 AS
				(SELECT DISTINCT Tax_id, Tax_rate, TxTypeForn, Ptprod, PtFrt, StProd, StFrt, Sttx FROM @ZSalesTax2)
				INSERT INTO CMPRICESTAX (UniqCmPRicesTax, CMUNIQUE, Cmpricelnk, CmPruniq, Tax_id, Tax_rate, TaxType, Ptprod, PtFrt, StProd, StFrt, Sttx)
					SELECT dbo.fn_GenerateUniqueNumber() AS UniqCmPricesTax, @CmdCmUnique AS Cmunique, @lcCmpricesCmpricelnk AS Cmpricelnk, @llCmpricesCmPrUniq As CmPruniq,
							Tax_id, Tax_rate, CASE WHEN TxTypeForn = '' THEN 'S' ELSE TxTypeForn END AS TaxType, Ptprod, PtFrt, StProd, StFrt, Sttx
							FROM ZDistSalesTax2 
				-- 03/05/15 VL End}
			END
	
		END
		-- 03/08/12 VL changed the calculation for @lnMSPTaxT, @lnMSSTaxT and @lnTotaltax because use different way to calculte
		--SET @lnMSPTaxT = @lnMSPTaxT + @lnMSPTax;
		--SET @lnMSSTaxT = @lnMSSTaxT + @lnMSSTax;
		--SET @lnTotaltax = @lnTotaltax + @lnMTAX;
		
		BEGIN
		-- 03/11/15 VL added FC fields
		IF @llForeignTax = 1
			BEGIN
				-- 01/19/17 VL added functional currency fields
				SELECT @lnMSPTaxT = ROUND(ISNULL(SUM(Tax_Amt),0),2), @lnMSPTaxTFC = ROUND(ISNULL(SUM(Tax_AmtFC),0),2), @lnMSPTaxTPR = ROUND(ISNULL(SUM(Tax_AmtPR),0),2) FROM @ZSalesTax WHERE TxTypeForn = 'P'
			END
		ELSE
			BEGIN
				SET @lnMSPTaxT = 0
				SET @lnMSPTaxTFC = 0
				-- 01/19/17 VL added functional currency fields
				SET @lnMSPTaxTPR = 0
			END
		END
		
		BEGIN
		IF @llForeignTax = 1
			BEGIN
				-- 01/19/17 VL added functional currency fields
				SELECT @lnMSSTaxT = ROUND(ISNULL(SUM(Tax_Amt),0),2), @lnMSSTaxTFC = ROUND(ISNULL(SUM(Tax_AmtFC),0),2), @lnMSSTaxTPR = ROUND(ISNULL(SUM(Tax_AmtPR),0),2) FROM @ZSalesTax WHERE TxTypeForn = 'E'
			END
		ELSE
			BEGIN
				SET @lnMSSTaxT = 0
				SET @lnMSSTaxTFC = 0
				-- 01/19/17 VL added functional currency fields
				SET @lnMSSTaxTPR = 0
			END
		END
		
		BEGIN
		IF @llForeignTax = 1
			BEGIN
				SET @lnTotaltax = @lnMSPTaxT + @lnMSSTaxT
				SET @lnTotaltaxFC = @lnMSPTaxTFC + @lnMSSTaxTFC
				-- 01/19/17 VL added functional currency fields
				SET @lnTotaltaxPR = @lnMSPTaxTPR + @lnMSSTaxTPR
			END
		ELSE
			BEGIN
				-- 01/19/17 VL added functional currency fields
				SELECT @lnTotaltax = ROUND(ISNULL(SUM(Tax_Amt),0),2), @lnTotaltaxFC = ROUND(ISNULL(SUM(Tax_AmtFC),0),2), @lnTotaltaxPR = ROUND(ISNULL(SUM(Tax_AmtPR),0),2) FROM @ZSalesTax
			END
		END
			
	END
END

/* TOTTAXF  @lnmFright_Tax*/
---------------
-- Delete first, will insert later
-- 02/07/12 VL comment out here, see detail above
--DELETE FROM InvStdTx WHERE Packlistno = @lcCmmainPacklistno AND Tax_Type = 'C'

-- 03/08/12 VL changed to call GetFreightTax4CM to have same calculation, in some situation, the old calculation and GetFreightTax4CM 
-- get $0.01 difference
-- Comment out old code, in old code, need to get value for @lnmFright_Tax, @lnMFPTax, @lnMFSTax
--BEGIN
--IF @llForeignTax = 0 -- Regular tax
--	BEGIN
--	IF @lcCmMainCmType = 'I' AND @lcOriginInvoiceno <> ''	-- credit memo from invoice, sales tax has to be the same as invoice
--		BEGIN
--			SET @lnCount9=0;
--			WHILE @lnTotalNoINVC>@lnCount9
--			BEGIN
--				SET @lnCount9=@lnCount9+1;		
--				SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
--						@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Tax_type, @lcTxTxTypeForn = TxTypeForn
--				FROM @ZShipTaxINVC WHERE nrecno = @lnCount9
				
--				IF (@@ROWCOUNT<>0)
--				BEGIN
--					-- Get unique value for PlUniqLnk
--					WHILE (1=1)
--					BEGIN
--						EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
--						SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
--						IF (@@ROWCOUNT<>0)
--							CONTINUE
--						ELSE
--							BREAK
--					END			
					
--					SET @lnmFright_Tax = @lnmFright_Tax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);	
--					-- 02/07/12 VL comment out here, see detail above			
--					--IF ROUND(@lnCmpricesExtended*@lnTxTax_rate/100*(100-@lnSalesDiscount)/100,2) <> 0
--					--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq) 
--					--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
--					--			-ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), @lcTxTaxtype, @lcNewUniqNbr)
--				END
--			END
--		END
--	ELSE
--		-- Regular shiptax
--		BEGIN
--		SET @lnCount4=0;
--		WHILE @lnTotalNoCR>@lnCount4
--		BEGIN	
--			SET @lnCount4=@lnCount4+1;
			
--			SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
--					@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
--					@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx
--			FROM @ZShipTaxCR WHERE nrecno = @lnCount4

--			IF (@@ROWCOUNT<>0)
--			BEGIN		
--				-- Get unique value for PlUniqLnk
--				WHILE (1=1)
--				BEGIN
--					EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
--					SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
--					IF (@@ROWCOUNT<>0)
--						CONTINUE
--					ELSE
--						BREAK
--				END			
				
--				SET @lnmFright_Tax = @lnmFright_Tax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2)
--				-- 02/07/12 VL comment out here, see detail above
--				--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0
--				--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq) 
--				--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
--				--			-ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), @lcTxTaxtype, @lcNewUniqNbr)
--			END
--		END
--		END
--	END

--ELSE
---- Foreign tax
--	BEGIN
--	IF @lcCmMainCmType = 'I' AND @lcOriginInvoiceno <> ''	-- credit memo from invoice, sales tax has to be the same as invoice
--		BEGIN
--		IF @llForeignSttx = 0
--			BEGIN
--			SET @lnCount9=0;
--			WHILE @lnTotalNoINVC>@lnCount9
--			BEGIN
--			SET @lnCount9=@lnCount9+1;		
--			SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
--					@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Tax_type, @lcTxTxTypeForn = TxTypeForn
--			FROM @ZShipTaxINVC WHERE nrecno = @lnCount9
			
--			IF (@@ROWCOUNT<>0)
--			BEGIN
--				-- Get unique value for PlUniqLnk
--				WHILE (1=1)
--				BEGIN
--					EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
--					SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
--					IF (@@ROWCOUNT<>0)
--						CONTINUE
--					ELSE
--						BREAK
--				END			

--				-- check if primary
--				-- 03/07/12 VL found should use @lcTxTxTypeForn and @llPtFrt, not @lcTxTaxtype and @llTxPtfrt
--				IF @lcTxTxTypeForn = 'P' AND @llPtFrt = 1
--					BEGIN
--					SET @lnMFPTax = @lnMFPTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
--					-- 02/07/12 VL comment out here, see detail above
--					--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0
--					--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
--					--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
--					--			-ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), 'C', @lcNewUniqNbr, @lcTxTxTypeForn)
--				END
				
--				-- 03/07/12 VL found should use @lcTxTxTypeForn and @llStFrt, not @lcTxTaxtype and @llTxStfrt
--				IF @lcTxTxTypeForn = 'E' AND @llStFrt = 1
--					BEGIN
--					SET @lnMFSTax = @lnMFSTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
					
--					-- 02/07/12 VL comment out here, see detail above
--					--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0
--					--		INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
--					--			VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
--					--				-ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), 'C', @lcNewUniqNbr, @lcTxTxTypeForn)
					
--				END		
--			END
--			END
--			END
--		ELSE
--			BEGIN
--			IF @llPtFrt = 1
--				BEGIN
--				SET @lnCount10=0;
--				WHILE @lnTotalNoINVC_P>@lnCount10
--				BEGIN
--					SET @lnCount10=@lnCount10+1;
--					SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
--							@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Tax_type, @lcTxTxTypeForn = TxTypeForn
--							FROM @ZShipTaxINVC_P WHERE nrecno = @lnCount10
					
--					IF (@@ROWCOUNT<>0)
--					 --Get unique value for PlUniqLnk
--					BEGIN
--						WHILE (1=1)
--						BEGIN
--							EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
--							SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
--							IF (@@ROWCOUNT<>0)
--								CONTINUE
--							ELSE
--								BREAK
--						END			
													
--						SET @lnMFPTax = @lnMFPTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
--						-- 02/07/12 VL comment out here, see detail above
--						--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0
--						--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
--						--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
--						--			-ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), 'C', @lcNewUniqNbr, @lcTxTxTypeForn)
--					END
--				END
--				END

--			IF @llStFrt = 1
--				BEGIN
--				SET @lnCount11=0;
--				WHILE @lnTotalNoINVC_E>@lnCount11
--				BEGIN
--					SET @lnCount11=@lnCount11+1;
					
--					SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
--							@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Tax_type, @lcTxTxTypeForn = TxTypeForn
--							FROM @ZShipTaxINVC_E WHERE nrecno = @lnCount11
					
--					IF (@@ROWCOUNT<>0)
--						SET @lnMFSTax = @lnMFSTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
--				END
--				END

--			SET @lnMFSTax = @lnMFSTax + ROUND(@lnMFPTax * @lnTxTax_rate/100,2)
							
--			IF @lnMFSTax <> 0
--				BEGIN
--				IF @lnMFSTax <> 0
--					-- Get unique value for PlUniqLnk
--					WHILE (1=1)
--					BEGIN
--						EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
--						SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
--						IF (@@ROWCOUNT<>0)
--							CONTINUE
--						ELSE
--							BREAK
--					END		
--					-- 02/07/12 VL comment out here, see detail above					
--					--INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
--					--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
--					--			-@lnMFSTax, 'C', @lcNewUniqNbr, @lcTxTxTypeForn)
--				END
--			END

--		END
--	ELSE
--	-- Foreign regular tax (not from invoice
--		BEGIN
--			SET @lnCount9=0;
--			WHILE @lnTotalNoSF>@lnCount9
--			BEGIN
--				SET @lnCount9=@lnCount9+1;
				
--				SELECT @lcTxTax_id = Tax_id, @lcTxTaxDesc = TaxDesc, @lcTxGl_nbr_in = Gl_nbr_in, 
--						@lcTxGl_nbr_out = Gl_nbr_out, @lnTxTax_rate = Tax_rate, @lcTxTaxtype = Taxtype, 
--						@llTxPtProd = PtProd, @llTxPtfrt = Ptfrt, @llTxStprod = Stprod, @llTxStFrt = StFrt, @llTxStTx = StTx, @lcTxTxTypeForn = TxTypeForn
--				FROM @ZShipTaxSF WHERE nrecno = @lnCount9
				
--				IF (@@ROWCOUNT<>0)
--				BEGIN
--					-- Get unique value for PlUniqLnk
					
--					WHILE (1=1)
--					BEGIN
--						EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
--						SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
--						IF (@@ROWCOUNT<>0)
--							CONTINUE
--						ELSE
--							BREAK
--					END			
					
--					-- check if primary
--					IF @lcTxTaxtype = 'P' AND @llTxPtfrt = 1
--						BEGIN
--						SET @lnMFPTax = @lnMFPTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
--						-- 02/07/12 VL comment out here, see detail above
--						--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0
--						--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
--						--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
--						--			-ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), 'C', @lcNewUniqNbr, @lcTxTxTypeForn)
--					END
					
--					IF @lcTxTaxtype = 'E' AND @llTxStFrt = 1
--						BEGIN
--						SET @lnMFSTax = @lnMFSTax + ROUND(@lnFreightAmt*@lnTxTax_rate/100,2);
--						-- 02/07/12 VL comment out here, see detail above
--						--IF @llForeignSttx = 0
--						--BEGIN
--							--IF ROUND(@lnFreightAmt*@lnTxTax_rate/100,2) <> 0
--							--	INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
--							--		VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcTxTax_id, @lcTxTaxDesc, @lcTxGl_nbr_in, @lcTxGl_nbr_out, @lnTxTax_rate, 
--							--			-ROUND(@lnFreightAmt*@lnTxTax_rate/100,2), 'C', @lcNewUniqNbr, @lcTxTxTypeForn)
--						--END
--					END		
--				END
--			END
		
	
--		IF @llForeignSttx = 1
--			BEGIN
--			SET @lnMFSTax = @lnMFSTax + ROUND(@lnMFPTax * @lnForeignTax_rate/100,2);
			
--			IF @lnMFSTax <> 0
--			BEGIN
--				-- Get unique value for PlUniqLnk
--				WHILE (1=1)
--				BEGIN
--					EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
--					SELECT @lcChkUniqValue = InvstdtxUniq FROM Invstdtx WHERE InvstdtxUniq = @lcNewUniqNbr
--					IF (@@ROWCOUNT<>0)
--						CONTINUE
--					ELSE
--						BREAK
--				END			
				
--				-- 02/07/12 VL comment out here, see detail above
--				--INSERT INTO InvStdTx (Packlistno, Invoiceno, PlUniqLnk, LinkAdd, Tax_id, TaxDesc, Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_type, InvStdtxUniq, TxTypeForn) 
--				--	VALUES (@lcCmmainPacklistno, @lcCmmainCmemono, SPACE(10), @lcSLinkAdd, @lcForeignTax_id, @lcForeignTaxDesc, @lcForeignGl_nbr_in, @lcForeignGl_nbr_out, @lnForeignTax_rate, 
--				--		-@lnMFSTax, 'C', @lcNewUniqNbr, @lcForeignTaxtype)

--			END
--		END

		
		
		
--		END
--		SET @lnmFright_Tax = @lnMFPTax + @lnMFSTax

--	END
	
--END
-- 03/08/12 VL start new code for freight tax calculation
-- OriginalPacklistno, Custno, cmType, Stand Alone RMA, Linkadd, FreightTax Only, Freight Amt (invoice - all CM freight), Freight Amt
-- 03/11/15 VL added two more parameters for FC fields
-- 01/19/17 VL added functional currency field as parameter
INSERT @ZFreightTax EXEC [GetFreightTax4CM] @lcOriginPacklistno,@lcCustno,'I',@pIsStandAloneRMA,@lcSLinkAdd,0,@lnFreightAmt,@lnFreightAmt, @lnFreightAmtFC,@lnFreightAmtFC, @lnFreightAmtPR,@lnFreightAmtPR

-- {03/05/15 VL added to insert CmfreightTax
DELETE FROM CMFREIGHTTAX WHERE CMUNIQUE = @gcCmUnique
INSERT INTO CMFREIGHTTAX (UNIQCMFREIGHTTAX, CMUNIQUE, Tax_id, Tax_rate, PtProd, PtFrt, StProd, StFrt, Sttx, TaxType ) 
	SELECT dbo.fn_GenerateUniqueNumber() AS uniqCmFreightTax, @gcCmUnique AS Cmunique, Tax_id, Tax_rate, PtProd, PtFrt, StProd, StFrt, Sttx, TxTypeForn AS TaxType
		FROM @ZFreightTax
-- 03/05/15 VL End}

-- 03/11/15 VL added FC fields
-- 01/19/17 VL added functional currency fields
SELECT @lnMFPTax = ROUND(ISNULL(SUM(Tax_Amt),0),2), @lnMFPTaxFC = ROUND(ISNULL(SUM(Tax_AmtFC),0),2), @lnMFPTaxPR = ROUND(ISNULL(SUM(Tax_AmtPR),0),2) FROM @ZFreightTax WHERE TxTypeForn = 'P'
SELECT @lnMFSTax = ROUND(ISNULL(SUM(Tax_Amt),0),2), @lnMFSTaxFC = ROUND(ISNULL(SUM(Tax_AmtFC),0),2), @lnMFSTaxPR = ROUND(ISNULL(SUM(Tax_AmtPR),0),2) FROM @ZFreightTax WHERE TxTypeForn = 'E'
SET @lnmFright_Tax = @lnMFPTax + @lnMFSTax
SET @lnmFright_TaxFC = @lnMFPTaxFC + @lnMFSTaxFC
SET @lnmFright_TaxPR = @lnMFPTaxPR + @lnMFSTaxPR

				
/* CmTotal @lnCmTotal*/
-- 03/11/15 VL added FC fields
SET @lnCmTotal = CASE WHEN 
	ROUND(@lnTotExten,2) + ROUND(@lnTotaltax,2) + ROUND(@lnFreightAmt,2) + ROUND(@lnmFright_Tax,2) - ROUND(@lnDsctamt,2) >  999999999999999.99
	THEN 999999999999999.99 
	ELSE ROUND(@lnTotExten,2) + ROUND(@lnTotaltax,2) + ROUND(@lnFreightAmt,2) + ROUND(@lnmFright_Tax,2) - ROUND(@lnDsctamt,2)
	END
SET @lnCmTotalFC = CASE WHEN 
	ROUND(@lnTotExtenFC,2) + ROUND(@lnTotaltaxFC,2) + ROUND(@lnFreightAmtFC,2) + ROUND(@lnmFright_TaxFC,2) - ROUND(@lnDsctamtFC,2) >  999999999999999.99
	THEN 999999999999999.99 
	ELSE ROUND(@lnTotExtenFC,2) + ROUND(@lnTotaltaxFC,2) + ROUND(@lnFreightAmtFC,2) + ROUND(@lnmFright_TaxFC,2) - ROUND(@lnDsctamtFC,2)
	END
-- 01/19/17 VL added functional currency fields
SET @lnCmTotalPR = CASE WHEN 
	ROUND(@lnTotExtenPR,2) + ROUND(@lnTotaltaxPR,2) + ROUND(@lnFreightAmtPR,2) + ROUND(@lnmFright_TaxPR,2) - ROUND(@lnDsctamtPR,2) >  999999999999999.99
	THEN 999999999999999.99 
	ELSE ROUND(@lnTotExtenPR,2) + ROUND(@lnTotaltaxPR,2) + ROUND(@lnFreightAmtPR,2) + ROUND(@lnmFright_TaxPR,2) - ROUND(@lnDsctamtPR,2)
	END
				
SET @lnMPTax = @lnMSPTaxT + @lnMFPTax
SET @lnMSTax = @lnMSSTaxT + @lnMFSTax
SET @lnMPTaxFC = @lnMSPTaxTFC + @lnMFPTaxFC
SET @lnMSTaxFC = @lnMSSTaxTFC + @lnMFSTaxFC
-- 01/19/17 VL added functional currency fields
SET @lnMPTaxPR = @lnMSPTaxTPR + @lnMFPTaxPR
SET @lnMSTaxPR = @lnMSSTaxTPR + @lnMFSTaxPR
								
IF @lcOriginInvoiceno <> ''	-- Created from invoice, will check if has rounding issues
BEGIN
	-- not include this CM amount, because cmmain is not updated yet
	-- 03/11/15 VL added FC fields
	-- 01/19/17 VL added functional currency fields
	SELECT @lnCmTotal4Inv = ISNULL(SUM(Cmtotal),0), @lnCmTotal4InvFC = ISNULL(SUM(CmtotalFC),0), @lnCmTotal4InvPR = ISNULL(SUM(CmtotalPR),0)
		FROM Cmmain
		WHERE Invoiceno = @lcOriginInvoiceno
		AND CMUNIQUE <> @gcCmUnique
		AND CStatus <> 'CANCELLED '

	-- 03/11/15 VL added FC fields
	-- 01/19/17 VL added functional currency fields
	SELECT @lnPlmainInvTotal = Invtotal, @lnPlmainInvtotalFC = InvtotalFC, @lnPlmainInvtotalPR = InvtotalPR
		FROM Plmain 
		WHERE Invoiceno = @lcOriginInvoiceno
	
	-- 03/07/12 VL changed from 0.01 to 0.05 to catch more differnce
	-- 11/03/10 VL added code, check if there is any difference caused by rounding on tax (more easily caused from foreign tax), if any ($0.01), just ;
	-- create another Cmdetail and Cmprices records with $0.01, and update Cmmain
	-- 03/13/12 VL removed (@lnTotaltax <> 0 OR @lnmFright_Tax <> 0) criteria, it might caused by amount itself, not tax
	--IF ABS((@lnCmTotal4Inv + @lnCmTotal) - @lnPlmainInvTotal) <= 0.05 AND (@lnTotaltax <> 0 OR @lnmFright_Tax <> 0) AND ABS((@lnCmTotal4Inv + @lnCmTotal) - @lnPlmainInvTotal) <> 0
	-- 03/11/15 VL added FC fields
	-- 01/19/17 VL not going to check functional currency fields
	IF (ABS((@lnCmTotal4Inv + @lnCmTotal) - @lnPlmainInvTotal) <= 0.05 AND ABS((@lnCmTotal4Inv + @lnCmTotal) - @lnPlmainInvTotal) <> 0) OR
		(ABS((@lnCmTotal4InvFC + @lnCmTotalFC) - @lnPlmainInvTotalFC) <= 0.05 AND ABS((@lnCmTotal4InvFC + @lnCmTotalFC) - @lnPlmainInvTotalFC) <> 0) 
	BEGIN
		EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
		EXEC sp_GenerateUniqueValue @lcNewUniqNbr2 OUTPUT
		EXEC sp_GenerateUniqueValue @lcNewUniqNbr3 OUTPUT
		
		-- 03/07/12 VL added lAdjustLine
	 	INSERT INTO Cmdetail (Cmemono, Packlistno, Uniqueln, CmQty, CmDescr, Note, Cmpricelnk, CmUnique, lAdjustLine) 
			VALUES (@lcCmMainCmemono, @lcCmmainPacklistno, 'NONE', 1.00, 'Rounding Adjustment', 'Adjust the difference created by rounding function',@lcNewUniqNbr, @gcCmUnique,1)
		--	08/29/11 VL	Removed CmTaxable from cmprices table, use Taxable to calculate	
		--	02/13/12 VL save cmprices.Pluniqlnk from @@lcNewUniqNbr2 to ''
		-- 03/11/15 VL added FC fields
		-- 01/19/17 VL added functional currency fields
		INSERT INTO CMPRICES (Cmemono, Packlistno, Uniqueln, Descript, CmQuantity, Cmprice, Cmextended, Taxable, Flat, Recordtype, 
				Pl_gl_nbr, Pluniqlnk, Cmpricelnk, CmprUniq, CmUnique, CmpriceFC, CmextendedFC, CmpricePR, CmextendedPR) 
			VALUES (@lcCmmainCmemono, @lcCmmainPacklistno, 'NONE', 'Rounding Adjustment', 1.00, (@lnPlmainInvTotal - (@lnCmTotal4Inv + @lnCmTotal)), 
			(@lnPlmainInvTotal - (@lnCmTotal4Inv + @lnCmTotal)), 0, 0, 'O',
			 @lcRundVar_gl, '', @lcNewUniqNbr, @lcNewUniqNbr3, @gcCmUnique, (@lnPlmainInvTotalFC - (@lnCmTotal4InvFC + @lnCmTotalFC)), 
			(@lnPlmainInvTotalFC - (@lnCmTotal4InvFC + @lnCmTotalFC)), (@lnPlmainInvTotalPR - (@lnCmTotal4InvPR + @lnCmTotalPR)), 
			(@lnPlmainInvTotalPR - (@lnCmTotal4InvPR + @lnCmTotalPR)))
		
		-- 11/01/11 VL added code to re-calculate extended again, so total of all RMA receivers created for the RMA will be correct
		/* TotExten*/
		-------------------------
		-- 03/11/15 VL added FC fields
		-- 01/19/17 VL added functional currency fields
		SELECT @lnTotExten = SUM(CmExtended), @lnTotExtenFC = SUM(CmExtendedFC), @lnTotExtenPR = SUM(CmExtendedPR) FROM Cmprices WHERE Cmunique = @gcCmUnique

		/* CmTotal @lnCmTotal*/
		-- 03/11/15 VL added FC fields
		SET @lnCmTotal = CASE WHEN 
			ROUND(@lnTotExten,2) + ROUND(@lnTotaltax,2) + ROUND(@lnFreightAmt,2) + ROUND(@lnmFright_Tax,2) - ROUND(@lnDsctamt,2) >  999999999999999.99
			THEN 999999999999999.99 
			ELSE ROUND(@lnTotExten,2) + ROUND(@lnTotaltax,2) + ROUND(@lnFreightAmt,2) + ROUND(@lnmFright_Tax,2) - ROUND(@lnDsctamt,2)
			END				 
		SET @lnCmTotalFC = CASE WHEN 
			ROUND(@lnTotExtenFC,2) + ROUND(@lnTotaltaxFC,2) + ROUND(@lnFreightAmtFC,2) + ROUND(@lnmFright_TaxFC,2) - ROUND(@lnDsctamtFC,2) >  999999999999999.99
			THEN 999999999999999.99 
			ELSE ROUND(@lnTotExtenFC,2) + ROUND(@lnTotaltaxFC,2) + ROUND(@lnFreightAmtFC,2) + ROUND(@lnmFright_TaxFC,2) - ROUND(@lnDsctamtFC,2)
			END				 
		-- 01/19/17 VL added functional currency fields
		SET @lnCmTotalPR = CASE WHEN 
			ROUND(@lnTotExtenPR,2) + ROUND(@lnTotaltaxPR,2) + ROUND(@lnFreightAmtPR,2) + ROUND(@lnmFright_TaxPR,2) - ROUND(@lnDsctamtPR,2) >  999999999999999.99
			THEN 999999999999999.99 
			ELSE ROUND(@lnTotExtenPR,2) + ROUND(@lnTotaltaxPR,2) + ROUND(@lnFreightAmtPR,2) + ROUND(@lnmFright_TaxPR,2) - ROUND(@lnDsctamtPR,2)
			END				 

	END
	
	-- Now check if total CM total exceed or equal to the invoice total, will save $0.00 CM if user agrees in RMA receiver form
	BEGIN
	-- 03/11/15 VL added FC fields
	-- 01/19/17 VL not going to check functional currency fields
	IF (@lnCmTotal4Inv + @lnCmTotal > @lnPlmainInvTotal + @lnPlmainInvTotal*0.01) OR (@lnCmTotal4InvFC + @lnCmTotalFC > @lnPlmainInvTotalFC + @lnPlmainInvTotalFC*0.01)
		BEGIN
		IF @lcSaveZeroCm = 'Y'	-- user agrees
			BEGIN
				UPDATE Cmprices SET CMPRICE = 0, CmExtended = 0.00, CMPRICEFC = 0, CmExtendedFC = 0.00 WHERE CmUnique = @gcCmUnique
				DELETE FROM INVSTDTX WHERE Invoiceno = @lcCmmainCmemono

				SET @lnMPTax = 0
				SET @lnMSTax = 0
				SET @lnMFPTax = 0
				SET @lnMFSTax = 0
				SET @lnMSPTax = 0
				SET @lnMSSTax = 0
				SET @lnMSPTaxT = 0
				SET @lnMSSTaxT = 0
				SET @lnFreightAmt = 0
				SET @lnmFright_Tax = 0
				SET @lnTotExten = 0
				SET @lnTotaltax = 0
				SET @lnCmTotal = 0
				SET @lnDsctamt = 0
				SET @lnSalesDiscount = 0
				-- 03/11/15 VL added FC fields
				SET @lnMPTaxFC = 0
				SET @lnMSTaxFC = 0
				SET @lnMFPTaxFC = 0
				SET @lnMFSTaxFC = 0
				SET @lnMSPTaxFC = 0
				SET @lnMSSTaxFC = 0
				SET @lnMSPTaxTFC = 0
				SET @lnMSSTaxTFC = 0
				SET @lnFreightAmtFC = 0
				SET @lnmFright_TaxFC = 0
				SET @lnTotExtenFC = 0
				SET @lnTotaltaxFC = 0
				SET @lnCmTotalFC = 0
				SET @lnDsctamtFC = 0
				-- 01/19/17 VL added functional currency fields
				SET @lnMPTaxPR = 0
				SET @lnMSTaxPR = 0
				SET @lnMFPTaxPR = 0
				SET @lnMFSTaxPR = 0
				SET @lnMSPTaxPR = 0
				SET @lnMSSTaxPR = 0
				SET @lnMSPTaxTPR = 0
				SET @lnMSSTaxTPR = 0
				SET @lnFreightAmtPR = 0
				SET @lnmFright_TaxPR = 0
				SET @lnTotExtenPR = 0
				SET @lnTotaltaxPR = 0
				SET @lnCmTotalPR = 0
				SET @lnDsctamtPR = 0
			END
		ELSE
			BEGIN
				--SET @llSaveSuccessful = 0
				RAISERROR('The total credit issued for this invoice exceeds/equals to the invoice total.  This will create a credit memo with $0.00 amount.  User selects to cancel the saving routine.  The transaction will be cancelled.',1,1)
				ROLLBACK TRANSACTION
				RETURN		
			END	
		END
	END

END


/* Update Cmmain from all variables*/
-- 03/09/12 VL added ROUND(,2)
-- 07/05/12 YS update is_rel_gl=1 if @lnCmTotal=0.00
-- 01/14/14 YS reverse the changes made on 07/05/12. Do not mark as released if total =0. There are still trnasactions for cost of goods that has to take place
-- 03/11/15 VL added FC fields
-- 01/19/17 VL added functional currency fields
UPDATE Cmmain SET Cmtotexten = @lnTotExten, Tottaxe = ROUND(@lnTotaltax,2), Cm_Frt = @lnFreightAmt, Cm_frt_tax = ROUND(@lnmFright_Tax,2),
		Cmtotal = @lnCmTotal, Dsctamt = @lnDsctamt, Frt_gl_no = @lcFrt_gl_no, Fc_gl_no = @lcFc_gl_no, 
		Disc_gl_no = @lcDisc_gl_no, PTAX = CASE WHEN @llForeignTax = 1 THEN ROUND(@lnmPTax,2) ELSE 0 END, 
		STAX = CASE WHEN @llForeignTax = 1 THEN ROUND(@lnmSTax,2) ELSE 0 END, CSTATUS = 'OPEN', DSAVEDATE = GETDATE(),
		CmtotextenFC = @lnTotExtenFC, TottaxeFC = ROUND(@lnTotaltaxFC,2), Cm_FrtFC = @lnFreightAmtFC, Cm_frt_taxFC = ROUND(@lnmFright_TaxFC,2),
		CmtotalFC = @lnCmTotalFC, DsctamtFC = @lnDsctamtFC, PTAXFC = CASE WHEN @llForeignTax = 1 THEN ROUND(@lnmPTaxFC,2) ELSE 0 END, 
		STAXFC = CASE WHEN @llForeignTax = 1 THEN ROUND(@lnmSTaxFC,2) ELSE 0 END,
		-- 01/19/17 VL added functional currency fields
		CmtotextenPR = @lnTotExtenPR, TottaxePR = ROUND(@lnTotaltaxPR,2), Cm_FrtPR = @lnFreightAmtPR, Cm_frt_taxPR = ROUND(@lnmFright_TaxPR,2),
		CmtotalPR = @lnCmTotalPR, DsctamtPR = @lnDsctamtPR, PTAXPR = CASE WHEN @llForeignTax = 1 THEN ROUND(@lnmPTaxPR,2) ELSE 0 END, 
		STAXPR = CASE WHEN @llForeignTax = 1 THEN ROUND(@lnmSTaxPR,2) ELSE 0 END
		--,
		--Is_rel_gl=CASE WHEN @lnCmTotal=0.00 THEN 1 ELSE Is_rel_gl END
	WHERE CMUNIQUE = @gcCmUnique


COMMIT;
--SET @llSaveSuccessful = 1
END








