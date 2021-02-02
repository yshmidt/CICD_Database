-- =============================================
-- Author:		??
-- Create date: ??
-- Description:	AP void check
-- 10/09/15 VL rename Orig_Fchkey to Orig_Fchist_key
---04/01/16 YS move the code to update Banks balance into insert trigger for the APCHKMST
-- 01/13/17 VL added functional currency fields
--01/17/17 YS do not change to be 'editable' if the aptype='DM'
-- =============================================
CREATE PROCEDURE [dbo].[ApVoidCheck]
--- Modified:
--- 08/20/2013 YS when voiding the user will see taoday's date on the screen and can modify it to the day they want
        -- Add the parameters for the stored procedure here
        @ApChk_Uniq as char(10) = ' ',
        @bk_uniq char(10)=' ', 
        @UserInit char(8)=' ',
        @NewCheckDate smalldatetime = NULL,
        @VoidingApchk_uniq char(10)=' ' OUTPUT
  
        
AS
BEGIN
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;
    -- Insert statements for procedure here
  
    SELECT @VoidingApchk_uniq=dbo.fn_GenerateUniqueNumber()	;		
			
	
    BEGIN TRANSACTION
        -- UPDATE existsing check status to Void and 
        UPDATE APCHKMST SET Status = 'Void', 
							VoidDate= ISNULL(@NewCheckDate,GETDATE()) 
							 where APCHKMST.APCHK_UNIQ=@ApChk_Uniq ;
							
       -- create Voiding Entry
       -- 07/26/12 YS add bk_acct_no (the field is exists, even though we have link to Banks via bk_uniq. Not sure why we need it, but for now will populate)
	   -- 07/16/15 VL added FC fields
	   -- 01/13/17 VL added functional currency fields
       INSERT INTO ApChkMst (ApChk_Uniq, CheckNo, CheckDate, CheckAmt, Status, CheckNote, UniqSupNo, Bk_Uniq,Bk_acct_no, R_Link, SaveInit, CheckAmtFC,
							PmtType, Fcused_uniq, Fchist_key, CheckAmtPR, PRFCUSED_UNIQ, FUNCFCUSED_UNIQ) 
						SELECT @VoidingApchk_uniq,A.CheckNo,
							--CASE WHEN DATEDIFF(day,getdate(),A.CheckDate)>0 THEN GETDATE() ELSE A.CheckDate END,
							--08/20/13 YS when voiding the user will see taoday's date on the screen and can modify it to the day they want
							ISNULL(@NewCheckDate,GETDATE()),
							-A.CheckAmt,'Voiding Entry',A.CheckNote,A.UniqSupNo,A.bk_uniq,A.Bk_acct_no,A.R_link,@UserInit,-A.CheckAmtFC, 
							A.PmtType, A.Fcused_uniq, A.Fchist_key, -A.CheckAmtPR,dbo.fn_GetPresentationCurrency(), dbo.fn_GetFunctionalCurrency()    
					FROM Apchkmst A where ApChk_Uniq=@ApChk_Uniq ;
			 
		
		--  create a voiding ApDetail Records  
		
		-- 07/16/15 VL added FC fields
		-- 01/13/17 VL added functional currency fields
		INSERT INTO [APCHKDET]
           ([APCKD_UNIQ]
           ,[APCHK_UNIQ]
           ,[CHECKNO]
           ,[PONUM]
           ,[APRPAY]
           ,[DISC_TKN]
           ,[INVNO]
           ,[INVDATE]
           ,[INVAMOUNT]
           ,[DUE_DATE]
           ,[ITEM_DESC]
           ,[GL_NBR]
           ,[UNIQAPHEAD]
           ,[ITEM_NO]
           ,[ITEMNOTE]
           ,[BALANCE]
		   ,[APRPAYFC]
		   ,[DISC_TKNFC]
		   ,[INVAMOUNTFC]
		   ,[BALANCEFC]
		   ,[Orig_Fchist_key]
		   -- 01/13/17 VL added functional currency fields
		   ,[APRPAYPR]
		   ,[DISC_TKNPR]
		   ,[INVAMOUNTPR]
		   ,[BALANCEPR])
     SELECT dbo.fn_GenerateUniqueNumber(),
           @VoidingApchk_uniq,
			CHECKNO,
            PONUM, 
            -APRPAY,
           -DISC_TKN,
            INVNO, 
           INVDATE, 
           INVAMOUNT, 
           DUE_DATE,
           ITEM_DESC,
           GL_NBR, 
           UNIQAPHEAD,
           ITEM_NO, 
           ITEMNOTE,
           BALANCE,
		   -APRPAYFC, 
		   -DISC_TKNFC,
		   INVAMOUNTFC, 
		   BALANCEFC,
		   Orig_Fchist_key,
		   -- 01/13/17 VL added functional currency fields
		   -APRPAYPR, 
		   -DISC_TKNPR,
		   INVAMOUNTPR, 
		   BALANCEPR
		   FROM ApchkDet WHERE [APCHK_UNIQ]=@ApChk_Uniq ;

		-- update apmaster
		-- 07/16/15 VL added FC fields
		-- 01/13/17 VL added functional currency fields
		UPDATE Apmaster SET ApPmts = ApPmts + APCHKDET.AprPay, 
				Apmaster.Disc_Tkn = Apmaster.Disc_Tkn + APCHKDET.Disc_Tkn,  
				Paid = 'N', 
				ApStatus = CASE 
				--01/17/17 YS do not change to be 'editable' if the aptype='DM'
				WHEN apmaster.aptype='DM' THEN apmaster.APSTATUS
				WHEN Apmaster.Is_Rel_Gl=1 THEN 'Released to GL' ELSE 'Editable' END,
				ApPmtsFC = ApPmtsFC + APCHKDET.AprPayFC, 
				Apmaster.Disc_TknFC = Apmaster.Disc_TknFC + APCHKDET.Disc_TknFC,
				ApPmtsPR = ApPmtsPR + APCHKDET.AprPayPR, 
				Apmaster.Disc_TknPR = Apmaster.Disc_TknPR + APCHKDET.Disc_TknPR
				FROM APCHKDET WHERE Apchkdet.APCHK_UNIQ =@VoidingApchk_uniq and ApchkDet.UNIQAPHEAD =Apmaster.UNIQAPHEAD 

		-- 07/16/15 VL added FC fields
		---04/01/16 YS move the code to update Banks balance into insert trigger for the APCHKMST
   --    UPDATE Banks 
			--SET Bank_bal=Bank_bal+ABS(ApchkMst.CheckAmt),
			--	Bank_balFC=Bank_balFC+ABS(ApchkMst.CheckAmtFC) 
			--FROM APCHKMST 
			--WHERE ApchkMst.APCHK_UNIQ =@VoidingApchk_uniq and Banks.Bk_Uniq=ApChkMst.Bk_Uniq     
    
       
    COMMIT                    
END