-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/05/12
-- Description:	ApVoidAndReprintCheck
-- Modification:
-- 07/28/15 VL added FC fields
-- 02/07/17 VL added functional currency code and minor fix for 'Voiding Entry' that A.CheckAmtFC is not negative
-- =============================================
CREATE PROCEDURE [dbo].[ApVoidAndReprintCheck]
        -- Add the parameters for the stored procedure here
        @ApChk_Uniq as char(10) = ' ',
        @bk_uniq char(10)=' ', 
        @NewCheckNo as char(10) = ' ',
        @UserInit char(8)=' ',
        @NewCheckDate smalldatetime = NULL,
        @Newapchk_uniq char(10)=' ' OUTPUT
  
        
AS
BEGIN
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;
    -- Insert statements for procedure here
    declare @VoidingApchk_uniq char(10),@Bank char(35),@BK_ACCT_NO char(15),@UniqLayout char(10),
			@AutoNumber bit ,@newPageChkNo char(10)=' ',
			@DetailLines numeric(4,2)=0,@nLineCount numeric(4,2)=0,@lnPages int=0
    SELECT @VoidingApchk_uniq=dbo.fn_GenerateUniqueNumber(),
			@Newapchk_uniq=dbo.fn_GenerateUniqueNumber()
			
	SELECT 	@Bank =RTRIM(Bank),
			@Bk_acct_no=RTRIM(Bk_acct_No),
			@UniqLayOut = Fk_UniqLayout ,
			@AutoNumber =XxCkNoSys
	from Banks WHERE bk_uniq=@bk_uniq 
	SELECT @DetailLines=DetailLines FROM CheckLayout WHERE 	UniqLayOut=@UniqLayOut
    
    BEGIN TRANSACTION
        -- UPDATE existsing check status to Void and 
        UPDATE APCHKMST SET Status = 'Void/Reprinted', 
							VoidDate= GETDATE(), 
							CheckNote = convert(varchar(max),CheckNote) + ' Replaced by Check No ' + @NewCheckNo + '   ' +
							@BANK+ '  account '  + @BK_ACCT_NO 
							 where APCHKMST.APCHK_UNIQ=@ApChk_Uniq
							
       -- create Voiding Entry
	   -- 02/07/17 VL added functional currency code, also found A.CheckAmtFC used to be possible, fix to be negative
       INSERT INTO ApChkMst (ApChk_Uniq, CheckNo, CheckDate, CheckAmt, Status, CheckNote, UniqSupNo, Bk_Uniq, BK_ACCT_NO,R_Link, SaveInit, CheckAmtFC, Fcused_Uniq, Fchist_key,CheckAmtPR, PRFcused_uniq, FuncFcused_uniq) 
						SELECT @VoidingApchk_uniq,A.CheckNo,
							CASE WHEN DATEDIFF(day,getdate(),A.CheckDate)>0 THEN GETDATE() ELSE A.CheckDate END,
							-A.CheckAmt,'Voiding Entry',A.CheckNote,A.UniqSupNo,A.bk_uniq,A.BK_ACCT_NO, A.R_link,@UserInit, -A.CheckAmtFC, A.Fcused_uniq, A.FCHIST_KEY, -A.CheckAmtPR, A.PRFCUSED_UNIQ, A.FUNCFCUSED_UNIQ   
					FROM Apchkmst A where ApChk_Uniq=@ApChk_Uniq
			 
		
		--  create a voiding ApDetail Records  
		-- 02/07/17 VL added functional currency code and FC code
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
		   -- 02/07/17 VL added functional currency and FC fields
		   ,[APRPAYFC]
		   ,[DISC_TKNFC]
		   ,[INVAMOUNTFC]
		   ,[BALANCEFC]
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
		   -- 02/07/17 VL added functional currency and FC fields
		   -APRPAYFC,
		   -DISC_TKNFC,
		   INVAMOUNTFC,
		    BALANCEFC, 
		   -APRPAYPR,
		   -DISC_TKNPR,
		   INVAMOUNTPR,
		   BALANCEPR
		    FROM ApchkDet WHERE [APCHK_UNIQ]=@ApChk_Uniq





                       
    
       -- replacement check
	   -- 02/07/17 VL added functional currency
       INSERT INTO ApChkMst (ApChk_Uniq, CheckNo, CheckDate, CheckAmt, Status, CheckNote, UniqSupNo, Bk_Uniq,BK_ACCT_NO, R_Link, SaveInit, CheckAmtFC, Fcused_Uniq, Fchist_key,CheckAmtPR, PRFcused_uniq, FuncFcused_uniq) 
						SELECT @Newapchk_uniq,@NewCheckNo,
							@NewCheckDate,A.CheckAmt,'Printed/OS',
							'Replaces check no ' + A.CheckNo + '  ' + 	@BANK+ '  account '  + @BK_ACCT_NO, 
							A.UniqSupNo,@bk_uniq,A.BK_ACCT_NO,A.R_link,@UserInit, A.CheckAmtFC, A.Fcused_Uniq, A.Fchist_key,A.CheckAmtPR, A.PRFCUSED_UNIQ, A.FUNCFCUSED_UNIQ     
					FROM Apchkmst A where ApChk_Uniq=@ApChk_Uniq
	   IF @AutoNumber=1				
			update Banks set LastCkNo=@NewCheckNo where BK_UNIQ = @bk_uniq	 
    --  create a replacing check ApDetail Records  
		
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
		   -- 02/07/17 VL added functional currency and FC fields
		   ,[APRPAYFC]
		   ,[DISC_TKNFC]
		   ,[INVAMOUNTFC]
		   ,[BALANCEFC]
		   ,[APRPAYPR]
		   ,[DISC_TKNPR]
		   ,[INVAMOUNTPR]
		   ,[BALANCEPR])
     SELECT dbo.fn_GenerateUniqueNumber(),
           @Newapchk_uniq,
		   @NewCheckNo,
           PONUM, 
           APRPAY,
           DISC_TKN,
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
		   -- 02/07/17 VL added functional currency and FC fields
		   APRPAYFC,
		   DISC_TKNFC,
		   INVAMOUNTFC,
		   BALANCEFC, 
		   APRPAYPR,
		   DISC_TKNPR,
		   INVAMOUNTPR,
		   BALANCEPR
		   FROM ApchkDet WHERE [APCHK_UNIQ]=@ApChk_Uniq
           
           SET @nLineCount=@@ROWCOUNT
		   SET @lnPages  = CEILING(@nLineCount/@DetailLines) - CASE WHEN @nLineCount % @DetailLines=0 THEN 0 ELSE 1 END
		   IF (SELECT CheckAdvance FROM Apsetup)=1
			BEGIN
				WHILE @lnPages>0
				BEGIN --- WHILE @lnPages>0
				    -- manual or auto numbers we are assigning next available number
					SET @newPageChkNo=@NewCheckNo
					WHILE 1=1
					BEGIN
						SELECT @newPageChkNo=CASE WHEN @AutoNumber=1 THEN dbo.padl(@newPageChkNo+1,10,'0') ELSE CAST(@newPageChkNo+1 as char(10)) END
						-- check if number already in use
						IF dbo.fn_IfAPCheckExists(@bk_uniq,@newPageChkNo)=0
							--not exists
							break 
							
					END	-- WHILE 1=1
					-- 02/07/17 VL added functional currency code
					 INSERT INTO ApChkMst (ApChk_Uniq, CheckNo, CheckDate, CheckAmt, Bk_Uniq, R_Link, Status, 
						UniqSupNo, SaveInit, CheckAmtFC, Fcused_Uniq, Fchist_key, CheckAmtPR, PRFcused_uniq, FuncFcused_uniq)
					SELECT 
						dbo.fn_GenerateUniqueNumber(), @newPageChkNo, GETDATE(), 0.00, @Bk_Uniq,
						A.R_Link, 'Void', A.UniqSupNo,@UserInit, A.CheckAmtFC, A.Fcused_Uniq, A.Fchist_key, A.CheckAmtPR, A.PRFCUSED_UNIQ, A.FUNCFCUSED_UNIQ
					FROM Apchkmst A where ApChk_Uniq=@ApChk_Uniq
					IF @AutoNumber=1
						update Banks set LastCkNo=@newPageChkNo WHERE BK_UNIQ = @bk_uniq	
					set @lnPages=@lnPages-1	
				END -- WHILE @lnPages>0
		   END --- IF (SELECT CheckAdvance FROM Apsetup)=1
    COMMIT                    
END