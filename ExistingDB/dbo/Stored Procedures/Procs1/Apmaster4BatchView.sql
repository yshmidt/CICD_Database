CREATE PROCEDURE [dbo].[Apmaster4BatchView]
	-- Add the parameters for the stored procedure here
	@lcUniqAPHead char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT APMASTER.UNIQAPHEAD ,APMASTER.RecVer ,APMASTER.lForceUpdate from APMASTER where UNIQAPHEAD =@lcUniqAPHead 
END
