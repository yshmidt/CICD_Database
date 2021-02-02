CREATE PROCEDURE dbo.ReturnCkDetView
	-- Add the parameters for the stored procedure here
	@gcUniqRetNo as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Arretdet.*
 FROM 
     arretdet
 WHERE  Arretdet.uniqretno = @gcUniqRetNo


END