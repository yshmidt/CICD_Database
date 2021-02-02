-- Author:  Raviraj Patil  
-- Create date: <07/03/2019>  
-- Description:Division Inventory Details  
-- EXEC [GetIntentoryDetailByDevision] '_1LR0NALAS'
-- 08/5/2019 Mahesh B Reduce the size of Unique Key from 20 to 10
--==============================================================================================  
CREATE PROCEDURE [dbo].[GetIntentoryDetailByDevision]
(  
 @uniqKey AS CHAR(10)='' -- 08/5/2019 Mahesh B Reduce the size of Unique Key from 20 to 10
)  
AS  
BEGIN  
	SET NOCOUNT ON;

	SELECT i.UNIQ_KEY, SUM (mf.QTY_OH) AS 'OnHand', SUM (mf.RESERVED) AS 'Reserved',SUM(QTY_OH-RESERVED) AS Available
  
	FROM INVENTOR i 
	JOIN INVTMFGR mf ON i.UNIQ_KEY  = mf.UNIQ_KEY  AND  i.UNIQ_KEY = @uniqKey  AND mf.IS_DELETED = 0  
	JOIN InvtMPNLink mpn ON mf.UNIQMFGRHD = mpn.uniqmfgrhd  
	JOIN MfgrMaster mm ON mpn.MfgrMasterId = mm.MfgrMasterId AND mm.is_deleted = 0  
	JOIN WAREHOUS wh ON mf.UNIQWH = wh.UNIQWH   
	WHERE wh.WAREHOUSE NOT IN ('WO-WIP','MRB','WIP')  
	GROUP BY i.UNIQ_KEY

END  
  