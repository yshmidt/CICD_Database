CREATE PROCEDURE dbo.GetPlPricesQtyView 
	-- Add the parameters for the stored procedure here
	@gcPlUniqlnk as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Quantity 
		FROM PlPrices 
		WHERE PlUniqLnk = @gcPluniqlnk
		

END