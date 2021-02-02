
-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/08/2020
-- Description:	Used to update Ipkey for desktop
-- Modification:
-- =============================================
CREATE PROCEDURE [dbo].[IpkeyView]
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	SELECT * 
		FROM IPKEY
		WHERE UNIQ_KEY = @lcUniq_key
END