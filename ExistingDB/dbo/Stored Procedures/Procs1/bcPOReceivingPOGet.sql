-- =============================================
-- Author:		David Sharp
-- Create date: 10/18/2012
-- Description:	gets a list of Open orders for receiving
-- =============================================
CREATE PROCEDURE bcPOReceivingPOGet
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT p.PONUM,p.BUYER,s.SUPID,s.SUPNAME,s.PHONE
		FROM POMAIN p INNER JOIN SUPINFO s ON p.UNIQSUPNO=s.UNIQSUPNO
		WHERE POSTATUS='OPEN'
END