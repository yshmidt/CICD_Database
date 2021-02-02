-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/11/2016
-- Description:	Order Configuration Price break
-- =============================================
CREATE PROCEDURE [dbo].[CnfgPricView]
	@gUniq_key char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	SELECT * 
		FROM CnfgPric
		WHERE CnfgPric.UNIQ_KEY = @gUniq_key
		ORDER BY Qty_Break
		
END