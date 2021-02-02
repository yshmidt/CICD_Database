-- =============================================
-- Author:		Vicky Lu
-- Create date: 12/03/10 
-- Description:	This procedure will calculate what's the warranty day for the uniq_key
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetRMAWarrantyDay4Uniq_key] @lcUniq_key AS char(10) = '',
				@lcCustno AS char(10) = '', @lnWarranty numeric(3,0) OUTPUT
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT @lnWarranty = Warranty
	FROM PRICHEAD
	WHERE Uniq_key = @lcUniq_key
	AND CATEGORY = @lcCustno
	
IF @@ROWCOUNT = 0
	SELECT @lnWarranty = Warranty
		FROM PRICHEAD
		WHERE Uniq_key = @lcUniq_key
		AND CATEGORY = '000000000~'
		
	IF @@ROWCOUNT = 0
		SELECT @lnWarranty = 0

END



