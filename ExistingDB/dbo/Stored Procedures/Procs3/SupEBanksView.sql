-- =============================================
-- Author:		Vicky Lu	
-- Create date: 07/28/15
-- Description:	Get all supplier e banks
-- =============================================
CREATE PROCEDURE [dbo].[SupEBanksView]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * 
		FROM Banks
		WHERE internalUse = 0
		ORDER BY Bank
END