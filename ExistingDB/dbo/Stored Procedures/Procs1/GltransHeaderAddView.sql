-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <11/29/11>
-- Description:	<Create an empty gltransheader view to insert new records w/o bringning all the records onto UI>
-- =============================================
CREATE PROCEDURE [dbo].[GltransHeaderAddView]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM GLTRANSHEADER WHERE 0=1
END