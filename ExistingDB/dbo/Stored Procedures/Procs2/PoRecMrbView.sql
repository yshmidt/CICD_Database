CREATE PROCEDURE [dbo].[PoRecMrbView] 
	-- Add the parameters for the stored procedure here
	@gnTransNo as numeric = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--04/17/14 YS added dmrNote 
    -- Insert statements for procedure here
	SELECT PoRecMrb.Dmr_No, PoRecMrb.Rma_Date, PoRecMrb.TransNo, PoRecMrb.Ret_Qty,PorecMrb.dmrNote 
	FROM PoRecMrb
	WHERE PoRecMrb.TransNo = @gnTransNo 
		AND PoRecMrb.Dmr_No <> '          ' 
	
END