


		-- =============================================
		-- Author:		<Debbie and Vicky> 
		-- Create date: <02/28/2012>
		-- Description:	<compiles details for the Gross Sales Summary in Percentage by Customer>
		-- Reports:     <used on inv_rep8.rpt>
		-- Modified:	10/04/2013 DRP:  Needed to change the parameters from @ldStartDate to @lcDateStart, etc. . . . 
		--				11/05/2013 DRP:  it was reported that the users was not getting the ending date that they had entered, instead they would have to enter in 11/2 to get all of 11/1 transactions
		--							     I modified the date below so that it would pull the results in correctly. 
		--				01/18/2017	VL:	 Added functional and FC code, also separate FC and non-FC
-- 07/16/18 VL changed custname from char(35) to char(50)
		-- =============================================
		CREATE PROCEDURE [dbo].[rptInvoiceGrossSalesSum] 

		--10/04/2013 DRP:   @ldStartDate smalldatetime, @ldEndDate smalldatetime
			@lcDateStart as smalldatetime = null
			, @lcDateEnd as smalldatetime = null

		 , @userId uniqueidentifier=null 
as
		begin
		declare @lnTotalAmt numeric(20,2)
-- 01/18/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
		DECLARE @ZInvDetl TABLE (Custno char(10), CustName char(50), InvAmt numeric(20,2), [Percent] numeric(6,2),InvoiceNo char (10))


		INSERT @ZInvDetl
			SELECT DISTINCT Plmain.Custno, customer.Custname, (Invtotal - Freightamt - Tottaxe - tottaxf) AS invamt, 000.00 AS [Percent],INVOICENO
				   FROM Customer ,plmain 
					WHERE PLMAIN.CUSTNO = CUSTOMER.CUSTNO 
--11/05/13 DRP:  changed the how the Date range was pulled so that the users would not have to enter in the next day to get the desired results
					--AND INVDATE BETWEEN @lcDateStart AND @lcDateEnd
					AND CAST(INVDATE as DATE) BETWEEN @lcDateStart AND @lcDateEnd
					AND PLMAIN.IS_INVPOST = 1


		-- Get total invoice amount
		SELECT @lnTotalAmt = SUM(InvAmt) FROM @ZInvDetl

		-- Calculate InvAmt and Percent for each customer
		SELECT Custno, Custname, SUM(InvAmt) AS InvAmt, (SUM(InvAmt)/@lnTotalAmt)* 100 AS [Percent]
			FROM @ZInvDetl
			GROUP BY Custno, Custname
			ORDER BY SUM(InvAmt)/@lnTotalAmt DESC
	END
ELSE
	BEGIN
		-- 01/18/17 VL added FC and functional currency code
		-- 07/16/18 VL changed custname from char(35) to char(50)
		DECLARE @ZInvDetlFC TABLE (Custno char(10), CustName char(50), InvAmt numeric(20,2), [Percent] numeric(6,2),InvoiceNo char (10), InvAmtFC numeric(20,2), InvAmtPR numeric(20,2),
				TSymbol char(3), PSymbol char(3), FSymbol char(3))


		INSERT @ZInvDetlFC
			SELECT DISTINCT Plmain.Custno, customer.Custname, (Invtotal - Freightamt - Tottaxe - tottaxf) AS invamt, 000.00 AS [Percent],INVOICENO,
							(InvtotalFC - FreightamtFC - TottaxeFC - tottaxfFC) AS invamtFC, 
							(InvtotalPR - FreightamtPR - TottaxePR - tottaxfPR) AS invamtPR, 
							TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
				   FROM Customer ,plmain 
					-- 01/18/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq
					WHERE PLMAIN.CUSTNO = CUSTOMER.CUSTNO 
--11/05/13 DRP:  changed the how the Date range was pulled so that the users would not have to enter in the next day to get the desired results
					--AND INVDATE BETWEEN @lcDateStart AND @lcDateEnd
					AND CAST(INVDATE as DATE) BETWEEN @lcDateStart AND @lcDateEnd
					AND PLMAIN.IS_INVPOST = 1


		-- Get total invoice amount
		SELECT @lnTotalAmt = SUM(InvAmt) FROM @ZInvDetlFC

		-- Calculate InvAmt and Percent for each customer
		-- 01/18/17 VL added FC and functional currency code
		SELECT Custno, Custname, SUM(InvAmt) AS InvAmt, (SUM(InvAmt)/@lnTotalAmt)* 100 AS [Percent],
				SUM(InvAmtFC) AS InvAmtFC, SUM(InvAmtPR) AS InvAmtPR, TSymbol, PSymbol, FSymbol
			FROM @ZInvDetlFC
			GROUP BY Custno, Custname,TSymbol, PSymbol, FSymbol
			ORDER BY SUM(InvAmt)/@lnTotalAmt DESC
	END
end