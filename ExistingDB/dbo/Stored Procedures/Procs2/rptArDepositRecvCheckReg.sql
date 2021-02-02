
-- =============================================
-- Author:		Debbie
-- Create date: 11/19/15
-- Description:	This Stored Procedure was created for the Received Check Register
-- Reports:		ar_rep16
-- Modified:	03/17/16 VL:	Added FC code
--				04/08/16 VL:	Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				01/13/17 VL:	Added functional currency fields
-- =============================================
CREATE PROCEDURE [dbo].[rptArDepositRecvCheckReg]
--declare
	@lcDateStart smalldatetime = NULL
	,@lcDateEnd smalldatetime = NULL
	,@userId uniqueidentifier = NULL

as 
begin

/*CUSTOMER LIST*/		
	DECLARE  @tCustomer as tCustomer
		--DECLARE @Customer TABLE (custno char(10))`--10/28/15 DRP:  we declared this but never really used it. 
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,'All' ;
		--SELECT * FROM @tCustomer	

-- 03/17/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
BEGIN
IF @lFCInstalled = 0
	BEGIN
	select	REC_DATE,REC_ADVICE,ARCREDIT.INVNO,CUSTNAME ,
			case when left(arcredit.rec_type,6) = 'PrePay' then CAST(0.00 AS NUMERIC(12,2)) else acctsrec.invtotal end as INVAMOUNT
			,REC_AMOUNT,lprepay
	from	ARCREDIT
			LEFT OUTER JOIN ACCTSREC ON ARCREDIT.CUSTNO = ACCTSREC.CUSTNO AND ARCREDIT.INVNO = ACCTSREC.INVNO
			INNER JOIN CUSTOMER ON ARCREDIT.CUSTNO = CUSTOMER.CUSTNO
	WHERE	ARCREDIT.REC_TYPE <> 'Credit Memo'
			and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)
			and DATEDIFF(day, @lcDateStart,arcredit.rec_date) >=0 AND DATEDIFF(day,arcredit.rec_date,@lcDateEnd )>=0
	order by rec_date,CUSTNAME,REC_ADVICE
	END
ELSE
-- FC installed
	BEGIN
	select	REC_DATE,REC_ADVICE,ARCREDIT.INVNO,CUSTNAME ,
			case when left(arcredit.rec_type,6) = 'PrePay' then CAST(0.00 AS NUMERIC(12,2)) else acctsrec.invtotal end as INVAMOUNT
			,REC_AMOUNT,lprepay
			,case when left(arcredit.rec_type,6) = 'PrePay' then CAST(0.00 AS NUMERIC(12,2)) else acctsrec.invtotalFC end as INVAMOUNTFC
			,REC_AMOUNTFC
			-- 01/13/17 VL added functional currency fields
			,case when left(arcredit.rec_type,6) = 'PrePay' then CAST(0.00 AS NUMERIC(12,2)) else acctsrec.invtotalPR end as INVAMOUNTPR
			,REC_AMOUNTPR
			--, Fcused.Symbol AS Currency
			,TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from ARCREDIT 
			-- 01/13/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON ARCREDIT.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON ARCREDIT.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON ARCREDIT.Fcused_uniq = TF.Fcused_uniq								
			LEFT OUTER JOIN ACCTSREC ON ARCREDIT.CUSTNO = ACCTSREC.CUSTNO AND ARCREDIT.INVNO = ACCTSREC.INVNO
			INNER JOIN CUSTOMER ON ARCREDIT.CUSTNO = CUSTOMER.CUSTNO
	WHERE	ARCREDIT.REC_TYPE <> 'Credit Memo'
			and exists (select 1 from @TCustomer t inner join customer c on t.custno=c.custno where c.custno=CUSTOMER.custno)
			and DATEDIFF(day, @lcDateStart,arcredit.rec_date) >=0 AND DATEDIFF(day,arcredit.rec_date,@lcDateEnd )>=0
	order by TSymbol, rec_date,CUSTNAME,REC_ADVICE
	END
END--IF FC installed

end
	