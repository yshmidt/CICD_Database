
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/04/2014
-- Description:	Procedure for the AP bacth detail report
-- In VFP (report CKREP1) 
--- List of parameters
-- 1. @cBatchUniq -  default to 'All' and will take a comma separated value for the batchuniq keys. 
-- 2. @cBk_Uniq  - default to 'All' and will accept comma separated values . 
-- 3. @sortBy - "Sort Within Supplier By"  Possible options "Invoice No" or "Due Date",  default to 'Invoice No' 
-- 4. @UserId - to make sure that the user can view only report for the suppliers that they have authority to view
-- Modified:	03/11/14 YS added Bank name
--			06/12/2014 DRP:  needed to change the @Bk_Uniq to @@lcbk_Uniq, @sortby to @lcSort
--			10/14/2014 DRP:  changed @bk_Uniq to be @lcBank and  Added the Batch_Date to the Sort Order  at this point in time we do not have the Date filter that we had in VFP.  We will see if users request it. 
--			12/12/14 DS Added supplier status filter
--			03/18/16 VL:	 Added FC code
--			04/08/16 VL:	 Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--			04/20/16 DRP:  needed to change the @lcSort from 'Invoice No' to 'Invoice Number' in order to work with a Sort parameter we already have within the WebManex params
--			02/03/17 VL:	 Added functional currency fields
--08/16/17 YS wrong columns duplicated FC amount instead of PR amount. Rearange currency symbol to make it easy for user to see
-- 11/20/17 VL added ROW_NUMBER() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum and use it in Stimulsoft report, when using Supname to sort, Stimulsoft has different way to sort (Trimble and Tri-tech), so created this RowNum field and use it to sort in report
-- 07/25/19 VL changed from ROW_NUMBER() to DENSE_RANK() for supname, so same supplier will have same number, so it won't affect the sort order of the rest columns
-- =============================================
CREATE PROCEDURE [dbo].[rptAPBatchDetails]
	-- Add the parameters for the stored procedure here
--declare	
@lcBatchUniq varchar(max) = 'All'
	,@lcbank varchar(max)='All'				/*06/12/2014 DRP: @cBk_Uniq varchar(MAX) = 'All'*/
	,@lcSort varchar(30) = 'Invoice No'			/*06/12/2014 DRP: @sortBy varchar(30) = 'Invoice No',*/
	,@userId uniqueidentifier = null
	--,@supplierStatus varchar(20) = 'All'	--04/20/16 DRP:  removed and just populated 'All' below in the Supplier Section
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   
    DECLARE @Batches TABLE (BatchUniq char(10))
    Declare @Banks TABLE (bk_uniq char(10))
    -- make sure this user allowed to view supplier information and show only suppliers that the user is allowed to see
    DECLARE  @tSupplier tSupplier
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, 'All'  ;

    
    IF (@lcBatchUniq is not NULL and @lcBatchUniq<>' ' and @lcBatchUniq<>'All')
		INSERT INTO  @Batches select * from dbo.[fn_simpleVarcharlistToTable](@lcBatchUniq,',')
		
	IF (@lcbank is not NULL and @lcbank<>' ' and @lcbank<>'All')
		INSERT INTO @Banks select * from dbo.[fn_simpleVarcharlistToTable](@lcbank,',')


	-- 03/18/16 VL added for FC installed or not
	DECLARE @lFCInstalled bit
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	BEGIN
	IF @lFCInstalled = 0
		BEGIN
	   
		SELECT	ApBatch.Batch_Date,Banks.BANK,ApBatch.BatchDescr,Supinfo.supname, Apmaster.invno,Apmaster.due_date, Apmaster.invamount
				,Apbatdet.disc_amt, Apbatdet.disc_tkn, Apbatdet.aprpay,Apmaster.ponum,ApBatch.Bk_Uniq ,APBATCH.BATCHUNIQ,
				-- 11/20/17 VL added ROW_NUMBER() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum and use it in Stimulsoft report, when using Supname to sort, Stimulsoft has different way to sort (Trimble and Tri-tech), so created this RowNum field and use it to sort in report
				-- 07/25/19 VL changed from ROW_NUMBER() to DENSE_RANK() for supname, so same supplier will have same number, so it won't affect the sort order of the rest columns
				DENSE_RANK() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum4Supname
		FROM	apbatch 
				INNER JOIN apbatdet ON ApBatch.BatchUniq = ApBatDet.BatchUniq
				INNER JOIN BANKS on apbatch.BK_UNIQ =Banks.BK_UNIQ 
				INNER JOIN apmaster ON Apbatdet.fk_uniqaphead = Apmaster.uniqaphead
				INNER JOIN supinfo 	ON  Apmaster.uniqsupno = Supinfo.uniqsupno 
				INNER JOIN @tSupplier tS ON Apmaster.UNIQSUPNO = tS.uniqsupno 
		WHERE	Is_Closed = 0
				-- banks
				AND 1=CASE WHEN @lcbank='All' THEN 1
						WHEN @lcbank is NULL OR @lcbank=' ' THEN 0
						WHEN EXISTS (SELECT 1 from @Banks B where b.bk_uniq =apbatch.BK_UNIQ ) THEN 1
						ELSE 0 END
				-- batch
				AND 1=CASE WHEN @lcBatchUniq='All' THEN 1
					WHEN @lcBatchUniq IS Null OR @lcBatchUniq=' ' THEN 0
					when EXISTS (select 1 from @Batches aB where ab.BatchUniq=APBATCH.BATCHUNIQ ) THEN 1
					ELSE 0 END 	
		ORDER BY 
		--04/20/16 DRP:  Changed it from 'Invoice No' to 'Invoice Number'
			case @lcSort when 'Invoice Number' then BATCH_DATE end,	--10/14/2014 DRP:  Added the Batch_Date to the Sort Order
					-- 11/20/17 VL added ROW_NUMBER() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum and use it in Stimulsoft report, when using Supname to sort, Stimulsoft has different way to sort (Trimble and Tri-tech), so created this RowNum field and use it to sort in report
					-- 07/25/19 VL changed from ROW_NUMBER() to DENSE_RANK() for supname, so same supplier will have same number, so it won't affect the sort order of the rest columns
					CASE @lcSort WHEN 'Invoice Number' THEN DENSE_RANK() OVER (ORDER BY Supinfo.Supname ASC) END,
					CASE  @lcSort WHEN 'Invoice Number' THEN [Invno] END, 
					CASE @lcSort WHEN 'Invoice Number'  THEN [Due_date] END,
		   case @lcSort when 'Due Date' then BATCH_DATE end,	--10/14/2014 DRP:  Added the Batch_Date to the Sort Order
					-- 11/20/17 VL added ROW_NUMBER() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum and use it in Stimulsoft report, when using Supname to sort, Stimulsoft has different way to sort (Trimble and Tri-tech), so created this RowNum field and use it to sort in report
					-- 07/25/19 VL changed from ROW_NUMBER() to DENSE_RANK() for supname, so same supplier will have same number, so it won't affect the sort order of the rest columns
					CASE @lcSort WHEN 'Due Date' THEN DENSE_RANK() OVER (ORDER BY Supinfo.Supname ASC) END,
					CASE @lcSort WHEN 'Due Date' THEN [DUE_DATE] END,
					CASE @lcSort WHEN 'Due date' THEN  [invno] END	
		END
	ELSE
	--FC installed
		BEGIN
		SELECT	ApBatch.Batch_Date,Banks.BANK,ApBatch.BatchDescr,Supinfo.supname, Apmaster.invno,Apmaster.due_date, FF.Symbol AS FSymbol ,
				Apmaster.invamount
				,Apbatdet.disc_amt, Apbatdet.disc_tkn, Apbatdet.aprpay,Apmaster.ponum,ApBatch.Bk_Uniq ,APBATCH.BATCHUNIQ
				,TF.Symbol AS TSymbol,Apmaster.invamountFC,Apbatdet.disc_amtFC, Apbatdet.disc_tknFC, Apbatdet.aprpayFC
				-- 02/03/17 VL comment out Currency field and added functional currency fields
				--, Fcused.Symbol AS Currency
				--08/16/17 YS wrong columns duplicated FC amount ionstead of PR amount
				, PF.Symbol AS PSymbol,Apmaster.invamountPr,Apbatdet.disc_amtPr, Apbatdet.disc_tknPr, Apbatdet.aprpayPr,
				-- 11/20/17 VL added ROW_NUMBER() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum and use it in Stimulsoft report, when using Supname to sort, Stimulsoft has different way to sort (Trimble and Tri-tech), so created this RowNum field and use it to sort in report
				-- 07/25/19 VL changed from ROW_NUMBER() to DENSE_RANK() for supname, so same supplier will have same number, so it won't affect the sort order of the rest columns
				DENSE_RANK() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum4Supname
		FROM	apbatch
				-- 02/03/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON apbatch.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON apbatch.FuncFcused_uniq = FF.Fcused_uniq			
				INNER JOIN Fcused TF ON apbatch.Fcused_uniq = TF.Fcused_uniq			
				INNER JOIN apbatdet ON ApBatch.BatchUniq = ApBatDet.BatchUniq
				INNER JOIN BANKS on apbatch.BK_UNIQ =Banks.BK_UNIQ 
				INNER JOIN apmaster ON Apbatdet.fk_uniqaphead = Apmaster.uniqaphead
				INNER JOIN supinfo 	ON  Apmaster.uniqsupno = Supinfo.uniqsupno 
				INNER JOIN @tSupplier tS ON Apmaster.UNIQSUPNO = tS.uniqsupno 
		WHERE	Is_Closed = 0
				-- banks
				AND 1=CASE WHEN @lcbank='All' THEN 1
						WHEN @lcbank is NULL OR @lcbank=' ' THEN 0
						WHEN EXISTS (SELECT 1 from @Banks B where b.bk_uniq =apbatch.BK_UNIQ ) THEN 1
						ELSE 0 END
				-- batch
				AND 1=CASE WHEN @lcBatchUniq='All' THEN 1
					WHEN @lcBatchUniq IS Null OR @lcBatchUniq=' ' THEN 0
					when EXISTS (select 1 from @Batches aB where ab.BatchUniq=APBATCH.BATCHUNIQ ) THEN 1
					ELSE 0 END 	
		ORDER BY 
		--04/20/16 DRP:  Changed it from 'Invoice No' to 'Invoice Number'
			-- 02/03/17 VL changed from currency to TSymbol
			TSymbol,
			case @lcSort when 'Invoice Number' then BATCH_DATE end,	--10/14/2014 DRP:  Added the Batch_Date to the Sort Order
					-- 11/20/17 VL added ROW_NUMBER() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum and use it in Stimulsoft report, when using Supname to sort, Stimulsoft has different way to sort (Trimble and Tri-tech), so created this RowNum field and use it to sort in report
					-- 07/25/19 VL changed from ROW_NUMBER() to DENSE_RANK() for supname, so same supplier will have same number, so it won't affect the sort order of the rest columns
					CASE @lcSort WHEN 'Invoice Number' THEN DENSE_RANK() OVER (ORDER BY Supinfo.Supname ASC) END,
					CASE  @lcSort WHEN 'Invoice Number' THEN [Invno] END, 
					CASE @lcSort WHEN 'Invoice Number'  THEN [Due_date] END,
		   case @lcSort when 'Due Date' then BATCH_DATE end,	--10/14/2014 DRP:  Added the Batch_Date to the Sort Order
					-- 11/20/17 VL added ROW_NUMBER() OVER (ORDER BY Supinfo.Supname ASC) AS RowNum and use it in Stimulsoft report, when using Supname to sort, Stimulsoft has different way to sort (Trimble and Tri-tech), so created this RowNum field and use it to sort in report
					-- 07/25/19 VL changed from ROW_NUMBER() to DENSE_RANK() for supname, so same supplier will have same number, so it won't affect the sort order of the rest columns
					CASE @lcSort WHEN 'Due Date' THEN DENSE_RANK() OVER (ORDER BY Supinfo.Supname ASC) END,
					CASE @lcSort WHEN 'Due Date' THEN [DUE_DATE] END,
					CASE @lcSort WHEN 'Due date' THEN  [invno] END	
		END
	END--End of IF FC installed

END