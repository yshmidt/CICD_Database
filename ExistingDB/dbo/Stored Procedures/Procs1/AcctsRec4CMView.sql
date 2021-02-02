-- =============================================
-- Author:		Bill?
-- Create date:
-- Description:	Get acctsrec used in CM module
-- Modification:
--	07/20/16	VL	Added 2nd parameter @lcCustno, found if user has multiple general CMs with same reference number, would have problem to find the right record
-- =============================================
CREATE PROCEDURE [dbo].[AcctsRec4CMView] 
	-- Add the parameters for the stored procedure here
	@gcInvNo as Char(10) = ' ', @lcCustno as char(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
		FROM ACCTSREC	
		WHERE INVNO = @gcInvNo
		AND Custno = @lcCustno
END