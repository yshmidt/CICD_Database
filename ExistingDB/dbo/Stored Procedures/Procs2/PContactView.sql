-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/11/2016
-- Description:	Prospect Contact (in order configuration)
-- =============================================
CREATE PROCEDURE [dbo].[PContactView]
	@Custno char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT *
		FROM PContact
		WHERE Custno = @Custno 
		ORDER BY Lastname, Firstname
		
END