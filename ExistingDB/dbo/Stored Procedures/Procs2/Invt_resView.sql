-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <04/26/2011>
-- Description:	<Invt_resView - primaru view for allocation module>
-- =============================================
CREATE PROCEDURE [dbo].[Invt_resView]  
	-- Add the parameters for the stored procedure here
	@pcUniq_key char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT INVT_RES.* FROM Invt_res 
		WHERE INVT_RES.UNIQ_KEY =@pcUniq_key
END