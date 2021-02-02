-- =============================================
-- Author:		Bill Blake
-- Create date: ??
-- Modification:
-- 07/08/15 VL added 3rd parameter @gcPaymentType and 4th parameter @gcFcused_uniq to consider foreign currency if @gcFcused_uniq is not empty and added FC fields
-- 07/24/15 VL added Disc_Tkn, was in frmChecksch Batch scueduling grid, but didn't see is't here, also added UPPER() for paymenttype
-- 10/09/15 VL rename Orig_Fchkey to Orig_Fchist_key
-- 10/24/16 YS added apmaster.DISC_AMT,apmaster.DISC_AMTFC
-- 02/03/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[Ap4checksch2] 
	-- Add the parameters for the stored procedure here
	@gcBatchUniq as char(10) = ' ', @gcPaymentType varchar(50) = ' ', @gcFcused_uniq char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
IF @gcFcused_uniq = ' '
	BEGIN
	SELECT 0 AS YesNo, Due_Date, SupName, InvNo, InvAmount, InvDate, 
	InvAmount - (Appmts + Disc_Tkn) AS Balance, 
	InvAmount - (Appmts + Disc_Tkn) AS AprPay,
	UniqApHead AS Fk_UniqApHead, @gcBatchUniq AS BatchUniq,Apmaster.RecVer,
	InvAmountFC,  InvAmountFC - (AppmtsFC + Disc_TknFC) AS BalanceFC, 
	InvAmountFC - (AppmtsFC + Disc_TknFC) AS AprPayFC, ApMaster.Fcused_uniq, ApMaster.Fchist_key AS Orig_Fchist_key,
	ApMaster.R_link, Disc_Tkn, Disc_TknFC,apmaster.DISC_AMT,apmaster.DISC_AMTFC
	FROM ApMaster, SupInfo 
	WHERE SupInfo.UniqSupNo = ApMaster.UniqSupNo 
	AND InvAmount - (Appmts + Disc_Tkn) <> 0.00 
	AND InvAmount - Appmts <> 0.00 
	AND ApStatus <> 'Deleted'
	AND cHoldStatus <> 'Pmt Hold' 
	AND ApMaster.lPrepay=0
	AND ApMaster.UniqApHead NOT IN 
		(SELECT ApBatDet.Fk_UniqApHead  
			FROM ApBatDet, ApBatch 
			where ApBatch.Is_Closed <> 1
			AND ApBatch.BatchUniq = ApBatDet.BatchUniq) 
	END

ELSE
	BEGIN
	WITH ZAp4CheckSch AS
	(
	SELECT 0 AS YesNo, Due_Date, SupName, InvNo, InvAmount, InvDate, 
	InvAmount - (Appmts + Disc_Tkn) AS Balance, 
	InvAmount - (Appmts + Disc_Tkn) AS AprPay,
	UniqApHead AS Fk_UniqApHead, @gcBatchUniq AS BatchUniq,Apmaster.RecVer,
	InvAmountFC,  InvAmountFC - (AppmtsFC + Disc_TknFC) AS BalanceFC, 
	InvAmountFC - (AppmtsFC + Disc_TknFC) AS AprPayFC, ApMaster.Fcused_uniq, ApMaster.Fchist_key AS Orig_Fchist_key,
	ApMaster.R_link, Disc_Tkn, Disc_TknFC,apmaster.DISC_AMT,apmaster.DISC_AMTFC,
	-- 02/03/17 VL added functional currency fields
	InvAmountPR,  InvAmountPR - (AppmtsPR + Disc_TknPR) AS BalancePR, 
	InvAmountPR - (AppmtsPR + Disc_TknPR) AS AprPayPR, apmaster.DISC_AMTPR, PRFcused_uniq, FuncFcused_uniq
	FROM ApMaster, SupInfo 
	WHERE SupInfo.UniqSupNo = ApMaster.UniqSupNo 
	AND InvAmountFC - (AppmtsFC + Disc_TknFC) <> 0.00 
	AND InvAmountFC - AppmtsFC <> 0.00 
	AND ApStatus <> 'Deleted'
	AND cHoldStatus <> 'Pmt Hold' 
	AND ApMaster.lPrepay=0
	AND Apmaster.Fcused_uniq = @gcFcused_uniq
	AND ApMaster.UniqApHead NOT IN 
		(SELECT ApBatDet.Fk_UniqApHead  
			FROM ApBatDet, ApBatch 
			where ApBatch.Is_Closed <> 1
			AND ApBatch.BatchUniq = ApBatDet.BatchUniq) 
	)
	-- 07/24/15 VL found a problem, the SQL code only works if user set up ebank info in supplier setup, 
	-- Tried to change to if ebank is setup, link shipbill.Bk_uniq = Banks.Bk_uniq, otherwise, if shipbill.Bk_uniq is empty, just the same way as before
	--SELECT ZAp4CheckSch.*
	--FROM ZAp4CheckSch, Shipbill, Banks
	--WHERE ZAp4CheckSch.R_link = ShipBill.LinkAdd
	--AND Shipbill.Bk_Uniq = Banks.BK_UNIQ 
	--AND ((UPPER(@gcPaymentType) = 'CHECK' AND (UPPER(Banks.PaymentType) = 'CHECK' OR Banks.PaymentType = ''))
	--OR (@gcPaymentType <> '' AND UPPER(Banks.PaymentType) = UPPER(@gcPaymentType)))
	SELECT ZAp4CheckSch.*
		FROM ZAp4CheckSch, Shipbill
		WHERE ZAp4CheckSch.R_link = ShipBill.LinkAdd
		AND ((ShipBill.Bk_Uniq<>''
			AND ShipBill.Bk_Uniq IN 
				(SELECT Banks.BK_UNIQ 
					FROM Banks 
					WHERE ((UPPER(@gcPaymentType) = 'CHECK' AND (UPPER(Banks.PaymentType) = 'CHECK' OR Banks.PaymentType = ''))
					OR (@gcPaymentType <> '' AND UPPER(Banks.PaymentType) = UPPER(@gcPaymentType)))))
		OR ShipBill.Bk_Uniq='')
	END

END