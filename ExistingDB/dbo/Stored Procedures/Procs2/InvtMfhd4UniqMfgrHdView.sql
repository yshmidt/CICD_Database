-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	???
-- Modified: 10/09/14 YS removed invtmfhd table and replace with 2 new tables
-- =============================================
CREATE PROC [dbo].[InvtMfhd4UniqMfgrHdView] @lcUniqMfgrhd AS char(10) = ''
AS
-- 10/09/14 YS removed invtmfhd table and replace with 2 new tables
SELECT  l.uniq_key,l.uniqmfgrhd,M.* 
	FROM InvtMpnLink L INNER JOIN mfgrMaster M on l.mfgrmasterid=m.mfgrmasterid
	WHERE l.uniqmfgrhd = @lcUniqMfgrhd 