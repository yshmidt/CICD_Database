-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	???
-- Modified: 10/08/14 YS replace invtmfhd table with 2 new tables 
-- 10/24/14 YS added mfgrmasterid to the resulting set
-- 10/29/14    move orderpref to invtmpnlink
-- =============================================
CREATE proc [dbo].[GetAvl4UniqKeyView] 
	@pcUniq_KEY AS Char(10)=null, @plShowDeleted as bit = 0
AS
--10/08/14 YS replace invtmfhd table with 2 new tables 
  -- SELECT Partmfgr,Mfgr_Pt_no,Autolocation,OrderPref,UniqMfgrHd,MatlType,INVTMFHD.LDISALLOWKIT,INVTMFHD.LDISALLOWBUY,Uniq_key 
		--	FROM Invtmfhd 
		--WHERE Invtmfhd.Uniq_key=@pcUniq_KEY AND Invtmfhd.Is_deleted=@plShowDeleted ORDER BY OrderPref
	SELECT Partmfgr,Mfgr_Pt_no,Autolocation,OrderPref,l.UniqMfgrHd,MatlType,LDISALLOWKIT,LDISALLOWBUY,l.Uniq_key,m.MfgrMasterId 
			FROM MfgrMaster M INNER JOIN InvtMPNLink L ON l.mfgrMasterId =m.MfgrMasterId
		WHERE L.Uniq_key=@pcUniq_KEY AND L.Is_deleted=@plShowDeleted and m.IS_DELETED=@plShowDeleted  
		ORDER BY OrderPref
	
	


	



