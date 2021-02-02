
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/11/2014
-- Description:	Procedure for the AP bacth summary report
-- In VFP (report CKREP2) 
--- List of parameters
-- 1. @lcBatchUniq -  default to 'All' and will take a comma separated value for the batchuniq keys. 
-- 2. @lcbank  - default to 'All' and will accept comma separated values . 
-- 4. @UserId - to make sure that the user can view only report for the suppliers that they have authority to view
--- Modified:
--	03/21/16	VL:	Added FC code
--  04/08/16	VL: Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--  02/07/17	VL:	Added functional currency code
-- 08/16/17 VL  Rearrange currency labels for currencies
-- 08/17/17 VL  Re-arrange fields again in FC section
-- =============================================
CREATE PROCEDURE [dbo].[rptAPBatchSummary]
	-- Add the parameters for the stored procedure here
	@lcBatchUniq varchar(max) = 'All',
	@lcbank varchar(max)='All'	,
	@supplierStatus varchar(20) = 'All',
	@userId uniqueidentifier =NULL
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
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user @userid, NULL, @supplierStatus  ;
    
    IF (@lcBatchUniq is not NULL and @lcBatchUniq<>' ' and @lcBatchUniq<>'All')
		INSERT INTO  @Batches select * from dbo.[fn_simpleVarcharlistToTable](@lcBatchUniq,',')
		
		
	IF (@lcbank is not NULL and @lcbank<>' ' and @lcbank<>'All')
		INSERT INTO @Banks select * from dbo.[fn_simpleVarcharlistToTable](@lcbank,',')
   
	-- 03/21/16 VL added for FC installed or not
	DECLARE @lFCInstalled bit
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

	BEGIN
	IF @lFCInstalled = 0
		BEGIN
	   
		SELECT  ApBatch.Batch_Date, Banks.Bank, ApBatch.BatchDescr,Batch_Tot,ApBatch.Bk_Uniq 
		FROM  apbatch INNER JOIN BANKS on Apbatch.BK_UNIQ =Banks.BK_UNIQ 
		WHERE apbatch.Is_Closed = 0
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
			AND EXISTS (SELECT 1 from Apbatdet INNER JOIN apmaster ON Apbatdet.fk_uniqaphead = Apmaster.uniqaphead
								INNER JOIN supinfo 	ON  Apmaster.uniqsupno = Supinfo.uniqsupno 
								INNER JOIN @tSupplier tS ON Apmaster.UNIQSUPNO = tS.uniqsupno 
								where apbatdet.BATCHUNIQ=apbatch.BATCHUNIQ)
		ORDER BY  ApBatch.Batch_Date
	
		END
	ELSE
	-- FC installed
		BEGIN
		-- 02/07/17	VL	Added functional currency code, commen tout Currency --Fcused.Symbol AS Currency
		-- 08/16/17 VL rearrange currency labels
		-- 08/17/17 VL moved Bk_uniq to the end of the list
		SELECT  ApBatch.Batch_Date, Banks.Bank, ApBatch.BatchDescr,Batch_Tot,FF.Symbol AS FSymbol,Batch_TotFC,
				TF.Symbol AS TSymbol, Batch_TotPR, PF.Symbol AS PSymbol,ApBatch.Bk_Uniq
		FROM  apbatch 
				-- 02/07/17 VL changed criteria to get 3 currencies
				INNER JOIN Fcused PF ON apbatch.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON apbatch.FuncFcused_uniq = FF.Fcused_uniq			
				INNER JOIN Fcused TF ON apbatch.Fcused_uniq = TF.Fcused_uniq			
				INNER JOIN BANKS on Apbatch.BK_UNIQ =Banks.BK_UNIQ 
		WHERE apbatch.Is_Closed = 0
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
			AND EXISTS (SELECT 1 from Apbatdet INNER JOIN apmaster ON Apbatdet.fk_uniqaphead = Apmaster.uniqaphead
								INNER JOIN supinfo 	ON  Apmaster.uniqsupno = Supinfo.uniqsupno 
								INNER JOIN @tSupplier tS ON Apmaster.UNIQSUPNO = tS.uniqsupno 
								where apbatdet.BATCHUNIQ=apbatch.BATCHUNIQ)
		ORDER BY TSymbol, ApBatch.Batch_Date

		END
	END--IF FC installed

END