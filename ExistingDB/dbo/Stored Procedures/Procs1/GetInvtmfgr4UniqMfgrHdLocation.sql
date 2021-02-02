-- =============================================
-- Author:		Vicky Lu	
-- Create date: <10/12/12>
-- Description:	<Get Invtmfgr records for passed in Uniqmfgrhd and Location
-- Modified: 10/08/14 YS replace invtmfhd with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[GetInvtmfgr4UniqMfgrHdLocation] 
	-- Add the parameters for the stored procedure here
	@ltUniqMfgrHdLocation AS tUniqMfgrHdLocation READONLY
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
-- 10/08/14 YS replace invtmfhd with 2 new tables
SELECT Inventor.Part_no, Inventor.Revision, Inventor.Part_sourc, Inventor.CustNo, Inventor.Uniq_key,
		m.Partmfgr,m.Mfgr_pt_no, ltUniqmfgrhdLocation.UniqMfgrHd, Invtmfgr.W_key, Invtmfgr.UniqWh, Invtmfgr.Is_Deleted
	FROM @ltUniqmfgrhdLocation ltUniqmfgrhdLocation 
	INNER JOIN InvtMPNLink L On ltUniqmfgrhdLocation.UniqMfgrhd = l.Uniqmfgrhd
	INNER JOIN Invtmfgr ON ltUniqmfgrhdLocation.uniqmfgrhd = Invtmfgr.UNIQMFGRHD 
		and ltUniqmfgrhdLocation.Location=Invtmfgr.LOCATION 
	INNER JOIN Inventor ON Invtmfgr.UNIQ_KEY=Inventor.UNIQ_KEY 
	--Invtmfhd
	INNER JOIN MfgrMaster M ON l.mfgrMasterId=m.MfgrMasterId
	ORDER BY Inventor.Part_no, Inventor.Revision, ltUniqmfgrhdLocation.UniqMfgrHd
	
END