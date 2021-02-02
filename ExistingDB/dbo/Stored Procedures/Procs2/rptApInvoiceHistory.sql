-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/03/2014
-- Description:	procedure for the AP Invoice/PO Report (SUPHIST was name of the report form in 9.6.3)
--- Modified:	04/30/14  YS  added APTYPE to check for general debit memo
--			12/12/14 DS Added supplier status filter
--			04/17/15 DRP: added the Saveinit to the results per request of an user.   
--			03/21/16 VL:  Added FC code
--			04/08/16 VL:  Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--			01/30/17 VL:  Added functional currency code
-- 08/17/17 VL re-arrange the fields for FC
-- 07/13/18 VL changed supname from char(30) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptApInvoiceHistory] 
	-- Add the parameters for the stored procedure here
--declare
	@lcDateStart date = null, -- have to have a value if @lcPoNum is null 
	@lcDateEnd date = null, -- have to have a value if @lcPoNum is null 
	@lcUniqSupno varchar(max)='All',  -- Null means did not select , All means all, has to have a value if @lcPoNum is NULL
	@singlePoNum bit =0,		-- select single PO
	@lcPoNum char(15)=NULL,    --- if @lcPoNum is not NULL will ignore date range and selection of @uniqsupno, but will check if user approved to see the information for the supplier assigned to the @lcPoNum
	@userid uniqueidentifier = null  -- has to have valid userid to continue
	,@supplierStatus varchar(20) = 'All'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
    -- get list of approved suppliers for this user
	DECLARE  @tSupplier tSupplier
	DECLARE @Supplier tSupplier
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus ;

    
	-- if a single ponum entered date range and supplier will be ignored
	IF (@lcPoNum is not null)
	-- make sure leading zeros are entered
		SELECT @lcDateStart=NULL,@lcDateEnd =NULL,@lcUniqSupno='All',@singlePoNum=1,@lcPoNum=DBO.PADL(LTRIM(RTRIM(@lcPoNum)),15,'0') 
	
	IF (@lcUniqSupno is not null and @lcUniqSupno <>'' and @lcUniqSupno<>'All')
		insert  into @Supplier (uniqsupno,supname) select S.uniqsupno ,S.supname 
		from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupno,',') F INNER JOIN @tSupplier S ON cast(f.id as CHAR(10))=S.uniqsupno 
			
	ELSE  -- if (@lcUniqSupno is not null and @lcUniqSupno <>'' and @lcUniqSupno<>'All')
	BEGIN -- else if (@lcUniqSupno is not null and @lcUniqSupno <>'' and @lcUniqSupno<>'All')
		---- empty or null  no selection were made
		IF  (@lcUniqSupno='All')	
		INSERT INTO @Supplier (uniqsupno,supname) SELECT UniqSupno,SupName FROM @tSupplier	
	END --  -- else if (@lcUniqSupno is not null and @lcUniqSupno <>'' and @lcUniqSupno<>'All')

	-- 03/21/16 VL added for FC installed or not
	DECLARE @lFCInstalled bit
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	BEGIN
	IF @lFCInstalled = 0
		BEGIN
	   
		-- collecting all invoice information
		-- 04/30/14 YS  added APTYPE to check for general debit memo
		-- 07/13/18 VL changed supname from char(30) to char(50)
		DECLARE @InvoiceInfo TABLE (UniqApHead char(10),  UniqSupNo char(10), PoNum char(15), InvNo char(20), 
					InvDate smalldatetime, Due_Date smalldatetime, InvAmount Numeric(12,2), Supname char(50),ApType char(10),Saveinit char(8))
		-- use nRec column to identify the invoice record (1 - for invoice, 2- for the rest)
		-- use indexdate column to index on the trnasaction date within an invoice		
		-- 07/13/18 VL changed supname from char(30) to char(50)	
		DECLARE @SupHist TABLE (UniqApHead Char(10), UniqSupNo Char(10), Ponum Char(15), InvNo Char(20), 
				InvDate smalldatetime, Due_Date smalldatetime, InvAmount Numeric(12,2) default 0.00, 
				DmemoNo Char(10), DmDate smallDatetime, DmTotal Numeric(12,2) default 0.00, DmApplied Numeric(12,2) default 0.00, 
				CheckDate smallDateTime, CheckNo Char(10), AprPay Numeric(12,2) default 0.00, Disc_Tkn Numeric(12,2) default 0.00, 
				SupName Char(50), DaysPay Numeric(5), VoidAmt Numeric(12,2) default 0.00,
				OffsetDate smalldatetime,OffsetAmount Numeric(12,2) default 0.00,nRec Int default 2,Indexdate smalldatetime,saveinit char(8))
	
	
		--- 04/30/14 YS  added APTYPE to check for general debit memo
	 
		INSERT INTO @InvoiceInfo (UniqApHead,  UniqSupNo, PoNum, InvNo, InvDate,Due_Date, InvAmount, Supname,Aptype,Saveinit)
		SELECT A.UniqApHead,  A.UniqSupNo, A.PoNum, A.InvNo, A.InvDate, A.Due_Date, A.InvAmount, S.Supname,A.Aptype,a.INIT
			FROM ApMaster A INNER JOIN  @Supplier S ON A.UNIQSUPNO = S.Uniqsupno
			WHERE 
			1=CASE WHEN @singlePoNum=1 THEN 1 
					WHEN  @singlePoNum=0 and CAST(InvDate as DATE) BETWEEN @lcDateStart and  @lcDateEnd THEN 1
					ELSE 0 END
			AND 1= CASE WHEN @singlePoNum=1 AND A.PONUM =@lcPoNum THEN 1 
					WHEN @singlePoNum=1 AND A.PONUM <> @lcPoNum THEN 0
					ELSE 1 END		
				
				
		INSERT INTO @SupHist (UniqApHead,  UniqSupNo, PoNum, InvNo, InvDate,Due_Date, InvAmount, Supname,nRec,Indexdate,saveinit )
			SELECT UniqApHead,  UniqSupNo, PoNum, InvNo, InvDate,Due_Date, InvAmount, Supname,1 ,InvDate,Saveinit
			FROM @InvoiceInfo 		
	
		-- collect all DM (ignore the data range)
		INSERT INTO @SupHist (UniqApHead, DmemoNo, DmDate, DmTotal, DmApplied, SupName, UniqSupNo, PoNum,
			InvNo, InvDate,Due_Date,IndexDate,saveinit)			
		SELECT D.UniqApHead, D.DmemoNo, D.DmDate, D.DmTotal, D.DmApplied, H.SupName, 
			H.UniqSupNo, H.PoNum ,H.InvNo, H.InvDate, H.Due_Date,DmDate,d.SAVEINIT
		FROM  DMemos D INNER JOIN @InvoiceInfo H ON  D.UniqApHead = H.UniqApHead 
		--- 04/30/14 YS  APTYPE<>'DM' when avoiding general debit memo
		--WHERE LEFT(H.Invno,2)<>'DM'
		WHERE H.Aptype<>'DM'
		-- collect checks (ignore the range)
		INSERT INTO @SupHist (UniqApHead, CheckDate, CheckNo, AprPay, Disc_Tkn, SupName, UniqSupNo, InvNo, InvDate, 
					PoNum, Due_Date, VoidAmt,IndexDate,saveinit) 
			SELECT CD.UniqApHead, CH.CheckDate, CH.CheckNo, CD.AprPay, CD.Disc_Tkn, I.SupName, I.UniqSupNo,  
				 I.InvNo, I.InvDate, I.PoNum,I.Due_Date, 
					CASE WHEN CH.[Status] ='Voiding Entry' THEN ABS(CD.APRPAY) ELSE 0.00 END ,CheckDate,ch.SAVEINIT
		FROM  ApChkMst CH INNER JOIN ApChkDet CD ON CH.APCHK_UNIQ=CD.APCHK_UNIQ
		INNER JOIN @InvoiceInfo I on CD.UNIQAPHEAD =I.UniqApHead 
	
		-- collect offset information
		INSERT INTO @SupHist (UniqApHead,SupName, UniqSupNo,InvNo, InvDate, 
					PoNum, Due_Date,OffsetDate ,OffsetAmount ,Indexdate,saveinit )
			select apoffset.UNIQAPHEAD,i.Supname,I.Uniqsupno,I.InvNo, I.InvDate, 
					I.PoNum, I.Due_Date,
					apoffset.[DATE], [AMOUNT] , apoffset.[DATE],INITIALS
			from APOFFSET INNER JOIN @InvoiceInfo I on ApOffset.UNIQAPHEAD = i.UniqApHead
	
		-- collect offset as separate antity
		--UPDATE @SupHist  SET OffsetAmount = Offset.OffAmount FROM 	
		--	(SELECT Apoffset.UniqApHEad,SUM(Amount) AS OffAmount
		--		FROM ApOffset INNER JOIN @InvoiceInfo I on ApOffset.UNIQAPHEAD = i.UniqApHead GROUP BY APOFFSET.UNIQAPHEAD) Offset
		--		INNER JOIN @SupHist S ON Offset.UNIQAPHEAD =S.UniqApHead 
	
		UPDATE @SupHist SET DaysPay = DATEDIFF(Day,InvDate,CheckDate) WHERE CheckDate is not null and InvDate is not null 	
		-- create total by supplier and total overall	
		select H.*,SUM(InvAmount) OVER (PARTITION By Uniqsupno) as SupInvAmount,
			SUM(InvAmount) OVER () as InvTotal
		 from @SupHist H order by SupName,invno,nrec,indexdate
		END
	ELSE
	-- FC installed
		BEGIN
		-- collecting all invoice information
		-- 04/30/14 YS  added APTYPE to check for general debit memo
		-- 01/30/17 VL added functional currency code
		-- 07/13/18 VL changed supname from char(30) to char(50)
		DECLARE @InvoiceInfoFC TABLE (UniqApHead char(10),  UniqSupNo char(10), PoNum char(15), InvNo char(20), 
					InvDate smalldatetime, Due_Date smalldatetime, InvAmount Numeric(12,2), Supname char(50),ApType char(10),Saveinit char(8)
					,InvAmountFC Numeric(12,2), InvAmountPR Numeric(12,2), Fcused_uniq char(10), PRFcused_uniq char(10), FuncFcused_uniq char(10))
		-- use nRec column to identify the invoice record (1 - for invoice, 2- for the rest)
		-- use indexdate column to index on the trnasaction date within an invoice	
		-- 01/30/17 VL added functional currency code		
		-- 07/13/18 VL changed supname from char(30) to char(50)
		DECLARE @SupHistFC TABLE (UniqApHead Char(10), UniqSupNo Char(10), Ponum Char(15), InvNo Char(20), 
				InvDate smalldatetime, Due_Date smalldatetime, InvAmount Numeric(12,2) default 0.00, 
				DmemoNo Char(10), DmDate smallDatetime, DmTotal Numeric(12,2) default 0.00, DmApplied Numeric(12,2) default 0.00, 
				CheckDate smallDateTime, CheckNo Char(10), AprPay Numeric(12,2) default 0.00, Disc_Tkn Numeric(12,2) default 0.00, 
				SupName Char(50), DaysPay Numeric(5), VoidAmt Numeric(12,2) default 0.00,
				OffsetDate smalldatetime,OffsetAmount Numeric(12,2) default 0.00,nRec Int default 2,Indexdate smalldatetime,saveinit char(8)
				,InvAmountFC Numeric(12,2) default 0.00, DmTotalFC Numeric(12,2) default 0.00, DmAppliedFC Numeric(12,2) default 0.00
				,AprPayFC Numeric(12,2) default 0.00, Disc_TknFC Numeric(12,2) default 0.00, VoidAmtFC Numeric(12,2) default 0.00
				,OffsetAmountFC Numeric(12,2) default 0.00
				,InvAmountPR Numeric(12,2) default 0.00, DmTotalPR Numeric(12,2) default 0.00, DmAppliedPR Numeric(12,2) default 0.00
				,AprPayPR Numeric(12,2) default 0.00, Disc_TknPR Numeric(12,2) default 0.00, VoidAmtPR Numeric(12,2) default 0.00
				,OffsetAmountPR Numeric(12,2) default 0.00
				,Fcused_uniq char(10), PRFcused_uniq char(10), FuncFcused_uniq char(10), TSymbol char(3), PSymbol char(3), FSymbol char(3))
	
	
		--- 04/30/14 YS  added APTYPE to check for general debit memo
		-- 01/30/17 VL added functional currency code
		INSERT INTO @InvoiceInfoFC (UniqApHead,  UniqSupNo, PoNum, InvNo, InvDate,Due_Date, InvAmount, Supname,Aptype,Saveinit, InvAmountFC, InvAmountPR, Fcused_uniq, PRFcused_uniq, FuncFcused_uniq)
		SELECT A.UniqApHead,  A.UniqSupNo, A.PoNum, A.InvNo, A.InvDate, A.Due_Date, A.InvAmount, S.Supname,A.Aptype,a.INIT, A.InvAmountFC, A.InvAmountPR, A.Fcused_uniq, A.PRFcused_uniq, A.FuncFcused_uniq
			FROM ApMaster A INNER JOIN  @Supplier S ON A.UNIQSUPNO = S.Uniqsupno
			WHERE 
			1=CASE WHEN @singlePoNum=1 THEN 1 
					WHEN  @singlePoNum=0 and CAST(InvDate as DATE) BETWEEN @lcDateStart and  @lcDateEnd THEN 1
					ELSE 0 END
			AND 1= CASE WHEN @singlePoNum=1 AND A.PONUM =@lcPoNum THEN 1 
					WHEN @singlePoNum=1 AND A.PONUM <> @lcPoNum THEN 0
					ELSE 1 END		
				
		-- 01/30/17 VL added functional currency code		
		INSERT INTO @SupHistFC (UniqApHead,  UniqSupNo, PoNum, InvNo, InvDate,Due_Date, InvAmount, Supname,nRec,Indexdate,saveinit,InvAmountFC, InvAmountPR, Fcused_uniq, PRFcused_uniq, FuncFcused_uniq)
			SELECT UniqApHead,  UniqSupNo, PoNum, InvNo, InvDate,Due_Date, InvAmount, Supname,1 ,InvDate,Saveinit, InvAmountFC, InvAmountPR, Fcused_uniq, PRFcused_uniq, FuncFcused_uniq
			FROM @InvoiceInfoFC 		
	
		-- collect all DM (ignore the data range)
		-- 01/30/17 VL added functional currency code		
		INSERT INTO @SupHistFC (UniqApHead, DmemoNo, DmDate, DmTotal, DmApplied, SupName, UniqSupNo, PoNum,
			InvNo, InvDate,Due_Date,IndexDate,saveinit,DmTotalFC, DmAppliedFC, DmTotalPR, DmAppliedPR, Fcused_uniq, PRFcused_uniq, FuncFcused_uniq)			
		SELECT D.UniqApHead, D.DmemoNo, D.DmDate, D.DmTotal, D.DmApplied, H.SupName, 
			H.UniqSupNo, H.PoNum ,H.InvNo, H.InvDate, H.Due_Date,DmDate,d.SAVEINIT,D.DmTotalFC, D.DmAppliedFC, D.DmTotalPR, D.DmAppliedPR, D.Fcused_uniq, D.PRFcused_uniq, D.FuncFcused_uniq
		FROM  DMemos D INNER JOIN @InvoiceInfoFC H ON  D.UniqApHead = H.UniqApHead 
		--- 04/30/14 YS  APTYPE<>'DM' when avoiding general debit memo
		--WHERE LEFT(H.Invno,2)<>'DM'
		WHERE H.Aptype<>'DM'
		-- collect checks (ignore the range)
		-- 01/30/17 VL added functional currency code		
		INSERT INTO @SupHistFC (UniqApHead, CheckDate, CheckNo, AprPay, Disc_Tkn, SupName, UniqSupNo, InvNo, InvDate, 
					PoNum, Due_Date, VoidAmt,IndexDate,saveinit, AprPayFC, Disc_TknFC, VoidAmtFC, AprPayPR, Disc_TknPR, VoidAmtPR, Fcused_uniq, PRFcused_uniq, FuncFcused_uniq) 
			SELECT CD.UniqApHead, CH.CheckDate, CH.CheckNo, CD.AprPay, CD.Disc_Tkn, I.SupName, I.UniqSupNo,  
				 I.InvNo, I.InvDate, I.PoNum,I.Due_Date,
					CASE WHEN CH.[Status] ='Voiding Entry' THEN ABS(CD.APRPAY) ELSE 0.00 END ,CheckDate,ch.SAVEINIT
					, CD.AprPayFC, CD.Disc_TknFC, CASE WHEN CH.[Status] ='Voiding Entry' THEN ABS(CD.APRPAYFC) ELSE 0.00 END
					, CD.AprPayPR, CD.Disc_TknPR, CASE WHEN CH.[Status] ='Voiding Entry' THEN ABS(CD.APRPAYPR) ELSE 0.00 END
					, CH.Fcused_uniq, CH.PRFcused_uniq, CH.FuncFcused_uniq
		FROM  ApChkMst CH INNER JOIN ApChkDet CD ON CH.APCHK_UNIQ=CD.APCHK_UNIQ
		INNER JOIN @InvoiceInfoFC I on CD.UNIQAPHEAD =I.UniqApHead 
	
		-- collect offset information
		-- 01/30/17 VL added functional currency code	
		INSERT INTO @SupHistFC (UniqApHead,SupName, UniqSupNo,InvNo, InvDate, 
					PoNum, Due_Date,OffsetDate ,OffsetAmount ,Indexdate,saveinit, OffsetAmountFC, OffsetAmountPR, Fcused_uniq, PRFcused_uniq, FuncFcused_uniq )
			select apoffset.UNIQAPHEAD,i.Supname,I.Uniqsupno,I.InvNo, I.InvDate, 
					I.PoNum, I.Due_Date,
					apoffset.[DATE], [AMOUNT] , apoffset.[DATE],INITIALS, [AMOUNTFC], [AMOUNTPR], APOffset.FCUSED_UNIQ, APOffset.PRFcused_uniq, APOffset.FuncFcused_uniq
			from APOFFSET INNER JOIN @InvoiceInfoFC I on ApOffset.UNIQAPHEAD = i.UniqApHead
	
		-- collect offset as separate antity
		--UPDATE @SupHist  SET OffsetAmount = Offset.OffAmount FROM 	
		--	(SELECT Apoffset.UniqApHEad,SUM(Amount) AS OffAmount
		--		FROM ApOffset INNER JOIN @InvoiceInfo I on ApOffset.UNIQAPHEAD = i.UniqApHead GROUP BY APOFFSET.UNIQAPHEAD) Offset
		--		INNER JOIN @SupHist S ON Offset.UNIQAPHEAD =S.UniqApHead 
	
		UPDATE @SupHistFC SET DaysPay = DATEDIFF(Day,InvDate,CheckDate) WHERE CheckDate is not null and InvDate is not null 	
		-- 01/30/17 VL added functional currency code	
		UPDATE @SupHistFC SET TSymbol = Symbol FROM @SupHistFC SupHistFC, Fcused WHERE SupHistFC.Fcused_Uniq = Fcused.Fcused_Uniq
		UPDATE @SupHistFC SET PSymbol = Symbol FROM @SupHistFC SupHistFC, Fcused WHERE SupHistFC.PRFcused_uniq = Fcused.Fcused_Uniq
		UPDATE @SupHistFC SET FSymbol = Symbol FROM @SupHistFC SupHistFC, Fcused WHERE SupHistFC.FuncFcused_Uniq = Fcused.Fcused_Uniq
		-- create total by supplier and total overall	
		-- 08/17/17 VL re-arrange the list
		SELECT UniqApHead, UniqSupNo, Ponum, InvNo,	InvDate, Due_Date, DmemoNo, DmDate, CheckDate, CheckNo, SupName, DaysPay, OffsetDate
				,InvAmount,	  DmTotal, DmApplied, AprPay, Disc_Tkn, VoidAmt, OffsetAmount, SUM(InvAmount) OVER (PARTITION By Uniqsupno) as SupInvAmount,
				SUM(InvAmount) OVER () as InvTotal, FSymbol
				,InvAmountFC, DmTotalFC, DmAppliedFC,AprPayFC, Disc_TknFC, VoidAmtFC, OffsetAmountFC, SUM(InvAmountFC) OVER (PARTITION By Uniqsupno) as SupInvAmountFC,
				SUM(InvAmountFC) OVER () as InvTotalFC, TSymbol
				,InvAmountPR, DmTotalPR, DmAppliedPR,AprPayPR, Disc_TknPR, VoidAmtPR ,OffsetAmountPR, SUM(InvAmountPR) OVER (PARTITION By Uniqsupno) as SupInvAmountPR,
				SUM(InvAmountPR) OVER () as InvTotalPR, PSymbol
				,Fcused_uniq, PRFcused_uniq, FuncFcused_uniq, nRec,Indexdate,saveinit
							
		 from @SupHistFC H order by TSymbol, SupName,invno,nrec,indexdate
		END
	END--End of FC installed

END