-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <12/16/2010>
-- Description:	<Invt_isu4PoView> used in poreceiving screen
-- =============================================
CREATE PROCEDURE dbo.Invt_isu4PoView
	-- Add the parameters for the stored procedure here
	@pcPonum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT INVT_ISU.* FROM Invt_isu 
		WHERE INVT_ISU.UNIQ_KEY in (SELECT UNIQ_KEY FROM POITEMS WHERE PONUM=@pcPonum)
END