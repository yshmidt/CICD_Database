CREATE PROCEDURE [dbo].[PoReconToDtView]
	-- Add the parameters for the stored procedure here
	@gcPoNum as char(15) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- 02/05/15 VL added FC field and I_link
    -- Insert statements for procedure here
	-- 11/16/16 VL added RecontoDtPR
	SELECT Pomain.ponum, Pomain.recontodt, PoUnique, RecVer, recontodtFC, I_link, recontodtPR
 FROM 
     pomain
 WHERE  Pomain.ponum = @gcPoNum 

END