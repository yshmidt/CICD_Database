CREATE PROCEDURE [dbo].[Apmaster4GivenDateRangeView] 
	-- Add the parameters for the stored procedure here
	@ldBeginDate char(10), @ldEndDate char(10), @lcApSatus char(15)='' ,@cHoldStatus char(10)=''
AS
-- 09/29/16 VL added code for FC to show more fields
-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--12/19/12 YS added cHoldStatus parameter
    -- Insert statements for procedure here
	-- 09/29/16 VL Added to get FC fields or not based on FC is installed or not
	DECLARE @lFCInstalled bit, @HCSymbol char(3) = ''
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
	-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
	SELECT @HCSymbol = Symbol FROM Fcused WHERE Fcused.Fcused_uniq = dbo.fn_GetFunctionalCurrency()

	IF @lFCInstalled = 0
		BEGIN
		IF (@lcApSatus='') 
			select Distinct Supname,InvAmount,Ponum,InvNo,ApStatus,InvDate,UniqApHead,Due_Date 
				From Apmaster,Supinfo
			where supinfo.uniqsupno=apmaster.uniqsupno 
			and lPrepay <> 1
			and CHOLDSTATUS=CASE WHEN @cHoldStatus ='' then CHOLDSTATUS else @cHoldStatus end
			and CAST(Due_date as date) between CAST(@ldBeginDate as date) and cast(@ldEndDate as date) 
		ELSE
			select Distinct Supname,InvAmount,Ponum,InvNo, ApStatus,InvDate,UniqApHead,Due_Date 
				From Apmaster,Supinfo
			where supinfo.uniqsupno=apmaster.uniqsupno 
			and lPrepay <> 1
			and CHOLDSTATUS=CASE WHEN @cHoldStatus ='' then CHOLDSTATUS else @cHoldStatus end
			and CAST(Due_date as Date) between CAST(@ldBeginDate as date) and cast(@ldEndDate as date) and ApStatus=@lcApSatus
		END
	ELSE
		BEGIN
		IF (@lcApSatus='') 
			select Distinct Supname,Trans_dt,InvNo,Ponum,InvAmountFC, Fcused.Symbol AS FCSymbol,InvAmount,@HCSymbol AS HCSymbol,InvDate, ApStatus,UniqApHead,Due_Date 
				From Apmaster,Supinfo, Fcused
			where supinfo.uniqsupno=apmaster.uniqsupno 
			AND Apmaster.Fcused_uniq = Fcused.Fcused_uniq
			and lPrepay <> 1
			and CHOLDSTATUS=CASE WHEN @cHoldStatus ='' then CHOLDSTATUS else @cHoldStatus end
			and CAST(Due_date as date) between CAST(@ldBeginDate as date) and cast(@ldEndDate as date) 
		ELSE
			select Distinct Supname,Trans_dt,InvNo,Ponum,InvAmountFC, Fcused.Symbol AS FCSymbol,InvAmount,@HCSymbol AS HCSymbol,InvDate, ApStatus,UniqApHead,Due_Date 
				From Apmaster,Supinfo, Fcused
			where supinfo.uniqsupno=apmaster.uniqsupno 
			AND Apmaster.Fcused_uniq = Fcused.Fcused_uniq
			and lPrepay <> 1
			and CHOLDSTATUS=CASE WHEN @cHoldStatus ='' then CHOLDSTATUS else @cHoldStatus end
			and CAST(Due_date as Date) between CAST(@ldBeginDate as date) and cast(@ldEndDate as date) and ApStatus=@lcApSatus
		END
END