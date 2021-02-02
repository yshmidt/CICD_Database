-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/29/2013
-- Description: Bring all the units to be able to perform conversion in the business object	
-- =============================================
CREATE PROCEDURE dbo.UnitConversionView
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * from Unit
END
