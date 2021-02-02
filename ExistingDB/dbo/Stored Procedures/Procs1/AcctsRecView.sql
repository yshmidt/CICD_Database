CREATE PROCEDURE dbo.AcctsRecView
	-- Add the parameters for the stored procedure here
	@gcUniqueAr AS char(10) = ''	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * 
		FROM AcctsRec 
		WHERE UniqueAr = @gcUniqueAr

END