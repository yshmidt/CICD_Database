-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/25/2011>
-- Description:	<get drill down information for the AP Offset transactio,>
-- Modification:
-- 09/15/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownApOffest]
	-- Add the parameters for the stored procedure here
	@UNIQ_SAVE as char(10)=' '
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
	select Supinfo.SUPNAME,Apmaster.INVDATE,Apmaster.INVNO,Apmaster.PONUM,
		Apmaster.REASON,ApOffset.AMOUNT,ApOffset.OFFNOTE, APOFFSET.UNIQAPHEAD,APOFFSET.UNIQSUPNO,
		Apoffset.UNIQ_APOFF,Apoffset.UNIQ_SAVE,Apmaster.lPrepay,
		ApOffset.AMOUNTFC
		from APMASTER INNER JOIN APOFFSET on Apmaster.UNIQAPHEAD =Apoffset.UNIQAPHEAD 
		INNER JOIN SUPINFO ON Apmaster.UNIQSUPNO =Supinfo.UNIQSUPNO 
		where Apoffset.UNIQ_SAVE =@UNIQ_SAVE 
ELSE
    -- Insert statements for procedure here
	select Supinfo.SUPNAME,Apmaster.INVDATE,Apmaster.INVNO,Apmaster.PONUM,
		Apmaster.REASON,ApOffset.AMOUNT,FF.Symbol AS Functional_Currency, ApOffset.OFFNOTE, APOFFSET.UNIQAPHEAD,APOFFSET.UNIQSUPNO,
		Apoffset.UNIQ_APOFF,Apoffset.UNIQ_SAVE,Apmaster.lPrepay,
		ApOffset.AMOUNTFC, TF.Symbol AS Transaction_Currency,
		ApOffset.AMOUNTPR, PF.Symbol AS Presentation_Currency
		FROM Apmaster 
				INNER JOIN Fcused TF ON Apmaster.Fcused_uniq = TF.Fcused_uniq
				INNER JOIN Fcused PF ON Apmaster.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON Apmaster.FuncFcused_uniq = FF.Fcused_uniq
		INNER JOIN APOFFSET on Apmaster.UNIQAPHEAD =Apoffset.UNIQAPHEAD 
		INNER JOIN SUPINFO ON Apmaster.UNIQSUPNO =Supinfo.UNIQSUPNO 
		where Apoffset.UNIQ_SAVE =@UNIQ_SAVE 
END