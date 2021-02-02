-- =============================================
-- Author:		<Bill Blake>
-- Create date: ?/?/2010
-- Description:	Find Invoice based on invoice number and supplier ( used in debit memo)
-- Modified: 
-- 02/27/15 YS added r_link column 
-- 12/08/16 VL added Fchist_key and Fcused_uniq fields
-- 02/07/17 VL added functional currency code and missing InvAmountFC
-- =============================================
CREATE PROCEDURE [dbo].[FindAPfromInvNoView] 
	-- Add the parameters for the stored procedure here
	@gcUniqSupNo as char(10) = '', @gcInvNo as char(20) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--02/27/15 YS added r_link column 
	SELECT UniqApHead, Invno, Ponum, InvDate, InvAmount, Due_Date,r_link, InvAmountFC, Fchist_key, FcUsed_uniq, InvAmountPR, PRFcused_Uniq, FUNCFCUSED_UNIQ
	FROM ApMaster 
	WHERE InvNo =@gcInvNo 
		AND UniqSupNo = @gcUniqSupNo 
		AND InvAmount - (Appmts + Disc_Tkn) > 0 

END