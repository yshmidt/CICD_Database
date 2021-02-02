
-- =============================================
-- Author:			<Debbie>
-- Create date:		<05/18/2010,>
-- Description:		<Compiles the detailed AP Invoice information>
-- Used On:			<Crystal Report {ap_rep3.rpt} and {ap_rep4.rtp}>
-- Modifications:	03/25/2013 DRP:  Range reported that the had hit the selection box limitation within crystal report version.  
--									 So I had to modify the stored procedure to use the parameters within the procedure instead of in the CR itself.  This will also speed the response time of the report.
---					04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
--					07/18/2014 DRP:  Added @userid, added the Supplier List sectio to work with WebManex.	Changed APStatus from '*' for All to 'All' for All.  Added the @lcSortOrder to work properly with the WebManex QuickView results. 
--									Added lPrepay to the @results, so I could use that instead of Left(invno = 'Prepaid') for the results. 
--					07/22/2014 DRP:  I had incorrectly used Disc_days when I should have been using Disc_pct when calculating the AvailDisc throughout the procedure. 
--					12/12/14 DS Added supplier status filter
--					01/16/2015 DRP:  Added uniqsupno to the results as requested by a customer.  
--					06/23/2015 DRP:  needed to change from Union to Union All in the situation there were exact same qty,etc . . . received against schedule dates 
--					02/02/2016 VL:   Added code for foreign currency
--					04/08/2016 VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--					04/22/2016 DRP:  added Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency
--					01/30/2017 VL:	 Added functional currency code
-- 07/13/18 VL changed supname from char(30) to char(50)
-- =============================================
CREATE PROCEDURE [dbo].[rptApInvDetail]

--declare
		@lcApplyDate char (20) = 'Invoice Date'		--This is where the user would determine what the date range is applied to (Invoice Date, Due Date or Transaction Date)
		,@lcDateStart as smalldatetime= null	--used in Date Range:  Start
		,@lcDateEnd as smalldatetime = null		--Used in Date Range:  End
		,@lcUniqSupNo as varchar(max) = 'All'		 
		--,@lcSup as varchar (35) = '*'				--07/18/2014 DRP: removed and replaced by @lcUniqSupno
		,@lcApStatus char(15) = 'All'				--AP Status filter.  (All,Editable,Paid,Released to GL or Paid/Rel to GL)
		,@lcRptType as char(10) = 'Detailed'		--07/18/2014 DRP:  (Detailed or Summary)  Added for Quickview results so it knows to display detailed or summary results. 
		,@lcSortOrder as char(20) = 'Invoice Date'	--07/18/2014 DRP: (Invoice Date,Due Date,Transaction Date,Reference,Status)  This is where the users will pick how they wish for the report to be orderd by.
		,@userId uniqueidentifier= null
		,@supplierStatus varchar(20) = 'All'


AS
begin 

--07/18/2014 DRP:  ADDED THE SUPPLIER LIST SELECTION BELOW SO THAT IT WILL WORK WITH THE WEBMANEX AND USERIDS
/*SUPPLIER LIST*/
	---- SET NOCOUNT ON added to prevent extra result sets from
	---- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE  @tSupplier tSupplier
	declare @tSupNo as table (Uniqsupno char (10))
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus;
	
	--- have to check for all suppliers @lcUniqSupNo for all no need to run [fn_simpleVarcharlistToTable], no data will be retuned
	IF @lcUniqSupNo is not null and @lcUniqSupNo <>'' and @lcUniqSupNo<>'All'
		insert into @tSupNo select * from dbo.[fn_simpleVarcharlistToTable](@lcUniqSupNo,',')
			where CAST (id as CHAR(10)) in (select Uniqsupno from @tSupplier)
	ELSE
	--- empty or null customer or part number means no selection were made
	IF  @lcUniqSupNo='All'	
	BEGIN
		INSERT INTO @tSupNo SELECT UniqSupno FROM @tSupplier	
	
	END		 

	-- 02/02/16 VL added new fields to @results
	/*BEGINNING OF SELECT STATEMENT*/
	-- 01/30/17 VL changed TCurrency, FCurrency to TSymbol, PSymbol, FSymbol, also added functional currency fields
	-- 07/13/18 VL changed supname from char(30) to char(50)
	declare @results as table	(SupName char(50),uniqaphead char(10),INVNO char(50),APSTATUS char(15),PONUM char(15),TRANS_DT smalldatetime,INVDATE smalldatetime,DUE_DATE smalldatetime
								 ,InvAmount numeric(20,2),appmts Numeric(20,2),disc_tkn Numeric(20,2),BalAmt Numeric(20,2),AvailDisc Numeric(20,2),CHOLDSTATUS char(10)  
								 ,ITEM_NO numeric(7,0),ITEM_DESC char(25),QTY_EACH decimal (10,2),PRICE_EACH numeric (13,5),ITEM_TOTAL numeric(12,2),GL_NBR char(13),lPrepay bit,uniqsupno char(10)
								 ,InvAmountFC numeric(20,2),appmtsFC Numeric(20,2),disc_tknFC Numeric(20,2),BalAmtFC Numeric(20,2),AvailDiscFC Numeric(20,2), PRICE_EACHFC numeric (13,5),ITEM_TOTALFC numeric(12,2)
								 ,InvAmountPR numeric(20,2),appmtsPR Numeric(20,2),disc_tknPR Numeric(20,2),BalAmtPR Numeric(20,2),AvailDiscPR Numeric(20,2), PRICE_EACHPR numeric (13,5),ITEM_TOTALPR numeric(12,2)
								 , TSymbol char(3),PSymbol char(3),FSymbol char(3)
								 )

-- 02/08/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
BEGIN
----------------------

	--&&& BEGIN APPLY TO INVOICE DATE:  This section is for if the users wants the date range to be applied to the Invoice Date
	IF (@lcApplyDate = 'Invoice Date') 
		BEGIN	
		;
		with zap as	(SELECT	TOP (100) PERCENT s1.SUPNAME,apm1.uniqaphead,apm1.INVNO,apm1.apstatus,apm1.PONUM,apm1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt) AS INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt) as Due_date
					 ,apm1.invAmount,apm1.appmts,apm1.disc_tkn,CAST(apm1.INVAMOUNT - apm1.APPMTS - apm1.DISC_TKN AS numeric(12, 2)) AS BalAmt,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						  WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
						 ELSE (apm1.invamount-apm1.appmts-apm1.disc_tkn) * (pmt1.DISC_PCT / 100) END AS AvailDisc
					 ,apm1.CHOLDSTATUS,apd1.ITEM_NO, apd1.ITEM_DESC, apd1.QTY_EACH, apd1.PRICE_EACH, apd1.ITEM_TOTAL, apd1.GL_NBR,apm1.lPrepay,apm1.UNIQSUPNO

			FROM	dbo.APMASTER as apm1 INNER JOIN
					dbo.SUPINFO as s1 ON apm1.UNIQSUPNO = s1.UNIQSUPNO left outer JOIN
					dbo.APDETAIL as apd1 ON apm1.UNIQAPHEAD = apd1.UNIQAPHEAD LEFT OUTER JOIN
					dbo.PMTTERMS AS pmt1 ON apm1.TERMS = pmt1.DESCRIPT

			where	apm1.apstatus <> '' and apm1.invno <> ''
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	 and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			union all

			SELECT	S1.SUPNAME,APM1.UNIQAPHEAD,APM1.REASON as invno,APM1.APSTATUS,APM1.PONUM,APM1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt)as INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt) as Due_date,-APC1.APRPAY AS InvAmount
					,cast(0.00 as numeric(12,2))as appmts,cast(0.00 as numeric(12,2)) as Disc_tkn, CAST(APM1.INVAMOUNT - APM1.APPMTS - APM1.DISC_TKN AS numeric(12, 2)) AS BalAmt
					,CAST(0.00 AS numeric(12, 2))AS AvailDisc,cast('' as char(8)) as choldstatus,CAST(1 AS numeric(7, 0)) AS Item_no, CAST('' AS char(25)) AS item_desc
					,CAST(0.00 AS decimal(10, 2)) AS qty_each,CAST(0.00 AS numeric(13, 5)) AS Price_each, CAST(0.00 AS numeric(12, 2)) AS Item_total, CAST(apc1.gl_nbr AS char(13)) AS Gl_nbr,apm1.lPrepay,apm1.UNIQSUPNO
		
			FROM    dbo.APMASTER AS APM1 INNER JOIN
					dbo.APCHKDET AS APC1 ON APM1.UNIQAPHEAD = APC1.UNIQAPHEAD INNER JOIN
					dbo.SUPINFO AS S1 ON APM1.UNIQSUPNO = S1.UNIQSUPNO
		
			WHERE	(LEFT(APC1.ITEM_DESC, 10) = 'Prepayment')
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			) 
			
		-- 02/02/16 VL have to specifiy fields
		insert into @results (Supname, uniqaphead, Invno, APSTATUS, PONUM, TRANS_DT, INVDATE, DUE_DATE, InvAmount, appmts,disc_tkn, BalAmt,AvailDisc,CHOLDSTATUS
							,ITEM_No, ITEM_DESC, QTY_EACH, PRICE_EACH, ITEM_TOTAL, GL_NBR, lPrepay,uniqsupno)
			   select	t1.SUPNAME,t1.uniqaphead,t1.INVNO,t1.APSTATUS,t1.PONUM,t1.TRANS_DT,t1.INVDATE,t1.DUE_DATE
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then Invamount ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmount
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmts ELSE CAST(0.00 as Numeric(20,2)) END AS appmts
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tkn ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tkn
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmt ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmt
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDisc ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDisc
						,t1.CHOLDSTATUS,t1.ITEM_NO, t1.ITEM_DESC, t1.QTY_EACH, t1.PRICE_EACH, t1.ITEM_TOTAL, t1.GL_NBR,t1.lPrepay,t1.UNIQSUPNO
				from	zap as t1 
				where	t1.invdate >=@lcDateStart and t1.invdate <@lcDateEnd+1


	END
	--&&& END APPLY TO INVOICE DATE

	--&&& BEGIN APPLY TO DUE DATE:  This section is for if the users wants the date range to be applied to the Due Date
	IF (@lcApplyDate = 'Due Date') 
		BEGIN	
		;
		with zap as	(SELECT	TOP (100) PERCENT s1.SUPNAME,apm1.uniqaphead,apm1.INVNO,apm1.apstatus,apm1.PONUM,apm1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt) AS INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt) as Due_date
					 ,apm1.invAmount,apm1.appmts,apm1.disc_tkn,CAST(apm1.INVAMOUNT - apm1.APPMTS - apm1.DISC_TKN AS numeric(12, 2)) AS BalAmt,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
							ELSE (apm1.invamount-apm1.appmts-apm1.disc_tkn) * (pmt1.disc_pct / 100) END AS AvailDisc
					 ,apm1.CHOLDSTATUS,apd1.ITEM_NO, apd1.ITEM_DESC, apd1.QTY_EACH, apd1.PRICE_EACH, apd1.ITEM_TOTAL, apd1.GL_NBR,apm1.lPrepay,apm1.UNIQSUPNO

			FROM	dbo.APMASTER as apm1 INNER JOIN
					dbo.SUPINFO as s1 ON apm1.UNIQSUPNO = s1.UNIQSUPNO left outer JOIN
					dbo.APDETAIL as apd1 ON apm1.UNIQAPHEAD = apd1.UNIQAPHEAD LEFT OUTER JOIN
					dbo.PMTTERMS AS pmt1 ON apm1.TERMS = pmt1.DESCRIPT

			where	apm1.apstatus <> '' and apm1.invno <> ''
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			union all

			SELECT	S1.SUPNAME,APM1.UNIQAPHEAD,APM1.REASON as invno,APM1.APSTATUS,APM1.PONUM,APM1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt)as INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt),-APC1.APRPAY AS InvAmount
					,cast(0.00 as numeric(12,2))as appmts,cast(0.00 as numeric(12,2)) as Disc_tkn, CAST(APM1.INVAMOUNT - APM1.APPMTS - APM1.DISC_TKN AS numeric(12, 2)) AS BalAmt
					,CAST(0.00 AS numeric(12, 2))AS AvailDisc,cast('' as char(8)) as choldstatus,CAST(1 AS numeric(7, 0)) AS Item_no, CAST('' AS char(25)) AS item_desc
					,CAST(0.00 AS decimal(10, 2)) AS qty_each,CAST(0.00 AS numeric(13, 5)) AS Price_each, CAST(0.00 AS numeric(12, 2)) AS Item_total, CAST(apc1.gl_nbr AS char(13)) AS Gl_nbr,apm1.lPrepay,apm1.UNIQSUPNO
		
			FROM    dbo.APMASTER AS APM1 INNER JOIN
					dbo.APCHKDET AS APC1 ON APM1.UNIQAPHEAD = APC1.UNIQAPHEAD INNER JOIN
					dbo.SUPINFO AS S1 ON APM1.UNIQSUPNO = S1.UNIQSUPNO
		
			WHERE	(LEFT(APC1.ITEM_DESC, 10) = 'Prepayment')
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP: 	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			) 
		-- 02/02/16 VL have to specifiy fields
		insert into @results (Supname, uniqaphead, Invno, APSTATUS, PONUM, TRANS_DT, INVDATE, DUE_DATE, InvAmount, appmts,disc_tkn, BalAmt,AvailDisc,CHOLDSTATUS
							,ITEM_No, ITEM_DESC, QTY_EACH, PRICE_EACH, ITEM_TOTAL, GL_NBR, lPrepay,uniqsupno)
			   select	t1.SUPNAME,t1.uniqaphead,t1.INVNO,t1.APSTATUS,t1.PONUM,t1.TRANS_DT,t1.INVDATE,t1.DUE_DATE
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then Invamount ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmount
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmts ELSE CAST(0.00 as Numeric(20,2)) END AS appmts
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tkn ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tkn
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmt ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmt
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDisc ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDisc
						,t1.CHOLDSTATUS,t1.ITEM_NO, t1.ITEM_DESC, t1.QTY_EACH, t1.PRICE_EACH, t1.ITEM_TOTAL, t1.GL_NBR,t1.lPrepay,t1.UNIQSUPNO
				from	zap as t1 
				where	t1.Due_date >=@lcDateStart and t1.Due_date <@lcDateEnd+1

	END
	--&&& END APPLY TO DUE DATE

	--&&& BEGIN APPLY TO TRANSACTION DATE:  This section is for if the users wants the date range to be applied to the transaction Date
	IF (@lcApplyDate = 'Transaction Date') 
		BEGIN	
		;
		with zap as	(SELECT	TOP (100) PERCENT s1.SUPNAME,apm1.uniqaphead,apm1.INVNO,apm1.apstatus,apm1.PONUM,apm1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt) AS INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt) as Due_date
					 ,apm1.invAmount,apm1.appmts,apm1.disc_tkn,CAST(apm1.INVAMOUNT - apm1.APPMTS - apm1.DISC_TKN AS numeric(12, 2)) AS BalAmt,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
							ELSE (apm1.invamount-apm1.appmts-apm1.disc_tkn) * (pmt1.DISC_PCT / 100) END AS AvailDisc
					 ,apm1.CHOLDSTATUS,apd1.ITEM_NO, apd1.ITEM_DESC, apd1.QTY_EACH, apd1.PRICE_EACH, apd1.ITEM_TOTAL, apd1.GL_NBR,apm1.lPrepay,apm1.UNIQSUPNO

			FROM	dbo.APMASTER as apm1 INNER JOIN
					dbo.SUPINFO as s1 ON apm1.UNIQSUPNO = s1.UNIQSUPNO left outer JOIN
					dbo.APDETAIL as apd1 ON apm1.UNIQAPHEAD = apd1.UNIQAPHEAD LEFT OUTER JOIN
					dbo.PMTTERMS AS pmt1 ON apm1.TERMS = pmt1.DESCRIPT

			where	apm1.apstatus <> '' and apm1.invno <> ''
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			union all

			SELECT	S1.SUPNAME,APM1.UNIQAPHEAD,APM1.REASON as invno,APM1.APSTATUS,APM1.PONUM,APM1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt)as INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt),-APC1.APRPAY AS InvAmount
					,cast(0.00 as numeric(12,2))as appmts,cast(0.00 as numeric(12,2)) as Disc_tkn, CAST(APM1.INVAMOUNT - APM1.APPMTS - APM1.DISC_TKN AS numeric(12, 2)) AS BalAmt
					,CAST(0.00 AS numeric(12, 2))AS AvailDisc,cast('' as char(8)) as choldstatus,CAST(1 AS numeric(7, 0)) AS Item_no, CAST('' AS char(25)) AS item_desc
					,CAST(0.00 AS decimal(10, 2)) AS qty_each,CAST(0.00 AS numeric(13, 5)) AS Price_each, CAST(0.00 AS numeric(12, 2)) AS Item_total, CAST(apc1.gl_nbr AS char(13)) AS Gl_nbr,apm1.lPrepay,apm1.UNIQSUPNO
		
			FROM    dbo.APMASTER AS APM1 INNER JOIN
					dbo.APCHKDET AS APC1 ON APM1.UNIQAPHEAD = APC1.UNIQAPHEAD INNER JOIN
					dbo.SUPINFO AS S1 ON APM1.UNIQSUPNO = S1.UNIQSUPNO
		
			WHERE	(LEFT(APC1.ITEM_DESC, 10) = 'Prepayment')
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			) 
		
		-- 02/02/16 VL have to specify fields
		insert into @results (Supname, uniqaphead, Invno, APSTATUS, PONUM, TRANS_DT, INVDATE, DUE_DATE, InvAmount, appmts,disc_tkn, BalAmt,AvailDisc,CHOLDSTATUS
							,ITEM_No, ITEM_DESC, QTY_EACH, PRICE_EACH, ITEM_TOTAL, GL_NBR, lPrepay,uniqsupno)
			   select	t1.SUPNAME,t1.uniqaphead,t1.INVNO,t1.APSTATUS,t1.PONUM,t1.TRANS_DT,t1.INVDATE,t1.DUE_DATE
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then Invamount ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmount
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmts ELSE CAST(0.00 as Numeric(20,2)) END AS appmts
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tkn ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tkn
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmt ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmt
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDisc ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDisc
						,t1.CHOLDSTATUS,t1.ITEM_NO, t1.ITEM_DESC, t1.QTY_EACH, t1.PRICE_EACH, t1.ITEM_TOTAL, t1.GL_NBR,t1.lPrepay,t1.UNIQSUPNO
				from	zap as t1 
				where	t1.Trans_dt >=@lcDateStart and t1.Trans_dt <@lcDateEnd+1

	END
	--&&& END APPLY TO TRANSACTION DATE


	/*BELOW IS WHERE WE SELECT TO DISPLAY DETAILED/SUMMARY RESULT. . . IT WILL ALSO DETERMINE THE SORT ORDER OF RESULTS FOR WEBMANEX.*/ --07/18/2014 DRP
	if (@lcRptType = 'Detailed')
	begin  --&&Detailed Begin
		IF (@lcSortOrder = 'Invoice Date')
			Begin	--&& Invoice Date Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
				from	@results
				Order by SupName,INVDATE,INVNO,uniqaphead
			end		--&& Invoice Date Sort Begin
		else if (@lcSortOrder = 'Due Date')
			Begin	--&& Due Date Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
				from	@results
				Order by SupName,DUE_DATE,INVNO,uniqaphead
			End		--&& Due Date Sort End
		else if (@lcSortOrder = 'Transaction Date')
			Begin	--&& Transaction Date Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
				from	@results
				Order by SupName,TRANS_DT,INVNO,uniqaphead
			End		--&& Transaction Date Sort End
		else if (@lcSortOrder = 'Reference')
			Begin	--&& Reference Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
				from	@results
				Order by SupName,Ponum,INVNO,uniqaphead,INVDATE
			End		--&& Reference Date Sort End
		else if (@lcSortOrder = 'Status')
			Begin	--&& status Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
				from	@results
				Order by SupName,APSTATUS,INVNO,uniqaphead,ponum,INVDATE
			End		--&& status Sort End
	end  --&&Detailed End


	else if (@lcRptType = 'Summary')
	begin --&&Summary Begin
		IF (@lcSortOrder = 'Invoice Date')
			Begin	--&& Invoice Date Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
				from	@results 
				group by Supname,InvDate,Invno,uniqaphead,ponum,trans_dt,invdate,Due_date,Apstatus,CHOLDSTATUS,uniqsupno
			end		--&& Invoice Date Sort Begin
		else if (@lcSortOrder = 'Due Date')
			Begin	--&& Due Date Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
				from	@results 
				group by Supname,Due_Date,Invno,uniqaphead,ponum,trans_dt,invdate,Due_date,Apstatus,CHOLDSTATUS,uniqsupno
			End		--&& Due Date Sort End
		else if (@lcSortOrder = 'Transaction Date')
			Begin	--&& Transaction Date Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
				from	@results 
				group by Supname,TRANS_DT,Invno,uniqaphead,ponum,trans_dt,invdate,Due_date,Apstatus,CHOLDSTATUS,uniqsupno
			End		--&& Transaction Date Sort End
		else if (@lcSortOrder = 'Reference')
			Begin	--&& Reference Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
				from	@results 
				group by Supname,ponum,Invno,uniqaphead,trans_dt,invdate,Due_date,Apstatus,CHOLDSTATUS,uniqsupno
			End		--&& Reference Date Sort End
		else if (@lcSortOrder = 'Status')
			Begin	--&& status Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
				from	@results 
				group by Supname,Apstatus,Invno,uniqaphead,ponum,trans_dt,invdate,Due_date,CHOLDSTATUS,uniqsupno
			End		--&& status Sort End

 
	end  --&&Summary End
END -- End of FC not installed

ELSE -- FC installed
	BEGIN

	-- 01/30/17 VL comment out the code, will get 3 currency symbols directly from SQL statement
	--DECLARE @FCurrency char(3) = ''
	--	-- 04/22/16 VL changed to get HC fcused_uniq from function
	--	SELECT @FCurrency = Symbol FROM Fcused WHERE Fcused.Fcused_uniq = dbo.fn_GetHomeCurrency()

	-- 02/02/16 VL added FC fields
	--&&& BEGIN APPLY TO INVOICE DATE:  This section is for if the users wants the date range to be applied to the Invoice Date
	IF (@lcApplyDate = 'Invoice Date') 
		BEGIN	
		;
		-- 02/02/16 VL added Fcused table for currency
		with zap as	(SELECT	TOP (100) PERCENT s1.SUPNAME,apm1.uniqaphead,apm1.INVNO,apm1.apstatus,apm1.PONUM,apm1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt) AS INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt) as Due_date
					 ,apm1.invAmount,apm1.appmts,apm1.disc_tkn,CAST(apm1.INVAMOUNT - apm1.APPMTS - apm1.DISC_TKN AS numeric(12, 2)) AS BalAmt,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						  WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
						 ELSE (apm1.invamount-apm1.appmts-apm1.disc_tkn) * (pmt1.DISC_PCT / 100) END AS AvailDisc
					 ,apm1.CHOLDSTATUS,apd1.ITEM_NO, apd1.ITEM_DESC, apd1.QTY_EACH, apd1.PRICE_EACH, apd1.ITEM_TOTAL, apd1.GL_NBR,apm1.lPrepay,apm1.UNIQSUPNO
					 ,apm1.invAmountFC,apm1.appmtsFC,apm1.disc_tknFC,CAST(apm1.INVAMOUNTFC - apm1.APPMTSFC - apm1.DISC_TKNFC AS numeric(12, 2)) AS BalAmtFC,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						  WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
						 ELSE (apm1.invamountFC-apm1.appmtsFC-apm1.disc_tknFC) * (pmt1.DISC_PCT / 100) END AS AvailDiscFC
					, apd1.PRICE_EACHFC, apd1.ITEM_TOTALFC
					-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
					--, Fcused.Symbol AS Currency
					--,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency	--04/22/2016 DRP:  added
					 ,apm1.invAmountPR,apm1.appmtsPR,apm1.disc_tknPR,CAST(apm1.INVAMOUNTPR - apm1.APPMTSPR - apm1.DISC_TKNPR AS numeric(12, 2)) AS BalAmtPR,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						  WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
						 ELSE (apm1.invamountPR-apm1.appmtsPR-apm1.disc_tknPR) * (pmt1.DISC_PCT / 100) END AS AvailDiscPR
					, apd1.PRICE_EACHPR, apd1.ITEM_TOTALPR, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol

			FROM	dbo.APMASTER as apm1 
					-- 01/30/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON apm1.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON apm1.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON apm1.Fcused_uniq = TF.Fcused_uniq		
					INNER JOIN dbo.SUPINFO as s1 ON apm1.UNIQSUPNO = s1.UNIQSUPNO left outer JOIN
					dbo.APDETAIL as apd1 ON apm1.UNIQAPHEAD = apd1.UNIQAPHEAD LEFT OUTER JOIN
					dbo.PMTTERMS AS pmt1 ON apm1.TERMS = pmt1.DESCRIPT

			where	apm1.apstatus <> '' and apm1.invno <> ''
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	 and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			union all

			SELECT	S1.SUPNAME,APM1.UNIQAPHEAD,APM1.REASON as invno,APM1.APSTATUS,APM1.PONUM,APM1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt)as INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt) as Due_date,-APC1.APRPAY AS InvAmount
					,cast(0.00 as numeric(12,2))as appmts,cast(0.00 as numeric(12,2)) as Disc_tkn, CAST(APM1.INVAMOUNT - APM1.APPMTS - APM1.DISC_TKN AS numeric(12, 2)) AS BalAmt
					,CAST(0.00 AS numeric(12, 2))AS AvailDisc,cast('' as char(8)) as choldstatus,CAST(1 AS numeric(7, 0)) AS Item_no, CAST('' AS char(25)) AS item_desc
					,CAST(0.00 AS decimal(10, 2)) AS qty_each,CAST(0.00 AS numeric(13, 5)) AS Price_each, CAST(0.00 AS numeric(12, 2)) AS Item_total, CAST(apc1.gl_nbr AS char(13)) AS Gl_nbr,apm1.lPrepay,apm1.UNIQSUPNO
					,-APC1.APRPAYFC AS InvAmountFC
					,cast(0.00 as numeric(12,2))as appmtsFC,cast(0.00 as numeric(12,2)) as Disc_tknFC, CAST(APM1.INVAMOUNTFC - APM1.APPMTSFC - APM1.DISC_TKNFC AS numeric(12, 2)) AS BalAmtFC
					,CAST(0.00 AS numeric(12, 2))AS AvailDiscFC, CAST(0.00 AS numeric(13, 5)) AS Price_eachFC, CAST(0.00 AS numeric(12, 2)) AS Item_totalFC
					-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
					--, Fcused.Symbol AS Currency
					--,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency	--04/22/2016 DRP:  added
					,-APC1.APRPAYPR AS InvAmountPR
					,cast(0.00 as numeric(12,2))as appmtsPR,cast(0.00 as numeric(12,2)) as Disc_tknPR, CAST(APM1.INVAMOUNTPR - APM1.APPMTSPR - APM1.DISC_TKNPR AS numeric(12, 2)) AS BalAmtPR
					,CAST(0.00 AS numeric(12, 2))AS AvailDiscPR, CAST(0.00 AS numeric(13, 5)) AS Price_eachPR, CAST(0.00 AS numeric(12, 2)) AS Item_totalPR
					, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM    dbo.APMASTER as apm1
					-- 01/30/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON apm1.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON apm1.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON apm1.Fcused_uniq = TF.Fcused_uniq		
					INNER JOIN
					dbo.APCHKDET AS APC1 ON APM1.UNIQAPHEAD = APC1.UNIQAPHEAD INNER JOIN
					dbo.SUPINFO AS S1 ON APM1.UNIQSUPNO = S1.UNIQSUPNO
		
			WHERE	(LEFT(APC1.ITEM_DESC, 10) = 'Prepayment')
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			) 
		-- 02/02/16 VL have to specify the fields
		-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
		insert into @results (Supname, uniqaphead, Invno, APSTATUS, PONUM, TRANS_DT, INVDATE, DUE_DATE, InvAmount, appmts,disc_tkn, BalAmt,AvailDisc,CHOLDSTATUS
							,ITEM_No, ITEM_DESC, QTY_EACH, PRICE_EACH, ITEM_TOTAL, GL_NBR, lPrepay,uniqsupno, InvAmountFC, appmtsFC,disc_tknFC, BalAmtFC,AvailDiscFC
							,PRICE_EACHFC, ITEM_TOTALFC
							,InvAmountPR, appmtsPR,disc_tknPR, BalAmtPR,AvailDiscPR,PRICE_EACHPR, ITEM_TOTALPR, TSymbol,PSymbol, FSymbol)
			   select	t1.SUPNAME,t1.uniqaphead,t1.INVNO,t1.APSTATUS,t1.PONUM,t1.TRANS_DT,t1.INVDATE,t1.DUE_DATE
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then Invamount ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmount
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmts ELSE CAST(0.00 as Numeric(20,2)) END AS appmts
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tkn ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tkn
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmt ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmt
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDisc ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDisc
						,t1.CHOLDSTATUS,t1.ITEM_NO, t1.ITEM_DESC, t1.QTY_EACH, t1.PRICE_EACH, t1.ITEM_TOTAL, t1.GL_NBR,t1.lPrepay,t1.UNIQSUPNO
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then InvamountFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmountFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmtsFC ELSE CAST(0.00 as Numeric(20,2)) END AS appmtsFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tknFC ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tknFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmtFC ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmtFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDiscFC ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDiscFC
						,t1.PRICE_EACHFC, t1.ITEM_TOTALFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then InvamountPR ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmountPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmtsPR ELSE CAST(0.00 as Numeric(20,2)) END AS appmtsPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tknPR ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tknPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmtPR ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmtPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDiscPR ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDiscPR
						,t1.PRICE_EACHPR, t1.ITEM_TOTALPR
						, t1.TSymbol,t1.PSymbol, t1.FSymbol
				from	zap as t1 
				where	t1.invdate >=@lcDateStart and t1.invdate <@lcDateEnd+1


	END
	--&&& END APPLY TO INVOICE DATE

	--&&& BEGIN APPLY TO DUE DATE:  This section is for if the users wants the date range to be applied to the Due Date
	IF (@lcApplyDate = 'Due Date') 
		BEGIN	
		;
		with zap as	(SELECT	TOP (100) PERCENT s1.SUPNAME,apm1.uniqaphead,apm1.INVNO,apm1.apstatus,apm1.PONUM,apm1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt) AS INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt) as Due_date
					 ,apm1.invAmount,apm1.appmts,apm1.disc_tkn,CAST(apm1.INVAMOUNT - apm1.APPMTS - apm1.DISC_TKN AS numeric(12, 2)) AS BalAmt,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
							ELSE (apm1.invamount-apm1.appmts-apm1.disc_tkn) * (pmt1.disc_pct / 100) END AS AvailDisc
					 ,apm1.CHOLDSTATUS,apd1.ITEM_NO, apd1.ITEM_DESC, apd1.QTY_EACH, apd1.PRICE_EACH, apd1.ITEM_TOTAL, apd1.GL_NBR,apm1.lPrepay,apm1.UNIQSUPNO
					 ,apm1.invAmountFC,apm1.appmtsFC,apm1.disc_tknFC,CAST(apm1.INVAMOUNTFC - apm1.APPMTSFC - apm1.DISC_TKNFC AS numeric(12, 2)) AS BalAmtFC,
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
							ELSE (apm1.invamountFC-apm1.appmtsFC-apm1.disc_tknFC) * (pmt1.disc_pct / 100) END AS AvailDiscFC
					,apd1.PRICE_EACHFC, apd1.ITEM_TOTALFC
					-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
					--, Fcused.Symbol AS Currency
					--,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency	--04/22/2016 DRP:  added
					 ,apm1.invAmountPR,apm1.appmtsPR,apm1.disc_tknPR,CAST(apm1.INVAMOUNTPR - apm1.APPMTSPR - apm1.DISC_TKNPR AS numeric(12, 2)) AS BalAmtPR,
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
							ELSE (apm1.invamountPR-apm1.appmtsPR-apm1.disc_tknPR) * (pmt1.disc_pct / 100) END AS AvailDiscPR
					,apd1.PRICE_EACHPR, apd1.ITEM_TOTALPR
					, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM	dbo.APMASTER as apm1
					-- 01/30/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON apm1.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON apm1.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON apm1.Fcused_uniq = TF.Fcused_uniq		
					INNER JOIN
					dbo.SUPINFO as s1 ON apm1.UNIQSUPNO = s1.UNIQSUPNO left outer JOIN
					dbo.APDETAIL as apd1 ON apm1.UNIQAPHEAD = apd1.UNIQAPHEAD LEFT OUTER JOIN
					dbo.PMTTERMS AS pmt1 ON apm1.TERMS = pmt1.DESCRIPT

			where	apm1.apstatus <> '' and apm1.invno <> ''
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			union all

			SELECT	S1.SUPNAME,APM1.UNIQAPHEAD,APM1.REASON as invno,APM1.APSTATUS,APM1.PONUM,APM1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt)as INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt),-APC1.APRPAY AS InvAmount
					,cast(0.00 as numeric(12,2))as appmts,cast(0.00 as numeric(12,2)) as Disc_tkn, CAST(APM1.INVAMOUNT - APM1.APPMTS - APM1.DISC_TKN AS numeric(12, 2)) AS BalAmt
					,CAST(0.00 AS numeric(12, 2))AS AvailDisc,cast('' as char(8)) as choldstatus,CAST(1 AS numeric(7, 0)) AS Item_no, CAST('' AS char(25)) AS item_desc
					,CAST(0.00 AS decimal(10, 2)) AS qty_each,CAST(0.00 AS numeric(13, 5)) AS Price_each, CAST(0.00 AS numeric(12, 2)) AS Item_total, CAST(apc1.gl_nbr AS char(13)) AS Gl_nbr,apm1.lPrepay,apm1.UNIQSUPNO
					,-APC1.APRPAYFC AS InvAmountFC
					,cast(0.00 as numeric(12,2))as appmtsFC,cast(0.00 as numeric(12,2)) as Disc_tknFC, CAST(APM1.INVAMOUNTFC - APM1.APPMTSFC - APM1.DISC_TKNFC AS numeric(12, 2)) AS BalAmtFC
					,CAST(0.00 AS numeric(12, 2))AS AvailDiscFC
					,CAST(0.00 AS numeric(13, 5)) AS Price_eachFC, CAST(0.00 AS numeric(12, 2)) AS Item_totalFC
					-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
					--, Fcused.Symbol AS Currency
					--,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency	--04/22/2016 DRP:  added
					,-APC1.APRPAYPR AS InvAmountPR
					,cast(0.00 as numeric(12,2))as appmtsPR,cast(0.00 as numeric(12,2)) as Disc_tknPR, CAST(APM1.INVAMOUNTPR - APM1.APPMTSPR - APM1.DISC_TKNPR AS numeric(12, 2)) AS BalAmtPR
					,CAST(0.00 AS numeric(12, 2))AS AvailDiscPR
					,CAST(0.00 AS numeric(13, 5)) AS Price_eachPR, CAST(0.00 AS numeric(12, 2)) AS Item_totalPR
					, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM    dbo.APMASTER as apm1
					-- 01/30/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON apm1.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON apm1.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON apm1.Fcused_uniq = TF.Fcused_uniq		
					INNER JOIN
					dbo.APCHKDET AS APC1 ON APM1.UNIQAPHEAD = APC1.UNIQAPHEAD INNER JOIN
					dbo.SUPINFO AS S1 ON APM1.UNIQSUPNO = S1.UNIQSUPNO
		
			WHERE	(LEFT(APC1.ITEM_DESC, 10) = 'Prepayment')
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP: 	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			) 
		-- 02/02/16 VL have to specify the fields
		-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
		insert into @results (Supname, uniqaphead, Invno, APSTATUS, PONUM, TRANS_DT, INVDATE, DUE_DATE, InvAmount, appmts,disc_tkn, BalAmt,AvailDisc,CHOLDSTATUS
							,ITEM_No, ITEM_DESC, QTY_EACH, PRICE_EACH, ITEM_TOTAL, GL_NBR, lPrepay,uniqsupno, InvAmountFC, appmtsFC,disc_tknFC, BalAmtFC,AvailDiscFC
							, PRICE_EACHFC, ITEM_TOTALFC
							,InvAmountPR, appmtsPR,disc_tknPR, BalAmtPR,AvailDiscPR, PRICE_EACHPR, ITEM_TOTALPR
							, TSymbol, PSymbol,FSymbol)
			   select	t1.SUPNAME,t1.uniqaphead,t1.INVNO,t1.APSTATUS,t1.PONUM,t1.TRANS_DT,t1.INVDATE,t1.DUE_DATE
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then Invamount ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmount
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmts ELSE CAST(0.00 as Numeric(20,2)) END AS appmts
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tkn ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tkn
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmt ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmt
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDisc ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDisc
						,t1.CHOLDSTATUS,t1.ITEM_NO, t1.ITEM_DESC, t1.QTY_EACH, t1.PRICE_EACH, t1.ITEM_TOTAL, t1.GL_NBR,t1.lPrepay,t1.UNIQSUPNO
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then InvamountFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmountFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmtsFC ELSE CAST(0.00 as Numeric(20,2)) END AS appmtsFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tknFC ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tknFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmtFC ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmtFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDiscFC ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDiscFC
						,t1.PRICE_EACHFC, t1.ITEM_TOTALFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then InvamountPR ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmountPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmtsPR ELSE CAST(0.00 as Numeric(20,2)) END AS appmtsPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tknPR ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tknPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmtPR ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmtPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDiscPR ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDiscPR
						,t1.PRICE_EACHPR, t1.ITEM_TOTALPR						
						, t1.TSymbol,t1.PSymbol, t1.FSymbol
				from	zap as t1 
				where	t1.Due_date >=@lcDateStart and t1.Due_date <@lcDateEnd+1

	END
	--&&& END APPLY TO DUE DATE

	--&&& BEGIN APPLY TO TRANSACTION DATE:  This section is for if the users wants the date range to be applied to the transaction Date
	IF (@lcApplyDate = 'Transaction Date') 
		BEGIN	
		;
		with zap as	(SELECT	TOP (100) PERCENT s1.SUPNAME,apm1.uniqaphead,apm1.INVNO,apm1.apstatus,apm1.PONUM,apm1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt) AS INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt) as Due_date
					 ,apm1.invAmount,apm1.appmts,apm1.disc_tkn,CAST(apm1.INVAMOUNT - apm1.APPMTS - apm1.DISC_TKN AS numeric(12, 2)) AS BalAmt,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
							ELSE (apm1.invamount-apm1.appmts-apm1.disc_tkn) * (pmt1.DISC_PCT / 100) END AS AvailDisc
					 ,apm1.CHOLDSTATUS,apd1.ITEM_NO, apd1.ITEM_DESC, apd1.QTY_EACH, apd1.PRICE_EACH, apd1.ITEM_TOTAL, apd1.GL_NBR,apm1.lPrepay,apm1.UNIQSUPNO
					,apm1.invAmountFC,apm1.appmtsFC,apm1.disc_tknFC,CAST(apm1.INVAMOUNTFC - apm1.APPMTSFC - apm1.DISC_TKNFC AS numeric(12, 2)) AS BalAmtFC,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
							ELSE (apm1.invamountFC-apm1.appmtsFC-apm1.disc_tknFC) * (pmt1.DISC_PCT / 100) END AS AvailDiscFC
					,apd1.PRICE_EACHFC, apd1.ITEM_TOTALFC
					-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
					--, Fcused.Symbol AS Currency
					--,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency	--04/22/2016 DRP:  added
					,apm1.invAmountPR,apm1.appmtsPR,apm1.disc_tknPR,CAST(apm1.INVAMOUNTPR - apm1.APPMTSPR - apm1.DISC_TKNPR AS numeric(12, 2)) AS BalAmtPR,
					 --- 04/30/14 YS  APTYPE='DM' when checking  if the record belongs to general debit memo
					 --CASE WHEN LEFT(apm1.invno, 2) = 'DM' THEN 0.00 
					 CASE WHEN apm1.aptype='DM' THEN 0.00
						WHEN apm1.invdate + pmt1.disc_days < getdate() THEN 0.00 
							ELSE (apm1.invamountPR-apm1.appmtsPR-apm1.disc_tknPR) * (pmt1.DISC_PCT / 100) END AS AvailDiscPR
					,apd1.PRICE_EACHPR, apd1.ITEM_TOTALPR
					, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM    dbo.APMASTER as apm1
					-- 01/30/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON apm1.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON apm1.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON apm1.Fcused_uniq = TF.Fcused_uniq		
					INNER JOIN
					dbo.SUPINFO as s1 ON apm1.UNIQSUPNO = s1.UNIQSUPNO left outer JOIN
					dbo.APDETAIL as apd1 ON apm1.UNIQAPHEAD = apd1.UNIQAPHEAD LEFT OUTER JOIN
					dbo.PMTTERMS AS pmt1 ON apm1.TERMS = pmt1.DESCRIPT

			where	apm1.apstatus <> '' and apm1.invno <> ''
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			union all

			SELECT	S1.SUPNAME,APM1.UNIQAPHEAD,APM1.REASON as invno,APM1.APSTATUS,APM1.PONUM,APM1.TRANS_DT,isnull(apm1.INVDATE,apm1.Trans_Dt)as INVDATE,isnull(apm1.DUE_DATE,apm1.Trans_dt),-APC1.APRPAY AS InvAmount
					,cast(0.00 as numeric(12,2))as appmts,cast(0.00 as numeric(12,2)) as Disc_tkn, CAST(APM1.INVAMOUNT - APM1.APPMTS - APM1.DISC_TKN AS numeric(12, 2)) AS BalAmt
					,CAST(0.00 AS numeric(12, 2))AS AvailDisc,cast('' as char(8)) as choldstatus,CAST(1 AS numeric(7, 0)) AS Item_no, CAST('' AS char(25)) AS item_desc
					,CAST(0.00 AS decimal(10, 2)) AS qty_each,CAST(0.00 AS numeric(13, 5)) AS Price_each, CAST(0.00 AS numeric(12, 2)) AS Item_total, CAST(apc1.gl_nbr AS char(13)) AS Gl_nbr,apm1.lPrepay,apm1.UNIQSUPNO
					,-APC1.APRPAYFC AS InvAmountFC
					,cast(0.00 as numeric(12,2))as appmtsFC,cast(0.00 as numeric(12,2)) as Disc_tknFC, CAST(APM1.INVAMOUNTFC - APM1.APPMTSFC - APM1.DISC_TKNFC AS numeric(12, 2)) AS BalAmtFC
					,CAST(0.00 AS numeric(12, 2))AS AvailDiscFC, CAST(0.00 AS numeric(13, 5)) AS Price_eachFC, CAST(0.00 AS numeric(12, 2)) AS Item_totalFC
					-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
					--, Fcused.Symbol AS Currency
					--,Fcused.Symbol AS TCurrency, @FCurrency AS FCurrency	--04/22/2016 DRP:  added
					,-APC1.APRPAYPR AS InvAmountPR
					,cast(0.00 as numeric(12,2))as appmtsPR,cast(0.00 as numeric(12,2)) as Disc_tknPR, CAST(APM1.INVAMOUNTPR - APM1.APPMTSPR - APM1.DISC_TKNPR AS numeric(12, 2)) AS BalAmtPR
					,CAST(0.00 AS numeric(12, 2))AS AvailDiscPR, CAST(0.00 AS numeric(13, 5)) AS Price_eachPR, CAST(0.00 AS numeric(12, 2)) AS Item_totalPR
					, TF.Symbol AS TSymbol, PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
			FROM    dbo.APMASTER as apm1
					-- 01/30/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON apm1.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON apm1.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON apm1.Fcused_uniq = TF.Fcused_uniq		
					INNER JOIN
					dbo.APCHKDET AS APC1 ON APM1.UNIQAPHEAD = APC1.UNIQAPHEAD INNER JOIN
					dbo.SUPINFO AS S1 ON APM1.UNIQSUPNO = S1.UNIQSUPNO
		
			WHERE	(LEFT(APC1.ITEM_DESC, 10) = 'Prepayment')
					and 1= case WHEN apm1.uniqsupno IN (SELECT uniqsupno FROM @tSupno) THEN 1 ELSE 0  END
	--07/18/2014 DRP:	and SUPNAME like case when @lcSup ='*' then '%' else @lcSup + '%' end
					and apstatus like case when @lcApStatus ='All' then '%' else @lcApStatus  end

			) 

		-- 02/02/16 VL have to specify the fields
		-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
		insert into @results (Supname, uniqaphead, Invno, APSTATUS, PONUM, TRANS_DT, INVDATE, DUE_DATE, InvAmount, appmts,disc_tkn, BalAmt,AvailDisc,CHOLDSTATUS
							,ITEM_No, ITEM_DESC, QTY_EACH, PRICE_EACH, ITEM_TOTAL, GL_NBR, lPrepay,uniqsupno, InvAmountFC, appmtsFC,disc_tknFC, BalAmtFC,AvailDiscFC
							, PRICE_EACHFC, ITEM_TOTALFC
							,InvAmountPR, appmtsPR,disc_tknPR, BalAmtPR,AvailDiscPR, PRICE_EACHPR, ITEM_TOTALPR,tSymbol, PSymbol, FSymbol)
			   select	t1.SUPNAME,t1.uniqaphead,t1.INVNO,t1.APSTATUS,t1.PONUM,t1.TRANS_DT,t1.INVDATE,t1.DUE_DATE
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then Invamount ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmount
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmts ELSE CAST(0.00 as Numeric(20,2)) END AS appmts
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tkn ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tkn
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmt ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmt
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDisc ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDisc
						,t1.CHOLDSTATUS,t1.ITEM_NO, t1.ITEM_DESC, t1.QTY_EACH, t1.PRICE_EACH, t1.ITEM_TOTAL, t1.GL_NBR,t1.lPrepay,t1.UNIQSUPNO
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then InvamountFC ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmountFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmtsFC ELSE CAST(0.00 as Numeric(20,2)) END AS appmtsFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tknFC ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tknFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmtFC ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmtFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDiscFC ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDiscFC
						,t1.PRICE_EACHFC, t1.ITEM_TOTALFC
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then InvamountPR ELSE CAST(0.00 as Numeric(20,2)) END AS InvAmountPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then appmtsPR ELSE CAST(0.00 as Numeric(20,2)) END AS appmtsPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then disc_tknPR ELSE CAST(0.00 as Numeric(20,2)) END AS disc_tknPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then BalAmtPR ELSE CAST(0.00 as Numeric(20,2)) END AS BalAmtPR
						,CASE WHEN ROW_NUMBER() OVER(Partition by supname,uniqaphead Order by Trans_dt)=1 Then AvailDiscPR ELSE CAST(0.00 as Numeric(20,2)) END AS AvailDiscPR
						,t1.PRICE_EACHPR, t1.ITEM_TOTALPR
						,t1.TSymbol,t1.PSymbol, T1.FSymbol
				from	zap as t1 
				where	t1.Trans_dt >=@lcDateStart and t1.Trans_dt <@lcDateEnd+1

	END
	--&&& END APPLY TO TRANSACTION DATE

	-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
	/*BELOW IS WHERE WE SELECT TO DISPLAY DETAILED/SUMMARY RESULT. . . IT WILL ALSO DETERMINE THE SORT ORDER OF RESULTS FOR WEBMANEX.*/ --07/18/2014 DRP
	if (@lcRptType = 'Detailed')
	begin  --&&Detailed Begin
		IF (@lcSortOrder = 'Invoice Date')
			Begin	--&& Invoice Date Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
						,InvAmountFC,CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end as AmountPaidFC,disc_tknFC,BalAmtFC,AvailDiscFC
						,PRICE_EACHFC,ITEM_TOTALFC
						,InvAmountPR,CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end as AmountPaidPR,disc_tknPR,BalAmtPR,AvailDiscPR
						,PRICE_EACHPR,ITEM_TOTALPR						
						,TSymbol,PSymbol,FSymbol
				from	@results
				Order by TSymbol, SupName,INVDATE,INVNO,uniqaphead
			end		--&& Invoice Date Sort Begin
		else if (@lcSortOrder = 'Due Date')
			Begin	--&& Due Date Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
						,InvAmountFC,CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end as AmountPaidFC,disc_tknFC,BalAmtFC,AvailDiscFC
						,PRICE_EACHFC,ITEM_TOTALFC
						,InvAmountPR,CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end as AmountPaidPR,disc_tknPR,BalAmtPR,AvailDiscPR
						,PRICE_EACHPR,ITEM_TOTALPR						
						,TSymbol,PSymbol,FSymbol
				from	@results
				Order by TSymbol, SupName,DUE_DATE,INVNO,uniqaphead
			End		--&& Due Date Sort End
		else if (@lcSortOrder = 'Transaction Date')
			Begin	--&& Transaction Date Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
						,InvAmountFC,CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end as AmountPaidFC,disc_tknFC,BalAmtFC,AvailDiscFC
						,PRICE_EACHFC,ITEM_TOTALFC
						,InvAmountPR,CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end as AmountPaidPR,disc_tknPR,BalAmtPR,AvailDiscPR
						,PRICE_EACHPR,ITEM_TOTALPR						
						,TSymbol,PSymbol,FSymbol
				from	@results
				Order by TSymbol, SupName,TRANS_DT,INVNO,uniqaphead
			End		--&& Transaction Date Sort End
		else if (@lcSortOrder = 'Reference')
			Begin	--&& Reference Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
						,InvAmountFC,CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end as AmountPaidFC,disc_tknFC,BalAmtFC,AvailDiscFC
						,PRICE_EACHFC,ITEM_TOTALFC
						,InvAmountPR,CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end as AmountPaidPR,disc_tknPR,BalAmtPR,AvailDiscPR
						,PRICE_EACHPR,ITEM_TOTALPR						
						,TSymbol,PSymbol,FSymbol						
				from	@results
				Order by TSymbol, SupName,Ponum,INVNO,uniqaphead,INVDATE
			End		--&& Reference Date Sort End
		else if (@lcSortOrder = 'Status')
			Begin	--&& status Sort Begin
				select	SupName,Uniqaphead,INVNO,Apstatus,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE,InvAmount
						,CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end as AmountPaid,disc_tkn,BalAmt,AvailDisc,CHOLDSTATUS,ITEM_NO,ITEM_DESC,QTY_EACH
						,PRICE_EACH,ITEM_TOTAL,GL_NBR,uniqsupno
						,InvAmountFC,CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end as AmountPaidFC,disc_tknFC,BalAmtFC,AvailDiscFC
						,PRICE_EACHFC,ITEM_TOTALFC
						,InvAmountPR,CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end as AmountPaidPR,disc_tknPR,BalAmtPR,AvailDiscPR
						,PRICE_EACHPR,ITEM_TOTALPR						
						,TSymbol,PSymbol,FSymbol
				from	@results
				Order by TSymbol, SupName,APSTATUS,INVNO,uniqaphead,ponum,INVDATE
			End		--&& status Sort End
	end  --&&Detailed End


	else if (@lcRptType = 'Summary')
	begin --&&Summary Begin
		-- 01/30/17 VL comment out the TCurrency and FCurrency and added functional currency fields
		IF (@lcSortOrder = 'Invoice Date')
			Begin	--&& Invoice Date Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
						,sum(InvAmountFC) as InvAmountFC,SUM(CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end) as AmountPaidFC,-sum(disc_tknFC)as Disc_tknFC
						,Sum(BalAmtFC) as BalAmtFC,sum(AvailDiscFC) as AvailDiscFC
						,sum(InvAmountPR) as InvAmountPR,SUM(CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end) as AmountPaidPR,-sum(disc_tknPR)as Disc_tknPR
						,Sum(BalAmtPR) as BalAmtPR,sum(AvailDiscPR) as AvailDiscPR
						,TSymbol, PSymbol, FSymbol	
				from	@results 
				group by TSymbol, PSymbol, FSymbol, Supname,InvDate,Invno,uniqaphead,ponum,trans_dt,invdate,Due_date,Apstatus,CHOLDSTATUS,uniqsupno
			end		--&& Invoice Date Sort Begin
		else if (@lcSortOrder = 'Due Date')
			Begin	--&& Due Date Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
						,sum(InvAmountFC) as InvAmountFC,SUM(CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end) as AmountPaidFC,-sum(disc_tknFC)as Disc_tknFC
						,Sum(BalAmtFC) as BalAmtFC,sum(AvailDiscFC) as AvailDiscFC
						,sum(InvAmountPR) as InvAmountPR,SUM(CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end) as AmountPaidPR,-sum(disc_tknPR)as Disc_tknPR
						,Sum(BalAmtPR) as BalAmtPR,sum(AvailDiscPR) as AvailDiscPR
						,TSymbol, PSymbol, FSymbol	
				from	@results 
				group by TSymbol, PSymbol, FSymbol, Supname,Due_Date,Invno,uniqaphead,ponum,trans_dt,invdate,Due_date,Apstatus,CHOLDSTATUS,uniqsupno
			End		--&& Due Date Sort End
		else if (@lcSortOrder = 'Transaction Date')
			Begin	--&& Transaction Date Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
						,sum(InvAmountFC) as InvAmountFC,SUM(CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end) as AmountPaidFC,-sum(disc_tknFC)as Disc_tknFC
						,Sum(BalAmtFC) as BalAmtFC,sum(AvailDiscFC) as AvailDiscFC
						,sum(InvAmountPR) as InvAmountPR,SUM(CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end) as AmountPaidPR,-sum(disc_tknPR)as Disc_tknPR
						,Sum(BalAmtPR) as BalAmtPR,sum(AvailDiscPR) as AvailDiscPR
						,TSymbol, PSymbol, FSymbol	
				from	@results 
				group by TSymbol, PSymbol, FSymbol, Supname,TRANS_DT,Invno,uniqaphead,ponum,trans_dt,invdate,Due_date,Apstatus,CHOLDSTATUS,uniqsupno
			End		--&& Transaction Date Sort End
		else if (@lcSortOrder = 'Reference')
			Begin	--&& Reference Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
						,sum(InvAmountFC) as InvAmountFC,SUM(CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end) as AmountPaidFC,-sum(disc_tknFC)as Disc_tknFC
						,Sum(BalAmtFC) as BalAmtFC,sum(AvailDiscFC) as AvailDiscFC
						,sum(InvAmountPR) as InvAmountPR,SUM(CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end) as AmountPaidPR,-sum(disc_tknPR)as Disc_tknPR
						,Sum(BalAmtPR) as BalAmtPR,sum(AvailDiscPR) as AvailDiscPR

				from	@results 
				group by TSymbol, PSymbol, FSymbol, Supname,ponum,Invno,uniqaphead,trans_dt,invdate,Due_date,Apstatus,CHOLDSTATUS,uniqsupno
			End		--&& Reference Date Sort End
		else if (@lcSortOrder = 'Status')
			Begin	--&& status Sort Begin
				select 	SupName,uniqaphead,INVNO,APSTATUS,PONUM,TRANS_DT,isnull(INVDATE,TRANS_DT) AS INVDATE,isnull(DUE_DATE,TRANS_DT) AS DUE_DATE
						,sum(InvAmount) as InvAmount,SUM(CASE WHEN lprepay = 1 then -(InvAmount-BalAmt) else -appmts end) as AmountPaid,-sum(disc_tkn)as Disc_tkn
						,Sum(BalAmt) as BalAmt,sum(AvailDisc) as AvailDisc,CHOLDSTATUS,uniqsupno
						,sum(InvAmountFC) as InvAmountFC,SUM(CASE WHEN lprepay = 1 then -(InvAmountFC-BalAmtFC) else -appmtsFC end) as AmountPaidFC,-sum(disc_tknFC)as Disc_tknFC
						,Sum(BalAmtFC) as BalAmtFC,sum(AvailDiscFC) as AvailDiscFC
						,sum(InvAmountPR) as InvAmountPR,SUM(CASE WHEN lprepay = 1 then -(InvAmountPR-BalAmtPR) else -appmtsPR end) as AmountPaidPR,-sum(disc_tknPR)as Disc_tknPR
						,Sum(BalAmtPR) as BalAmtPR,sum(AvailDiscPR) as AvailDiscPR
				from	@results 
				group by TSymbol, PSymbol, FSymbol, Supname,Apstatus,Invno,uniqaphead,ponum,trans_dt,invdate,Due_date,CHOLDSTATUS,uniqsupno
			End		--&& status Sort End

 
	end  --&&Summary End



END-- FC installed
/*07/18/2014 DRP:  REMOVED THE MICSSYS FROM BELOW
	SELECT r1.*,micssys.lic_name FROM @RESULTS as r1 cross apply micssys 
--order by 1,6
*/
end