-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <07/13/2011>
-- Description:	<Check if entered reference exists for any primary key, but the given one>
-- =============================================
CREATE PROCEDURE [dbo].[GlADRefView]
	-- Add the parameters for the stored procedure here
	@pRef as char(10)=' ',@pKey as char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Gladhdr.glahdrkey, Gladhdr.adref from Gladhdr WHERE adref=@pRef and Gladhdr.glahdrkey<>@pKey
	
END