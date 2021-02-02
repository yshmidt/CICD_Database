-- =============================================
-- Author:		Vicky Lu
-- Create date: 2010/08/02
-- Description:	Recalculate Invoice and update invoice total
-- Modification:
-- 04/22/13 VL	has to consider a situation that pldetail is deleted, but invt_isu record has been created (positive and negative),
--				it's possible to have invt_isu record for PK item, but has no plprices records
-- 12/23/14 VL	added FC fields
-- 01/07/15 VL added Fcused_uniq and FcHist_key
-- 10/07/16 VL added presentation currency code
-- 10/13/16 VL remove PRFchist_key
-- =============================================
CREATE PROCEDURE [dbo].[sp_InvoicePost] @lcPacklistno AS char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

BEGIN TRANSACTION
DECLARE @PlmCustno char (10), @PlmInvoiceno char(10), @PlmInvDate smalldatetime, @PlmInvTotal numeric(20,2),
		@PlmTerms char(15), @lnPmt_days numeric(3,0), @lcTestNo char(10), @lcNewUniqNbr char(10), 
		@ARBalance numeric(20,2), @lnTotalNoIsu int, @lnCount int, @IsuInvtIsu_no char(10), @IsuUniqueln char(10), 
		@PlpCog_gl_nbr char(13), @PlmInvTotalFC numeric(20,2), @PlmFcUsed_uniq char(10), @PlmFcHist_key char(10),
		-- 10/07/16 VL added presentation currency fields
		 @PlmInvTotalPR numeric(20,2), @PlmFuncFcUsed_uniq char(10), @PlmPRFcUsed_uniq char(10);

DECLARE @ZInvt_isu TABLE (nrecno int identity, InvtIsu_no char(10), Uniqueln char(10));
INSERT @ZInvt_isu SELECT InvtIsu_no, Uniqueln
		FROM INVT_ISU 
		WHERE SUBSTRING(Issuedto,11,10) = @lcPacklistno 
SET @lnTotalNoIsu = @@ROWCOUNT;

-- 10/07/16 VL added @PlmInvTotalPR
SELECT @PlmCustno = Custno, @PlmInvoiceno = Invoiceno, @PlmInvDate = INVDATE, @PlmInvTotal = InvTotal, @PlmInvTotalFC = InvTotalFC,
		@PlmTerms = Terms, @PlmFcUsed_uniq = FcUsed_uniq, @PlmFcHist_key = FcHist_key,
		@PlmInvTotalPR = InvTotalPR, @PlmFuncFcUsed_uniq = FuncFcused_uniq, @PlmPRFcUsed_uniq = PRFcUsed_uniq
	FROM Plmain
	WHERE Packlistno = @lcPacklistno

-- Update Acctsrec record
IF (@@ROWCOUNT=0)
BEGIN
	RAISERROR('Cannot find associated packing list record. This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN	
END
	
SELECT @lnPmt_days = Pmt_days
	FROM PMTTERMS
	WHERE DESCRIPT = @PlmTerms

IF (@@ROWCOUNT=0)
BEGIN
	RAISERROR('Cannot find associated record in the pmtterms table that used in packing list table. This operation will be cancelled.',11,1)
	ROLLBACK TRANSACTION
	RETURN 
END

SELECT Custno, Invno
	FROM ACCTSREC
	WHERE CUSTNO = @PlmCustno 
	AND INVNO = @PlmInvoiceno
	
BEGIN
IF @@ROWCOUNT = 0
	-- No acctsrec record, need to insert one
	BEGIN
		WHILE (1=1)
		BEGIN
			EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
			SELECT @lcTestNo = UniqueAr FROM AcctSrec WHERE UniqueAr = @lcNewUniqNbr
			IF (@@ROWCOUNT<>0)
				CONTINUE
			ELSE
				BREAK
		END
		-- 12/23/14 VL added InvTotalFC
		-- 01/07/15 VL added Fcused_uniq and FcHist_key
		-- 10/07/16 VL added InvTotalPR, FuncFcused_uniq, PRFcused_uniq
		INSERT INTO Acctsrec (Custno, Invno, InvDate, InvTotal, Due_date, UniqueAr, InvTotalFC, FcUsed_uniq, FcHist_key, InvTotalPR, FuncFcused_uniq, PRFcused_uniq)
			VALUES (@PlmCustno, @PlmInvoiceno, @PlmInvDate, @PlmInvTotal, @PlmInvDate+@lnPmt_days, @lcNewUniqNbr, @PlmInvTotalFC, @PlmFcUsed_Uniq, @PlmFcHist_key, @PlmInvTotalPR, @PlmFuncFcUsed_Uniq, @PlmPRFcUsed_Uniq)
	END	
ELSE
	-- 12/23/14 VL added InvTotalFC
	-- 10/07/16 VL added InvTotalPR
	UPDATE ACCTSREC
		SET INVTOTAL = @PlmInvTotal,
			InvTotalFC = @PlmInvTotalFC,
			InvTotalPR = @PlmInvTotalPR
		WHERE INVNO = @PlmInvoiceno
END


-- Update Customer
SELECT @ARBalance = ISNULL(SUM(Acctsrec.Invtotal - Acctsrec.Arcredits),0)
	FROM Acctsrec
	WHERE Acctsrec.Custno = @PlmCustno

-- 09/23/10 VL comment out because the field customer.Calndr_ytd will be removed
--UPDATE CUSTOMER	
--	SET AR_HIGHBAL = CASE WHEN AR_HIGHBAL > @ARBalance THEN AR_HIGHBAL ELSE @ARBalance END,
--		CALNDR_YTD = CASE WHEN CALNDR_YTD + @PlmInvTotal > 999999999.99 THEN 999999999.99 ELSE CALNDR_YTD + @PlmInvTotal END
--		WHERE CUSTNO = @PlmCustno

UPDATE CUSTOMER	
	SET AR_HIGHBAL = CASE WHEN AR_HIGHBAL > @ARBalance THEN AR_HIGHBAL ELSE @ARBalance END
		WHERE CUSTNO = @PlmCustno

-- Update Invt_isu
IF (@lnTotalNoIsu>0)
BEGIN
	SET @lnCount=0;
	WHILE @lnTotalNoIsu>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @IsuInvtIsu_no = InvtIsu_no, @IsuUniqueln =Uniqueln	
			FROM @ZInvt_isu
			WHERE nrecno = @lnCount
			
		IF (@@ROWCOUNT<>0)
		BEGIN
			SELECT @PlpCog_gl_nbr = Cog_gl_nbr
				FROM PLPRICES
				WHERE Packlistno = @lcPacklistno
				AND UNIQUELN = @IsuUniqueln
				AND Recordtype = 'P'
			
			IF (@@ROWCOUNT<>0)
				BEGIN
				UPDATE INVT_ISU
					SET GL_NBR = @PlpCog_gl_nbr
					WHERE INVTISU_NO = @IsuInvtIsu_no
				END
			-- {04/22/13 VL has to consider a situation that pldetail is deleted, but invt_isu record has been created (positive and negative),
			-- it's possible to have invt_isu record for PK item, but has no plprices records
			--ELSE
			--	BEGIN
			--	RAISERROR('Cannot find associated record in the Invt_isu table to update. This operation will be cancelled.',11,1)
			--	ROLLBACK TRANSACTION
			--	RETURN	
			--END
			-- 04/22/13 VL End}
		END
					
	END
END

COMMIT

END