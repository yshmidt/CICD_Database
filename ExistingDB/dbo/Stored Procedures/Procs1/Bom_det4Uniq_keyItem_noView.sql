CREATE PROC [dbo].[Bom_det4Uniq_keyItem_noView] @gUniq_key AS char(10) = ' ', 
	@lcUniq_key AS char(10) = ' ', @lnItem_no AS numeric(4,0) = 0
AS
SELECT UNIQBOMNO, Qty 
	FROM Bom_det 
	WHERE Bom_det.Bomparent = @gUniq_key
	AND UNIQ_KEY = @lcUniq_key 
	AND 1 = CASE WHEN (@lnItem_no <> 0) THEN CASE WHEN (ITEM_NO = @lnItem_no) THEN 1 ELSE 0 END
			ELSE 1 END








