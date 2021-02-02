-- =============================================
-- Author:		Bill Blake
-- Create date: <Create Date,,>
-- Description:	Get PO reconcilation tax record
-- Modified:	
-- 06/07/16 YS: Added isManualCM column
-- =============================================
CREATE PROCEDURE [dbo].[ARInvoices4CMView] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT AcctsRec.*, Customer.CustName 
		FROM AcctsRec, Customer
		WHERE (Acctsrec.Invtotal - Acctsrec.Arcredits) > 0
		and AcctsRec.CustNo = Customer.CustNo 
		-- 06/07/16 YS: Added isManualCM column Use this and lPrepay flag instaed of hard coded values
		--AND upper(LEFT(AcctsRec.InvNo,4)) <> 'PPAY'
		--and upper(left(AcctsRec.InvNO,2)) <> 'CM'
		AND AcctsRec.lPrepay=0
		and AcctsRec.isManualCM=0
END