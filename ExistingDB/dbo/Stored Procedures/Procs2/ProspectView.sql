-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/11/2016
-- Description:	Order Configuration Prospect
-- =============================================
CREATE PROCEDURE [dbo].[ProspectView]
	@Custno char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT *
		FROM Prospect
		WHERE Custno = @Custno 
		
END