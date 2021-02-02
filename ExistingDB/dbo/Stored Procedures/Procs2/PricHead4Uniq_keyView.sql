-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/24/10
-- Description:	Get Prichead records, used in Price module
-- Modified: 
-- 05/02/16 VL	Added different code if FC is installed or not, if yes, need to show currency symbol
-- =============================================
CREATE PROC [dbo].[PricHead4Uniq_keyView] @gUniq_key AS char(10) = ''
AS
-- 05/02/16 VL added for FC installed or not
	DECLARE @lFCInstalled bit
	-- 04/08/16 VL changed to get FC installed from function
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
	BEGIN
	IF @lFCInstalled = 1
		BEGIN
		SELECT PricHead.*, Fcused.Symbol, CustName
			FROM PricHead, Fcused, Customer
			WHERE Prichead.Category = Customer.Custno 
			AND Prichead.Fcused_uniq = Fcused.Fcused_uniq
			AND Uniq_key = @gUniq_key
			ORDER BY Number
		END
	ELSE
		BEGIN
		SELECT PricHead.*, CustName
			FROM PricHead, Customer
			WHERE Prichead.Category = Customer.Custno 
			AND Uniq_key = @gUniq_key
			ORDER BY Number
		END
	END
	select * from fcused