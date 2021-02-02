-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/02/2011>
-- Description:	<Drill Down into Sales transactions>
-- Modification:
-- 09/14/15 VL: Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/09/16 VL: added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownSales]
	-- Add the parameters for the stored procedure here
	@packlistno char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- 05/27/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0

	-- Insert statements for procedure here
	-- 12/09/16 VL removed the FC fields I added before, no need to show to confuse users for non-FC system
	select Customer.CUSTNAME,Sodetail.SONO,PlMain.PACKLISTNO , Plmain.INVOICENO ,Plmain.INVDATE ,plmain.INVTOTAL,plmain.FREIGHTAMT ,plmain.DSCTAMT ,plmain.TOTTAXE ,plmain.TOTTAXF,
	PLMAIN.CUSTNO  ,plprices.DESCRIPT,plprices.QUANTITY ,plprices.PRICE ,plprices.EXTENDED ,plprices.TAXABLE ,plprices.UNIQUELN,
	CASE WHEN sodetail.LINE_NO IS NULL THEN plprices.UNIQUELN ELSE sodetail.LINE_NO end AS Line_no,sodetail.UNIQ_KEY,inventor.PART_NO,inventor.REVISION,inventor.DESCRIPT,inventor.PART_SOURC
	from PLMAIN inner join CUSTOMER on plmain.CUSTNO=customer.CUSTNO
	inner join PLPRICES on plmain.PACKLISTNO = plprices.PACKLISTNO 
	left outer join SODETAIL on plprices.UNIQUELN =SODETAIL.UNIQUELN 
	left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY 
	where plmain.PACKLISTNO =@packlistno
ELSE
	-- Insert statements for procedure here
	-- 12/09/16 VL added presentation currency fields
	select Customer.CUSTNAME,Sodetail.SONO,PlMain.PACKLISTNO , Plmain.INVOICENO ,Plmain.INVDATE ,plmain.INVTOTAL,plmain.FREIGHTAMT ,plmain.DSCTAMT ,plmain.TOTTAXE ,plmain.TOTTAXF,
	PLMAIN.CUSTNO  ,plprices.DESCRIPT,plprices.QUANTITY ,plprices.PRICE ,plprices.EXTENDED, FF.Symbol AS Functional_Currency ,plprices.TAXABLE ,plprices.UNIQUELN,
	CASE WHEN sodetail.LINE_NO IS NULL THEN plprices.UNIQUELN ELSE sodetail.LINE_NO end AS Line_no,sodetail.UNIQ_KEY,inventor.PART_NO,inventor.REVISION,inventor.DESCRIPT,inventor.PART_SOURC, 
	plmain.INVTOTALFC,plmain.FREIGHTAMTFC ,plmain.DSCTAMTFC ,plmain.TOTTAXEFC ,plmain.TOTTAXFFC, plprices.PRICEFC ,plprices.EXTENDEDFC, TF.Symbol AS Transaction_Currency,
	plmain.INVTOTALPR,plmain.FREIGHTAMTPR ,plmain.DSCTAMTPR ,plmain.TOTTAXEPR ,plmain.TOTTAXFPR, plprices.PRICEPR ,plprices.EXTENDEDPR, PF.Symbol AS Presentation_Currency
	FROM Plmain INNER JOIN Fcused TF ON Plmain.Fcused_uniq = TF.Fcused_uniq
				INNER JOIN Fcused PF ON Plmain.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON Plmain.FuncFcused_uniq = FF.Fcused_uniq
		inner join CUSTOMER on plmain.CUSTNO=customer.CUSTNO
	inner join PLPRICES on plmain.PACKLISTNO = plprices.PACKLISTNO 
	left outer join SODETAIL on plprices.UNIQUELN =SODETAIL.UNIQUELN 
	left outer join INVENTOR on sodetail.UNIQ_KEY = inventor.UNIQ_KEY 
	where plmain.PACKLISTNO =@packlistno

END