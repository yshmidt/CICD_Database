-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/22/2010>
-- Description:	<Invt_res for items (uniq_key), which are in the given PO>
-- =============================================
CREATE PROCEDURE [dbo].[Invt_res4PoView]  
	-- Add the parameters for the stored procedure here
	@pcPonum char(15)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT INVT_RES.* FROM Invt_res 
		WHERE INVT_RES.UNIQ_KEY in (SELECT UNIQ_KEY FROM POITEMS WHERE PONUM=@pcPonum)
END