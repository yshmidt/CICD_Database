-- =============================================
-- Author:		Rajendra K	
-- Create date: <05/03/2019>
-- Description:Get Part Manufacturers Data
-- EXEC GetPartManufacturersData 'D8ELTKH9GL','5SP6PPUNMQ','_0DM120YNM',''
-- 03/25/2020 Rajendra K : Added @custNo,@consgUniq and used consign uniq_key to get anti avls
-- 08/26/2020 Rajendra K : Added condition to set @consgUniq value and Changed the condition in join
-- =============================================
CREATE PROCEDURE [dbo].[GetPartManufacturersData]  
(
  @bomparent NVARCHAR(10)='',
  @uniq_key NVARCHAR(10)='',
  @uniqWH NVARCHAR(10)= '',
  @location NVARCHAR(200)= ''
)
AS
BEGIN
	SET NOCOUNT ON;	
DECLARE @Avl_View TABLE (
			Orderpref numeric(2,0)
			, Mfgr_pt_no char(30)
			, Partmfgr char(8)
			, Uniq_key char(10)
			,Uniqmfgrhd char(10)
			, Matltype char(10)
			, lDisallowbuy bit
			, lDisallowkit bit
		);

DECLARE @AntiAvlView TABLE (
			Uniq_key char(10)
			, Partmfgr char(8)
			, Mfgr_pt_no char(30)
			, Bomparent char(10)
			,Uniqanti char(10)
		);

DECLARE @custNo CHAR(10),@consgUniq  CHAR(10)-- 03/25/2020 Rajendra K : Added @custNo,@consgUniq and used consign uniq_key to get anti avls
SET @custNo = (SELECT BOMCUSTNO FROM INVENTOR WHERE UNIQ_KEY = @bomParent)
SET @consgUniq = @uniq_key;--(SELECT ISNULL(UNIQ_KEY,@Uniq_key) FROM INVENTOR WHERE INT_UNIQ = @Uniq_key AND CUSTNO = @custNo)
-- 08/26/2020 Rajendra K : Added condition to set @consgUniq value and Changed the condition in join
IF EXISTS(SELECT 1 FROM INVENTOR WHERE INT_UNIQ = @Uniq_key AND CUSTNO = @custNo)
BEGIN
SELECT @consgUniq = UNIQ_KEY FROM INVENTOR WHERE INT_UNIQ = @Uniq_key AND CUSTNO = @custNo
END

INSERT INTO @Avl_View EXEC [Avl_View] @consgUniq;

INSERT INTO @AntiAvlView EXEC [AntiAvlView] @Bomparent, @consgUniq;-- 03/25/2020 Rajendra K : Added @custNo,@consgUniq and used consign uniq_key to get anti avls

SELECT DISTINCT Avl.Partmfgr
		,Avl.Mfgr_pt_no
		,Avl.Orderpref
		,Avl.Uniq_key
		,Avl.Uniqmfgrhd
		,AntiAvl.Uniqanti
		,IsChecked = CAST(CASE WHEN AntiAvl.Uniqanti IS NULL THEN 1 ELSE 0 END AS bit)
		,Avl.Matltype	
		,IM.UNIQWH
		,WH.WAREHOUSE
		,IM.LOCATION
		,(IM.QTY_OH - IM.RESERVED) AS AvailableQty
FROM  INVTMFGR IM 
	INNER JOIN	@Avl_View Avl ON  (IM.UNIQMFGRHD+IM.UNIQ_KEY) = (Avl.Uniqmfgrhd+Avl.Uniq_key)
	-- 08/26/2020 Rajendra K : Added condition to set @consgUniq value and Changed the condition in join
	LEFT OUTER JOIN @Antiavlview AntiAvl ON (Avl.Partmfgr+Avl.Mfgr_pt_no)=(AntiAvl.Partmfgr+AntiAvl.Mfgr_pt_no)
	-- (Avl.Uniq_key+Avl.Partmfgr+Avl.Mfgr_pt_no)=(AntiAvl.Uniq_key+AntiAvl.Partmfgr+AntiAvl.Mfgr_pt_no)
	INNER JOIN WAREHOUS WH ON IM.UNIQWH = WH.UNIQWH
	WHERE IM.IS_DELETED = 0 AND WH.WAREHOUSE NOT IN('WO-WIP','MRB','WIP') AND IM.UNIQWH = @uniqWH AND IM.LOCATION = @location
	ORDER BY Avl.Orderpref, Avl.Partmfgr, Avl.Mfgr_pt_no
END