-- =============================================
-- Author:		
-- Create date:
-- Description:	get arcredit for CM
-- Modification:
-- 03/20/15 VL added FC fields
-- 10/09/15 VL rename Orig_Fchkey to Orig_Fchist_key
-- 10/24/16 VL added presentation currency fields
-- 01/13/17 VL added PRFcused_uniq and FuncFcused_uniq
-- =============================================
CREATE PROCEDURE [dbo].[ArCredit4CmView] 
	-- Add the parameters for the stored procedure here
	@gcUniqDetNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 03/20/15 VL added FC fields
	-- 10/09/15 VL rename Orig_Fchkey to Orig_Fchist_key
	-- 10/24/16 VL added presentation currency fields
	-- 01/13/17 VL added PRFcused_uniq and FuncFcused_uniq
	SELECT CustNo, InvNo, Rec_Date, Rec_Type, Rec_Advice, Rec_Amount, Disc_Taken, UniqDetNo, UniqueAR, Rec_AmountFC, Disc_TakenFC, Fcused_uniq, Fchist_key, ORIG_FCHist_KEY, Rec_amountPR, Disc_TakenPR,PRFcused_uniq,FuncFcused_uniq
	from ArCredit
	where UniqDetNo = @gcUniqDetNo
END