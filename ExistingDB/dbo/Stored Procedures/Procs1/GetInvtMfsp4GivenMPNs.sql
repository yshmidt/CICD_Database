-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/29/2013
-- Description:	Find all suppliers for all given uniqmfhd. Use table valued parameter
-- Modified : 01/28/14 YS added PFDSUPL and remove deleted suppliers
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtMfsp4GivenMPNs] 
	-- Add the parameters for the stored procedure here
	@tUniqmfgrhd tUniqMfgrHd READONLY 
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- 01/28/14 YS added PFDSUPL and remove deleted suppliers
    SELECT Supinfo.supname, Invtmfsp.uniqmfsp, Supinfo.supid,
		Supinfo.uniqsupno, Invtmfsp.uniqmfgrhd, Invtmfsp.suplpartno,
		Invtmfsp.uniq_key,Invtmfsp.PFDSUPL
	FROM invtmfsp 
    INNER JOIN supinfo 
   ON  Invtmfsp.UniqSupno = Supinfo.UniqSupno
   INNER JOIN @tUniqmfgrhd t on  Invtmfsp.uniqmfgrhd =t.UniqMfgrHd
   where Invtmfsp.IS_DELETED=0


END