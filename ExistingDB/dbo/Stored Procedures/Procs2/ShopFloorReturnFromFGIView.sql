-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 03/19/14 VL remove CoungFlag = '' criteria and changed to catch in form level, otherwise this sp will rebutn 0 record and form 
--				would try to find deleted record
--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 04/27/15 VL added CountFlag field
-- =============================================
CREATE PROCEDURE [dbo].[ShopFloorReturnFromFGIView]
	-- Add the parameters for the stored procedure here
	@gUniq_key char(10)=' '
AS
BEGIN

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;
--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
SELECT m.Partmfgr, Warehouse, Location, Whno, Invtmfgr.W_key, (Qty_Oh-Reserved) AS Qty_oh, L.UniqMfgrHd, Invtmfgr.CountFlag
	--  10/09/14 YS removed invtmfhd table and replaced with 2 new tables
	FROM InvtMPNLink L,MfgrMaster M, Invtmfgr, Warehous
	WHERE L.Uniq_key = @gUniq_Key
	AND Invtmfgr.UniqMfgrHd = L.UniqMfgrHd
	AND Warehous.UniqWh = Invtmfgr.UniqWh
	AND WAREHOUSE <> 'WIP   ' 
	AND WAREHOUSE <> 'WO-WIP'	
	AND Warehouse <> 'MRB   '
	AND Qty_oh-Reserved > 0
	AND Netable = 1
	AND Invtmfgr.Is_Deleted = 0
	AND Invtmfgr.InStore = 0
	AND L.Is_Deleted =0 and m.IS_DELETED=0
	--AND Invtmfgr.CountFlag = ''

END