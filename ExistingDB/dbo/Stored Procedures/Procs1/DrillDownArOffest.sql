-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/26/2011>
-- Description:	<get drill down information for the AR Offset transactio,>
-- Modification:
-- 09/15/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownArOffest]
	-- Add the parameters for the stored procedure here
	@cTransaction as char(10)=' '
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
	select Customer.CustName,ACCTSREC.INVDATE,ACCTSREC.INVNO,
		Aroffset.OffNote,ArOffset.AMOUNT,AROFFSET.UniqueAr,Aroffset.custno,
		Aroffset.UNIQ_ArOFF,Aroffset.cTransaction,AcctsRec.lPrepay,
		ArOffset.AMOUNTFC    
		from AcctsRec INNER JOIN AROFFSET on AcctsRec.UNIQUEAR =Aroffset.UNIQUEAR 
		INNER JOIN Customer ON Aroffset.custno =customer.custNO 
		where Aroffset.cTransaction =@cTransaction 
ELSE
    -- Insert statements for procedure here
	select Customer.CustName,ACCTSREC.INVDATE,ACCTSREC.INVNO,
		Aroffset.OffNote,ArOffset.AMOUNT,FF.Symbol AS Functional_Currency, AROFFSET.UniqueAr,Aroffset.custno,
		Aroffset.UNIQ_ArOFF,Aroffset.cTransaction,AcctsRec.lPrepay,
		ArOffset.AMOUNTFC, TF.Symbol AS Transaction_Currency,ArOffset.AMOUNTPR, PF.Symbol AS Presentation_Currency
		from AcctsRec
				INNER JOIN Fcused TF ON AcctsRec.Fcused_uniq = TF.Fcused_uniq
				INNER JOIN Fcused PF ON AcctsRec.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON AcctsRec.FuncFcused_uniq = FF.Fcused_uniq
		INNER JOIN AROFFSET on AcctsRec.UNIQUEAR =Aroffset.UNIQUEAR 
		INNER JOIN Customer ON Aroffset.custno =customer.custNO 
		where Aroffset.cTransaction =@cTransaction 

END