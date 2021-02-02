-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <06/16/2010>
-- Description:	<Find all Work orders, which have current qty in FGI WC for the given uniq_key>
-- =============================================
CREATE PROCEDURE dbo.DeptFGI4ProductsView
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' ' 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Woentry.Wono, Curr_Qty AS FgiQty 
	FROM Woentry, Dept_qty 
	WHERE Woentry.Wono = Dept_qty.Wono 
	AND Dept_Qty.Dept_id = 'FGI'
	AND Woentry.Uniq_Key = @lcUniq_key
	AND Curr_Qty > 0 
	
END