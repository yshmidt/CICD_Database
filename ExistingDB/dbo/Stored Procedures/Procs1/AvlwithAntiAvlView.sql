
CREATE PROCEDURE [dbo].[AvlwithAntiAvlView] @gUniq_key char(10)=' ', @cUniq_key char(10)=' ' 

AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @Avl_View TABLE (Orderpref numeric(2,0), Mfgr_pt_no char(30), Partmfgr char(8), Uniq_key char(10),
		Uniqmfgrhd char(10), Matltype char(10), lDisallowbuy bit, lDisallowkit bit);

DECLARE @AntiAvlView TABLE (Uniq_key char(10), Partmfgr char(8), Mfgr_pt_no char(30), Bomparent char(10),
		Uniqanti char(10));

INSERT INTO @Avl_View EXEC [Avl_View] @cUniq_key;

INSERT INTO @AntiAvlView EXEC [AntiAvlView] @gUniq_key, @cUniq_key;

SELECT Avl.Partmfgr, Avl.Mfgr_pt_no, Avl.Orderpref, Avl.Uniq_key, 
	AntiAvl.Uniqanti, CheckUse = CAST(CASE WHEN AntiAvl.Uniqanti IS NULL THEN 1 ELSE 0 END AS bit), Avl.Matltype, 
	Avl.lDisallowbuy, Avl.lDisallowkit
	FROM @Avl_View Avl LEFT OUTER JOIN @Antiavlview AntiAvl
	ON (Avl.Uniq_key+Avl.Partmfgr+Avl.Mfgr_pt_no)=(AntiAvl.Uniq_key+AntiAvl.Partmfgr+AntiAvl.Mfgr_pt_no)
	ORDER BY Avl.Orderpref, Avl.Partmfgr, Avl.Mfgr_pt_no
END


