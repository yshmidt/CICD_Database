CREATE PROCEDURE dbo.GetPlUniqLnk
	-- Add the parameters for the stored procedure here
	@gcInv_link as char(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select PluniqLnk 
	from PlPrices 
	where Inv_link = @gcInv_link
END