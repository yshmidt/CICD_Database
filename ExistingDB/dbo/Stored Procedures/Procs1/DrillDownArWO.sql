-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/26/2011>
-- Description:	<get drill down information for the AR Write - off>
-- Modification:
-- 09/15/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added presentation currency fields
-- 04/13/17 VL: Fix Presentation_Currency
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownArWO]
	-- Add the parameters for the stored procedure here
	@ArWoUnique as char(10)=' '
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
	select Customer.CustName,ACCTSREC.INVDATE,ACCTSREC.INVNO,Acctsrec.Invdate,AcctsRec.INVTOTAL,
		Ar_wo.Wo_reason,Ar_wO.WO_AMT,AR_wO.ARWOUNIQUE ,Acctsrec.custno,
		Ar_wo.UNIQuear, AcctsRec.INVTOTALFC,Ar_wO.WO_AMTFC
		from AcctsRec INNER JOIN AR_WO on AcctsRec.UNIQUEAR =Ar_wo.UNIQUEAR 
		INNER JOIN Customer ON Acctsrec.custno =customer.custNO 
		where Ar_wo.ArWounique =@ArWoUnique 
ELSE
    -- Insert statements for procedure here
	select Customer.CustName,ACCTSREC.INVDATE,ACCTSREC.INVNO,Acctsrec.Invdate,AcctsRec.INVTOTAL,
		Ar_wo.Wo_reason,Ar_wO.WO_AMT,FF.Symbol AS Functional_Currency,AR_wO.ARWOUNIQUE ,Acctsrec.custno,
		Ar_wo.UNIQuear, AcctsRec.INVTOTALFC,Ar_wO.WO_AMTFC, TF.Symbol AS Transaction_Currency,
		AcctsRec.INVTOTALPR,Ar_wO.WO_AMTPR, PF.Symbol AS Presentation_Currency
		FROM Acctsrec
				INNER JOIN Fcused TF ON AcctsRec.Fcused_uniq = TF.Fcused_uniq
				INNER JOIN Fcused PF ON AcctsRec.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON AcctsRec.FuncFcused_uniq = FF.Fcused_uniq
		INNER JOIN AR_WO on AcctsRec.UNIQUEAR =Ar_wo.UNIQUEAR 
		INNER JOIN Customer ON Acctsrec.custno =customer.custNO 
		where Ar_wo.ArWounique =@ArWoUnique 

END