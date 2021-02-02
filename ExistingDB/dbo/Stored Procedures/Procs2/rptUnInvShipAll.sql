
-- =============================================
-- Author:		Debbie
-- Create date: 02/24/2012
-- Description:	This Stored Procedure was created for the Un-Invoiced Shipment Summary ALL report
-- Reports Using Stored Procedure:  inv_rep5.rpt
-- Modified:	 01/15/2014 DRP:  added the @userid parameter for WebManex
--				 12/15/2014 DRP:  added the pack_foot, saveinit and invdate to the quickview results per request from a customer. 
--				 02/22/2016 VL:	  added FC code
--				 04/08/2016 VL:   Get FC installed and HC from new function because need to check both wmSettingManagement and mnxSettingManagement
--				 01/19/2017 VL:   Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[rptUnInvShipAll]

@userId uniqueidentifier=null


		
AS 
BEGIN

-- 02/18/16 VL added for FC installed or not
DECLARE @lFCInstalled bit
-- 04/08/16 VL changed to get FC installed from function
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

BEGIN
IF @lFCInstalled = 0
	BEGIN
	select	plmain.custno,custname,PackListNo,ShipDate,SoNo,INVOICENO,totexten,freightamt,dsctamt
			--,SUM(TOTTAXE + TOTTAXF) as Taxes	--12/15/2014 DRP:  replaced with the below
			,TOTTAXE + TOTTAXF as Taxes
			,INVTOTAL,PACK_FOOT,plmain.SAVEINIT,INVDATE

	from	PLMAIN
			inner join CUSTOMER on plmain.CUSTNO = customer.CUStno
		
	WHERE	plmain.IS_INVPOST = 0
			and plmain.PRINTED = 1
		
	--group by plmain.CUSTNO,CUSTNAME,PACKLISTNO,SHIPDATE,SONO,INVOICENO,TOTEXTEN,FREIGHTAMT,DSCTAMT,INVTOTAL	--12/15/2014 DRP:  removed the grouping because it did not work when I added the pack_foot to the results.
	END
ELSE
-- FC installed
	BEGIN
	select	plmain.custno,custname,PackListNo,ShipDate,SoNo,INVOICENO,totexten,freightamt,dsctamt
			--,SUM(TOTTAXE + TOTTAXF) as Taxes	--12/15/2014 DRP:  replaced with the below
			,TOTTAXE + TOTTAXF as Taxes
			,INVTOTAL,PACK_FOOT,plmain.SAVEINIT,INVDATE
			,totextenFC,freightamtFC,dsctamtFC,TOTTAXEFC + TOTTAXFFC as TaxesFC,INVTOTALFC--, Fcused.Symbol AS Currency
			-- 01/19/17 VL added functional currency code
			,totextenPR,freightamtPR,dsctamtPR,TOTTAXEPR + TOTTAXFPR as TaxesPR,INVTOTALPR, TF.Symbol AS TSymbol,PF.Symbol AS PSymbol, FF.Symbol AS FSymbol
	from	PLMAIN 
			-- 01/19/17 VL changed criteria to get 3 currencies
			INNER JOIN Fcused PF ON plmain.PrFcused_uniq = PF.Fcused_uniq
			INNER JOIN Fcused FF ON plmain.FuncFcused_uniq = FF.Fcused_uniq			
			INNER JOIN Fcused TF ON plmain.Fcused_uniq = TF.Fcused_uniq
			inner join CUSTOMER on plmain.CUSTNO = customer.CUStno
		
	WHERE	plmain.IS_INVPOST = 0
			and plmain.PRINTED = 1
	ORDER BY TSymbol, Custname, Invoiceno
	--group by plmain.CUSTNO,CUSTNAME,PACKLISTNO,SHIPDATE,SONO,INVOICENO,TOTEXTEN,FREIGHTAMT,DSCTAMT,INVTOTAL	--12/15/2014 DRP:  removed the grouping because it did not work when I added the pack_foot to the results.
	END
END -- End of IF FC installed
END