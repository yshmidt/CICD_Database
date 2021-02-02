-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 09/03/2012
-- Description:	Update Apchkmst and Apchkdet when auto deduction is generated. (last page on the bank reconciliation form.
--04/01/16 Banks balance is updated when apchkmst insert trigger is fired
-- =============================================
CREATE PROCEDURE [dbo].[Sp_GenerateChecksFromAutoDeduction] 
	-- Add the parameters for the stored procedure here
	@zAutoDeduct as tAutoDeduct READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- insert into apchkmst
     BEGIN TRANSACTION
		INSERT INTO APCHKMST (APCHK_UNIQ,CHECKNO,CHECKDATE ,CHECKAMT ,Status,IS_PRINTED ,BK_UNIQ)
		SELECT  Apchk_uniq,'Auto Ded',AD.CheckDate, AD.CheckAmt, 'Open',1, AD.Bk_Uniq FROM @ZAutoDeduct AD
	--- insert into apchkdet	
		INSERT INTO APCHKDET (ApCkD_Uniq,Apchk_uniq,ITEM_NO,ITEM_DESC,AprPay,GL_NBR)
			SELECT dbo.fn_GenerateUniqueNumber(),
				AD.Apchk_uniq,B.ITEM_NO,B.ITEM_DESC,
				B.ITEM_TOTAL as AprPay,
				B.GL_NBR  FROM @ZAutoDeduct AD INNER JOIN BkAdDetl B ON AD.UniqBkAdMn=B.FK_UNIQBKADMN     
		--- update bkAdMain
		UPDATE bkAdMain SET LastPmtGen =AD.CheckDate,
				PmtsDed =PmtsDed +Ad.nPayments
		 FROM bkAdMain INNER JOIN (SELECT UniqBkAdMn,COUNT(*) as nPayments,MAX(CheckDate) as CheckDate FROM @zAutoDeduct GROUP BY UniqBkAdMn) AD
		 ON bkAdMain.UNIQBKADMN= AD.UNIQBKADMN 
		--- Update Banks
		--04/01/16 Banks balance is updated when apchkmst insert trigger is fired
		--UPDATE BANKS SET BANK_BAL =BANK_BAL- AD.SUM_CheckAmt FROM BANKS
		--INNER JOIN 
		--(Select bk_uniq,SUM(CHECKAMT) as SUM_CheckAmt
		--	FROM @zAutoDeduct AD GROUP BY Bk_uniq) AS AD
		--ON Banks.BK_UNIQ =AD.Bk_uniq	
		 
				      
		
       
     COMMIT 
END