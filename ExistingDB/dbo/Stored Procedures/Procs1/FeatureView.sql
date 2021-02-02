-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/05/2016
-- Description:	Feature setup, used in Product Type setup
-- =============================================
CREATE PROCEDURE FeatureView

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT * 
		FROM Feature
		ORDER BY Descript
	
END