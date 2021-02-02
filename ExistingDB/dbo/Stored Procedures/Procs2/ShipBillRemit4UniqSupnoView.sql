
CREATE PROCEDURE [dbo].[ShipBillRemit4UniqSupnoView]
	-- Add the parameters for the stored procedure here
	@lcUniqSupNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/15 VL changed to link with bank to get default payment type
	--SELECT SHIPBILL.* from ShipBill, SupInfo
	--	where SUPINFO.UNIQSUPNO = @lcUniqSupNo 
	--		and SUPINFO.SUPID=SHIPBILL.CustNo
	--		and RECORDTYPE = 'R'
	-- 08/04/15 VL changed to have 'CHECK' if payment type is not set up: ISNULL(Banks.PaymentType, SPACE(50)) AS PaymentType
	SELECT SHIPBILL.*, ISNULL(Banks.PaymentType, dbo.PADR('Check',50,' ')) AS PaymentType from SupInfo, ShipBill LEFT OUTER JOIN Banks
		ON ShipBill.bk_uniq = Banks.Bk_uniq
		where SUPINFO.UNIQSUPNO = @lcUniqSupNo 
			and SUPINFO.SUPID=SHIPBILL.CustNo
			and RECORDTYPE = 'R'

END