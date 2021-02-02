-- ======================================================================
-- Author:		Vicky Lu
-- Create date: 
-- Description:	Foreign Currency Home Currency info
---Modified:	10/13/2014 VL Created the view
-- ======================================================================
CREATE PROC [dbo].[FCHomeCurrencyView] @lcFcUsed_Uniq char(10) = ' '
AS
BEGIN
	SELECT * FROM ISO_4217 WHERE FcUsed_Uniq = @lcFcUsed_Uniq
END