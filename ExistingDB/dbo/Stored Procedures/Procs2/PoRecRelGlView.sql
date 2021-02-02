-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <12/06/2010>
-- Description:	<>
-- =============================================
CREATE PROCEDURE dbo.PoRecRelGlView 
	-- Add the parameters for the stored procedure here
	@lcLoc_uniq char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * from PORECRELGL where LOC_UNIQ =@lcLoc_uniq 
END