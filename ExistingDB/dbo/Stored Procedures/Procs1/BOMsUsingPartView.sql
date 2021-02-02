-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <03/31/10>
-- Description:	<Find all BOM with a specific part as a component>
-- =============================================
CREATE PROCEDURE dbo.BOMsUsingPartView
	-- Add the parameters for the stored procedure here
	@lcUniq_key as char(10) =' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT UniqBomNo, BomParent,Bom_Det.Uniq_key,Inventor.BomCustNo 
		 FROM Bom_Det,Inventor
	WHERE Bom_Det.Uniq_Key = @lcUniq_Key
	 AND Inventor.Uniq_key=Bom_det.BomParent


END