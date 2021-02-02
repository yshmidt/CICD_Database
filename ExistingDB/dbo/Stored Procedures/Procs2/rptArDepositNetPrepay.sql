
-- =============================================
-- Author:		Debbie
-- Create date: 11/19/15
-- Description:	This Stored Procedure was created for the Net Prepayment Summary
-- Reports:		ar_dep2
-- Modified:	03/16/2016	VL: Added FC code
--				04/08/2016	VL: Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/24/2017	VL:	added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptArDepositNetPrepay]
	@userId uniqueidentifier=null

as
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	


/*RECORD SELECTION SECTION*/

-- 03/16/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
BEGIN
IF @lFCInstalled = 0
	BEGIN	

	SELECT	CUSTNAME,INVNO,REC_DATE,REC_AMOUNT,DEP_CREDIT,REC_AMOUNT-DEP_CREDIT AS NetCredit

	FROM	ARDEP
			INNER JOIN CUSTOMER ON ARDEP.CUSTNO = CUSTOMER.CUSTNO
	where	ARDEP.REC_AMOUNT - ARDEP.DEP_CREDIT <> 0
			and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)
	order by CUSTNAME,REC_DATE

	END
ELSE
-- FC installed
	BEGIN
	-- 01/24/17 VL added functional currency code
	;WITH ZArDep AS (
	SELECT	CUSTNAME,INVNO,REC_DATE,REC_AMOUNT,DEP_CREDIT,REC_AMOUNT-DEP_CREDIT AS NetCredit
			,REC_AMOUNTFC,DEP_CREDITFC,REC_AMOUNTFC-DEP_CREDITFC AS NetCreditFC, Dep_no
			,REC_AMOUNTPR,DEP_CREDITPR,REC_AMOUNTPR-DEP_CREDITPR AS NetCreditPR
	FROM	ARDEP
			INNER JOIN CUSTOMER ON ARDEP.CUSTNO = CUSTOMER.CUSTNO
	where	ARDEP.REC_AMOUNTFC - ARDEP.DEP_CREDITFC <> 0
			and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)
	)
	SELECT ZArDep.*, 
			TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol 
		FROM ZArDep, Deposits
			-- 01/24/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON Deposits.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON Deposits.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON Deposits.Fcused_uniq = TF.Fcused_uniq			
		WHERE ZArDep.Dep_no = Deposits.Dep_no 
		--AND DEPOSITS.Fcused_uniq = Fcused.FcUsed_Uniq
	order by TSymbol, CUSTNAME,REC_DATE

	END
END-- If FC installed
end