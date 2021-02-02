
CREATE PROCEDURE [dbo].[KitBomInfoView] @gWono AS char(10) = ' '
AS
BEGIN
--- 03/28/17 YS changed length of the part_no column from 25 to 35
SET NOCOUNT ON;

-- 08/29/12 VL changed Custrev char(4) to char(8)
-- 02/17/15 VL added 10th parameter to filter out inactive part
-- 08/27/15 VL changed StdCostper1Build from numeric(13,5) to numeric(29,5), Inovar has really bit number and caused overflow, bom_qty numeric(9,2), bld_qty numeric(7,0) and stdcost numeric(13,5)
-- 06/28/17 Rajendra K added Qty_Each column in select list
-- 05/24/19 Rajendra K Changed setting name
DECLARE @lnTotalNo int, @lnCount int, @WODue_date smalldatetime, @WOBldQty numeric(7,0), 
		@lKitIgnoreScrap bit, @ZDept_id char(4), @ZUniq_key char(10), @ZBomparent char(10), @ZQty numeric(9,2),
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		@ZUsed_inkit char(1), @ZPart_Sourc char(8), @ZPart_no char(35), @ZRevision char(8), @ZDescript char(45),
		@ZPart_class char(8), @ZPart_Type char(8), @ZU_of_meas char(4), @ZScrap numeric(6,2), @ZSetupScrap numeric(4,0), 
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		@lnQtyReq numeric(12,5), @lUsesetscrp bit, @ZCustPartNo char(35), @WOUniq_key char(10), @ZReqQty numeric(12,2);
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZResult TABLE (Dept_id char(4), Uniq_key char(10), BomParent char(10), Qty numeric(9,2), ShortQty numeric(9,2),
		Used_inKit char(1), Part_Sourc char(8), Part_no char(35), Revision char(8), Descript char(45), Part_class char(8), 
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		Part_type char(8), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), CustPartNo char(35))
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @Phantom2 TABLE (Item_no numeric(4,0),Part_no char(35),Revision char(8),Custpartno char(35),
		Custrev char(8),Part_class char(8),Part_type char(8),Descript char(45),Qty numeric(9,2), Scrap_qty numeric(9,2), StdCostper1Build numeric(29,5),
		Bomparent char(10),Uniq_key char(10),Dept_id char(4),Item_note text,Offset numeric(3,0),
		Term_dt smalldatetime, Eff_dt smalldatetime,Custno char(10),U_of_meas char(4),Inv_note text,
		Part_sourc char(10),Perpanel numeric(4,0),Used_inkit char(1), Scrap numeric(6,2), 
		SetupScrap numeric(4,0),UniqBomNo char(10),Buyer_type char(3),StdCost numeric(13,5),
		Phant_make bit, Make_buy bit, MatlType char(5), TopStdCost numeric(13,5), LeadTime numeric(4,0),
		UseSetScrp bit, SerialYes bit, StdBldQty numeric(8,0), Level numeric(3,0), ReqQty numeric(12,2), nRecno int identity );

SELECT @WOuniq_key = Uniq_key, @WODue_date = Due_date, @WOBldQty = BldQty FROM WOENTRY WHERE WONO = @gWono

--12/20/2018 Rajendra K: Get the settingValue  
SELECT @lKitIgnoreScrap = ISNULL(w.settingValue,m.settingValue) FROM MnxSettingsManagement m LEFT JOIN wmSettingsManagement w -- 05/24/19 Rajendra K Changed setting name
                                            ON m.settingId=w.settingId WHERE settingName='ExcludeScrapInKitting' AND settingModule='ICMWOSetup' -- settingName='Kitting'

--lKitIgnoreScrap	FROM KitDef;  Commented for now
	
SELECT @lUsesetscrp = Usesetscrp 
	FROM Inventor
	WHERE Uniq_key = @WOuniq_key;
	
--@cPhantomUniqkey, @nPhantomQty numeric,@cChkDate, @dDate, @cMake, @cKitInUse,@cMakeBuy
--SELECT *, ReqQty AS ShortQty FROM [dbo].[fn_PhantomSubSelect] (@WOuniq_key, @WOBldQty, 'T', @WODue_date, 'F', 'T', 'F', @lKitIgnoreScrap);
-- 02/17/15 VL added 10th parameter to filter out inactive part
--08/12/2018 Rajendra K added UniqueId to Generate uniqe number
SELECT Dept_id, Uniq_key, BomParent, Qty, ReqQty AS ShortQty, Used_inKit, Part_Sourc, Part_no, Revision, Descript, 
		Part_class, Part_type, U_of_meas, Scrap, SetupScrap, CustPartNo, SerialYes,Qty_Each,dbo.fn_GenerateUniqueNumber() As UniqueId
		FROM [dbo].[fn_PhantomSubSelect] (@WOuniq_key, @WOBldQty, 'T', @WODue_date, 'F', 'T', 'F', @lKitIgnoreScrap,0,0);

END