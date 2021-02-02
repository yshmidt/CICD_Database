-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/29/2013
-- Description:	get material and target price
-- =============================================
CREATE PROCEDURE GetMatlCostAndTargetPriceView 
	-- Add the parameters for the stored procedure here
	@uniq_key char(10) = '' 
	   
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Matl_Cost,TargetPrice FROM Inventor WHERE Uniq_key=@uniq_key 
END