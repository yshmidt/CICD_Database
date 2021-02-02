


-- =============================================
-- Author:		<Debbie and Vicky> 
-- Create date: <02/27/2012>
-- Description:	<compiles details for the Net Sales Summary in Percentage by Customer>
-- Reports:     <used on inv_rep7.rpt>
-- MODIFIED:	11/01/13 DRP:  it was reported that the users was not getting the ending date that they had entered, instead they would have to enter in 11/2 to get all of 11/1 transactions
--							 I modified the date below so that it would pull the results in correctly. 
--			11/08/13 DRP:   Needed to change the parameters from @ldStartDate to @lcDateStart, etc. . . . 
--			12/22/2014 DRP:  added the @userid and the Customer List section below to make sure that only Customers the user is approved to view are available. 
--			01/06/2015 DRP:  Added @customerStatus Filter 
--			02/12/2015 DRP:  needed to add the Rounding to the Percent formula at the end of this procedure to make sure that the percentage total at the end would end up equaling 100.00 instead of 99.99	
--							 This was requested to be put into report form, not just QuickView by a user.
--			01/18/2017	VL:	 Added functional and FC code, also separate FC and non-FC
-- 08/16/17 VL Fixed the InvAmtFC and InvAmtPR didn't show correct values issue
-- 07/16/18 VL changed custname from char(35) to char(50)
-- 02/24/20 VL added Packlistno and COGAmt, request by PTI
-- 04/08/20 VL Changed from using CTE cursor ZIssueCost to table variable to speed up
-- =============================================
CREATE PROCEDURE [dbo].[rptInvoiceNetSalesSum] 

 --declare
 @lcDateStart smalldatetime = null 
 ,@lcDateEnd smalldatetime = null
 ,@customerStatus varchar (20) = 'All'	--01/06/2015 DRP: ADDED
 ,@userId uniqueidentifier= null

as
begin

--declare @lcCustNo as varchar(max) = 'All'
/*CUSTOMER LIST*/	--12/22/2014 DRP:  added to work with the userid filter
DECLARE  @tCustomer as tCustomer
		DECLARE @Customer TABLE (custno char(10))
		-- get list of customers for @userid with access
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userid,null,@customerStatus ;
		--SELECT * FROM @tCustomer	
		

-- 08/16/17 VL added FC and PR totalamt
-- 02/24/20 VL added @lnTotalCOGAmt numeric(20,2)
declare @lnTotalAmt numeric(20,2), @lnTotalAmtFC numeric(20,2), @lnTotalAmtPR numeric(20,2), @lnTotalCOGAmt numeric(20,2), @lnTotalCOGAmtPR numeric(20,2)
-- 04/08/20 VL Changed from using CTE cursor ZIssueCost to table variable to speed up
DECLARE @ZIssueCost TABLE (CogAmt numeric(12,2), Packlistno char(10))

-- 01/18/17 VL separate FC and non FC
IF dbo.fn_IsFCInstalled() = 0
	BEGIN
	-- 07/16/18 VL changed custname from char(35) to char(50)
	-- 02/24/20 VL added Packlistno and COGAmt, request by PTI
	DECLARE @ZInvDetl TABLE (Custno char(10), CustName char(50), InvAmt numeric(20,2), [Percent] numeric(6,2),InvoiceNo char (10), Packlistno char(10), COGAmt numeric(20,2))


	INSERT @ZInvDetl
	-- 02/24/20 VL Added Packlistno and COGAmt
		SELECT DISTINCT Plmain.Custno, customer.Custname, (Invtotal - Freightamt - Tottaxe - tottaxf) AS invamt, 000.00 AS [Percent],INVOICENO, Packlistno, 0.00 AS COGAmt
			   FROM Customer ,plmain 
				WHERE PLMAIN.CUSTNO = CUSTOMER.CUSTNO 
	--11/01/13 DRP:  changed the how the Date range was pulled so that the users would not have to enter in the next day to get the desired results
				--AND INVDATE BETWEEN @ldStartDate AND @ldEndDate
				AND CAST(INVDATE as DATE) BETWEEN @lcDateStart AND @lcDateEnd
				AND PLMAIN.IS_INVPOST = 1
				and 1= case WHEN plmain.custNO IN (SELECT custno FROM @tCUSTOMER) THEN 1 ELSE 0  END	--12/22/2014 DRP:  added to work with the userid filter
				UNION ALL
				(SELECT DISTINCT Cmmain.Custno, customer.Custname,-(CmTotal - Cm_Frt - cm_Frt_tax - tottaxe) AS InvAmt, 000.00 AS [Percent],CMEMONO as invoiceno, '' AS Packlistno, 0.00 AS COGAmt
				FROM Customer , Cmmain 
				WHERE cmmain.CUSTNO = CUSTOMER.CUSTNO 
	--11/01/13 DRP:  changed the how the Date range was pulled so that the users would not have to enter in the next day to get the desired results
				--AND CmDate BETWEEN @ldStartDate AND @ldEndDate
				AND cast(CmDate as DATE) BETWEEN @lcDateStart AND @lcDateEnd
				AND Is_Cmpost = 1
				and 1 = case when Customer.CUSTNO in (select CUSTNO from @tCustomer ) then 1 else 0 end --12/22/2014 DRP:  added to work with the userid filter
				)

	--02/24/20 VL update COGAmt, COGPercent
	-- 04/08/20 VL Changed from using CTE cursor ZIssueCost to table variable to speed up
	--;WITH ZIssueCost AS 
	--(
	--	SELECT ROUND(SUM(Qtyisu*Stdcost),2) AS COGAmt, SUBSTRING(IssuedTo,11,10) AS Packlistno
	--		FROM Invt_isu
	--		WHERE EXISTS(SELECT 1 FROM @ZInvDetl pk WHERE pk.packlistno = SUBSTRING(Issuedto,11,10) AND LEFT(Issuedto,10) = 'REQ PKLST-')
	--		GROUP BY SUBSTRING(Issuedto,11,10)
	--)
	--04/08/20 VL update COGAmt, COGPercent
	INSERT INTO @ZIssueCost 
		SELECT ROUND(SUM(Qtyisu*Stdcost),2) AS COGAmt, SUBSTRING(IssuedTo,11,10) AS Packlistno
			FROM Invt_isu
			WHERE EXISTS(SELECT 1 FROM @ZInvDetl pk WHERE pk.packlistno = SUBSTRING(Issuedto,11,10) AND LEFT(Issuedto,10) = 'REQ PKLST-')
			GROUP BY SUBSTRING(Issuedto,11,10)

	UPDATE @ZInvDetl
		SET COGAmt = ZIssueCost.COGAmt
		FROM @ZIssueCost ZIssueCost
		WHERE [@ZInvDetl].Packlistno = ZIssueCost.Packlistno

	-- Get total invoice amount
	-- 02/24/20 VL added @ln lnTotalCOGAmt
	SELECT @lnTotalAmt = SUM(InvAmt), @lnTotalCOGAmt = SUM(COGAmt) FROM @ZInvDetl

	-- Calculate InvAmt and Percent for each customer
	-- 02/24/20 VL added COGAmt and COGPercent
	SELECT Custno, Custname, SUM(InvAmt) AS InvAmt, round((SUM(InvAmt)/@lnTotalAmt)* 100,3) AS [Percent],	--02/12/2015 DRP:  needed to add the Rounding to the Percent formula
		SUM(COGAmt) AS COGAmt, ROUND((SUM(COGAmt)/@lnTotalCOGAmt)*100,3) AS COGPercent
		FROM @ZInvDetl
		GROUP BY Custno, Custname
		ORDER BY SUM(InvAmt)/@lnTotalAmt DESC
	END
ELSE
	BEGIN
	-- 07/16/18 VL changed custname from char(35) to char(50)
	-- 02/24/20 VL added Packlistno and COGAmt, request by PTI
	DECLARE @ZInvDetlFC TABLE (Custno char(10), CustName char(50), InvAmt numeric(20,2), [Percent] numeric(6,2),InvoiceNo char (10),InvAmtFC numeric(20,2),InvAmtPR numeric(20,2),
								TSymbol char(3), PSymbol char(3), FSymbol char(3), Packlistno char(10), COGAmt numeric(20,2), COGAmtPR numeric(20,2))


	INSERT @ZInvDetlFC
		-- 02/24/20 VL Added Packlistno and COGAmt	
		SELECT DISTINCT Plmain.Custno, customer.Custname, (Invtotal - Freightamt - Tottaxe - tottaxf) AS invamt, 000.00 AS [Percent],INVOICENO,
						-- 08/16/17 VL fixed incorrect InvamtFC and InvAmtPR calculation
						(InvtotalFC - FreightamtFC - TottaxeFC - tottaxfFC) AS invamtFC,
						(InvtotalPR - FreightamtPR - TottaxePR - tottaxfPR) AS invamtPR,
						TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol,
						Packlistno, 0.00 AS COGAmt, 0.00 AS COGAmtPR
			   FROM Customer ,plmain 
					-- 01/18/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq
				WHERE PLMAIN.CUSTNO = CUSTOMER.CUSTNO 
	--11/01/13 DRP:  changed the how the Date range was pulled so that the users would not have to enter in the next day to get the desired results
				--AND INVDATE BETWEEN @ldStartDate AND @ldEndDate
				AND CAST(INVDATE as DATE) BETWEEN @lcDateStart AND @lcDateEnd
				AND PLMAIN.IS_INVPOST = 1
				and 1= case WHEN plmain.custNO IN (SELECT custno FROM @tCUSTOMER) THEN 1 ELSE 0  END	--12/22/2014 DRP:  added to work with the userid filter
				UNION ALL
				(SELECT DISTINCT Cmmain.Custno, customer.Custname,-(CmTotal - Cm_Frt - cm_Frt_tax - tottaxe) AS InvAmt, 000.00 AS [Percent],CMEMONO as invoiceno,
								-(CmTotalFC - Cm_FrtFC - cm_Frt_taxFC - tottaxeFC) AS InvAmtFC,
								-(CmTotalPR - Cm_FrtPR - cm_Frt_taxPR - tottaxePR) AS InvAmtPR,
								TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol,
								'' AS Packlistno, 0.00 AS COGAmt, 0.00 AS COGAmtPR
				FROM Customer , Cmmain 
					-- 01/18/17 VL changed criteria to get 3 currencies
					INNER JOIN Fcused PF ON Cmmain.PrFcused_uniq = PF.Fcused_uniq
					INNER JOIN Fcused FF ON Cmmain.FuncFcused_uniq = FF.Fcused_uniq			
					INNER JOIN Fcused TF ON Cmmain.Fcused_uniq = TF.Fcused_uniq
				WHERE cmmain.CUSTNO = CUSTOMER.CUSTNO 
	--11/01/13 DRP:  changed the how the Date range was pulled so that the users would not have to enter in the next day to get the desired results
				--AND CmDate BETWEEN @ldStartDate AND @ldEndDate
				AND cast(CmDate as DATE) BETWEEN @lcDateStart AND @lcDateEnd
				AND Is_Cmpost = 1
				and 1 = case when Customer.CUSTNO in (select CUSTNO from @tCustomer ) then 1 else 0 end --12/22/2014 DRP:  added to work with the userid filter
				)

	--02/24/20 VL update COGAmt, COGPercent
	-- 04/08/20 VL Changed from using CTE cursor ZIssueCost to table variable to speed up
	--;WITH ZIssueCost AS 
	--(
	--	SELECT ROUND(SUM(Qtyisu*Stdcost),2) AS COGAmt, ROUND(SUM(Qtyisu*StdcostPR),2) AS COGAmtPR, SUBSTRING(IssuedTo,11,10) AS Packlistno
	--		FROM Invt_isu
	--		WHERE EXISTS(SELECT 1 FROM @ZInvDetl pk WHERE pk.packlistno = SUBSTRING(Issuedto,11,10) AND LEFT(Issuedto,10) = 'REQ PKLST-')
	--		GROUP BY SUBSTRING(Issuedto,11,10)
	--)
	--04/08/20 VL update COGAmt, COGPercent
	INSERT INTO @ZIssueCost 
		SELECT ROUND(SUM(Qtyisu*Stdcost),2) AS COGAmt, SUBSTRING(IssuedTo,11,10) AS Packlistno
			FROM Invt_isu
			WHERE EXISTS(SELECT 1 FROM @ZInvDetl pk WHERE pk.packlistno = SUBSTRING(Issuedto,11,10) AND LEFT(Issuedto,10) = 'REQ PKLST-')
			GROUP BY SUBSTRING(Issuedto,11,10)

	UPDATE @ZInvDetl
		SET COGAmt = ZIssueCost.COGAmt
		FROM @ZIssueCost ZIssueCost
		WHERE [@ZInvDetl].Packlistno = ZIssueCost.Packlistno

	-- Get total invoice amount
	-- 08/16/17 VL added FC and PR total
	-- 02/24/20 VL added @ln lnTotalCOGAmt
	SELECT @lnTotalAmt = SUM(InvAmt), @lnTotalAmtFC = SUM(InvAmtFC), @lnTotalAmtPR = SUM(InvAmtPR), @lnTotalCOGAmt = SUM(COGAmt), @lnTotalCOGAmtPR = SUM(COGAmtPR) FROM @ZInvDetlFC
	
	-- Calculate InvAmt and Percent for each customer
	-- 08/16/17 VL added FC and PR percent
	-- 02/24/20 VL added COGAmt and COGPercent
	SELECT Custno, Custname, SUM(InvAmt) AS InvAmt, FSymbol,	--02/12/2015 DRP:  needed to add the Rounding to the Percent formula
			SUM(InvAmtFC) AS InvAmtFC, TSymbol,
			SUM(InvAmtPR) AS InvAmtPR, PSymbol, round((SUM(InvAmt)/@lnTotalAmt)* 100,3) AS [Percent],
			SUM(COGAmt) AS COGAmt, SUM(COGAmtPR) AS COGAmtPR, ROUND((SUM(COGAmt)/@lnTotalCOGAmt)*100,3) AS COGPercent
		FROM @ZInvDetlFC
		GROUP BY Custno, Custname, TSymbol, PSymbol, FSymbol
		ORDER BY SUM(InvAmt)/@lnTotalAmt DESC
	END
end