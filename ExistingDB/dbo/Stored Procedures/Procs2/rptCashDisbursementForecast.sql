-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/29/2015
-- Description: Cash Disbursement Forecast (check module CKREP3 in VFP)
-- =============================================
CREATE PROCEDURE rptCashDisbursementForecast
	-- Add the parameters for the stored procedure here
	@lcDateStart as smalldatetime= null,
	@lcDateEnd as smalldatetime = null,
	@supplierStatus varchar(20) = 'All',
	@userid as uniqueidentifier=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		-- make sure date has no time part
	SELECT @lcDateStart=CASE WHEN @lcDateStart is null then @lcDateStart else DATEADD(day,0,datediff(day,0,@lcDateStart))  END,
				@lcDateEnd=CASE WHEN @lcDateEnd is null then @lcDateEnd else DATEADD(day,0,datediff(day,0,@lcDateEnd))  END

		DECLARE  @tSupplier tSupplier ;
	-- get list of Suppliers for @userid with access
	INSERT INTO @tSupplier EXEC aspmnxSP_GetSuppliers4user  @userid, NULL, @supplierStatus  ;
	--select * from @tSupplier where uniqsupno='_1V50INBS5'
	SELECT S.SupName, Due_Date, InvNo, InvDate, InvAmount, InvAmount - (ApPmts + apmaster.DISC_TKN) AS InvoiceBalAmt, UniqApHead ,
		isnull(b.sumaprpay,cast(0.00 as numeric(12,2))) as ScheduledAmount, b.FirstSchdDate as EarliestScheduledDate
		FROM ApMaster INNER JOIN  @tSupplier S  ON S.UniqSupNo = ApMaster.UniqSupNo
			OUTER APPLY (select distinct Fk_UniqApHead, sum(AprPay) OVER (partition by fk_uniqaphead) as sumaprpay,
					MIN(ApBatch.Batch_Date) OVER (partition by fk_uniqaphead) as FirstSchdDate
						FROM ApBatDet INNER JOIN  ApBatch ON ApBatDet.BatchUniq = ApBatch.BatchUniq
							WHERE APBATCH.IS_CLOSED = 0 and FK_UNIQAPHEAD=apmaster.UNIQAPHEAD) B
	WHERE  InvAmount - (ApPmts + apmaster.DISC_TKN)<>0
		AND ApStatus <> 'Deleted' 
		and (
		(@lcDateStart is null and @lcDateEnd is null) 
		or (@lcDateStart is not null and @lcDateEnd is null and apmaster.DUE_DATE>=@lcDateStart )
		or (@lcDateStart is null and  @lcDateEnd is not null and apmaster.DUE_DATE<=@lcDateEnd )
		or (@lcDateStart is not null and  @lcDateEnd is not null and apmaster.DUE_DATE>=@lcDateStart and apmaster.DUE_DATE<=@lcDateEnd))
	ORDER BY Due_Date, SupName, InvNo
END