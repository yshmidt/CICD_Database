-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/09/2012
-- Description:	Collect Shortage information for MRP level (will replace zShort cursor)
-- =============================================
CREATE PROCEDURE dbo.MrpShortageView
	-- Add the parameters for the stored procedure here
	@mrp_code int =0 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    SELECT MI.Uniq_Key, ShortQty AS ReqQty, Due_date AS Ship_Dts, WoEntry.GlDivNo, 
		CAST('WO' + KaMain.WoNo + CASE WHEN KaMain.LineShort=1 then ' Line Shortage' ELSE ' Kit Shortage' END as CHAR(24)) AS Ref,
		'Release WO' AS Action, BomParent AS ParentPt, @mrp_code AS Testlevel, WoEntry.PrjUnique, MI.Mrp_Code,
		MI.SCRAP,MI.MAKE_BUY ,MI.PHANT_MAKE   
		FROM Inventor MI INNER JOIN KaMain  ON MI.Uniq_Key = KaMain.Uniq_Key 
		INNER JOIN WoEntry ON WoEntry.WoNo = KaMain.WoNo
		WHERE MI.Part_Sourc = 'MAKE' 
		AND MI.Mrp_Code = @mrp_code 
		AND KaMain.ShortQty > 0 
		AND UPPER(WoEntry.OpenClos) NOT IN ('CLOSED','CANCEL','ARCHIVED')
		AND (UPPER(WoEntry.OpenClos) NOT IN ('MFG HOLD','ADMIN HOLD') OR 
		UPPER(WoEntry.OpenClos) IN ('MFG HOLD','ADMIN HOLD') AND MrponHold=0)
		AND  Make_Buy =0
		AND KaMain.IgnoreKit =0
	
	
END