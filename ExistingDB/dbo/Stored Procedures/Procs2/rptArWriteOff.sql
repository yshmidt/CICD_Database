
-- =============================================
-- Author:			Debbie
-- Create date:		11/25/2013
-- Description:		Created for the AR Writeoff report
-- Reports Using:   ar_rep6 
-- Modifications:	11/26/2013 DRP:  Yelena brought to my attention that I need to make sure that I include the @lcUserId for WebManex Procedures. 
--									 Then had to change the comma seperator to work with the aspmnxSP_GetCustomers4User 
--					01/23/2014 DRP:  we found that if the user left All for the cUSTOMER that it was bringing forward all customers regardless if the user was approved for the Userid or not. 
--					01/06/2015 DRP:  Added @customerStatus Filter 
--					01/24/2017 VL:	 Separate FC and non FC, also added functional currency fields and symbols
-- =============================================
CREATE procedure [dbo].[rptArWriteOff]
	 @lcDateStart smalldatetime = null
		,@lcDateEnd smalldatetime = null
		,@lcCustNo varchar(max) = 'All'
		,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
		,@UserId uniqueidentifier = null

as 
Begin

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @tCustomers tCustomer ;
	DECLARE @tCustno tCustno ;
	-- get list of customers for @userid with access
	-- even if @lcCustomer is not empty we cannot assume that the user has rights to those customers. They might just know the codes of the customers that they have no rights to
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus;
	
	
--01/23/2014 DRP:  NEEDED TO REPLACE HOW THE @tCustNo was popluated to work properly with the userid and All	
	IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'
		insert into @tCustno select * from dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',') where CAST (id as CHAR(10)) in (select Custno from @tCustomers)
	ELSE
		IF  @lcCustNo='All'	
	BEGIN
		INSERT INTO @tCustno SELECT Custno FROM @tCustomers
	END		 
	
--01/23/2014 DRP:  	Removed the below
	--INSERT INTO @tCustno SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustno,',')
	--	WHERE cast(ID as char(10)) IN (SELECT Custno from @tCustomers)

-- 01/24/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN		
	select	customer.custname,ACCTSREC.INVNO,ACCTSREC.INVDATE,ACCTSREC.INVTOTAL,(acctsrec.INVTOTAL - ar_wo.WO_AMT) as ColAmt,ar_wo.WO_AMT,ar_wo.WODATE, ar_wo.WO_REASON
	from	ACCTSREC,AR_WO,CUSTOMER
	where	ACCTSREC.UNIQUEAR = ar_wo.UniqueAR
			and ACCTSREC.CUSTNO = customer.CUSTNO
			and cast(ar_wo.WODATE as Date) between  @lcDateStart AND @lcDateEnd
			and 1 = case when Customer.CustNo IN (select Custno from @tCustno ) then 1 ELSE 0 END
	--01/23/2014 DRP:	Removed the below and replaced it with the above	
	--and 1= CASE WHEN @lcCustNo = 'All' then 1 WHEN  Customer.CustNo IN (select Custno from @tCustno ) then 1 ELSE 0 END

	order by CUSTNAME,INVNO
	END
ELSE
	BEGIN
	select	customer.custname,ACCTSREC.INVNO,ACCTSREC.INVDATE,ACCTSREC.INVTOTAL,(acctsrec.INVTOTAL - ar_wo.WO_AMT) as ColAmt,ar_wo.WO_AMT,ar_wo.WODATE, ar_wo.WO_REASON,
			ACCTSREC.INVTOTAL,(acctsrec.INVTOTAL - ar_wo.WO_AMT) as ColAmt,ar_wo.WO_AMT,
			ACCTSREC.INVTOTAL,(acctsrec.INVTOTAL - ar_wo.WO_AMT) as ColAmt,ar_wo.WO_AMT,
			TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	ACCTSREC
			-- 01/24/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON ACCTSREC.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON ACCTSREC.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON ACCTSREC.Fcused_uniq = TF.Fcused_uniq
			,AR_WO,CUSTOMER
	where	ACCTSREC.UNIQUEAR = ar_wo.UniqueAR
			and ACCTSREC.CUSTNO = customer.CUSTNO
			and cast(ar_wo.WODATE as Date) between  @lcDateStart AND @lcDateEnd
			and 1 = case when Customer.CustNo IN (select Custno from @tCustno ) then 1 ELSE 0 END
	--01/23/2014 DRP:	Removed the below and replaced it with the above	
	--and 1= CASE WHEN @lcCustNo = 'All' then 1 WHEN  Customer.CustNo IN (select Custno from @tCustno ) then 1 ELSE 0 END

	order by CUSTNAME,INVNO

	END



end