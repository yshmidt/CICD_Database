
-- Author:		Raviraj Patil
-- Create date: <06/19/2019>
-- Description:Division Inventory Details
-- EXEC [GetDivisionInvnetoryDetails] 'Y90R4FUYZ9',1,150,'',''
 -- 08/5/2019 Mahesh B Reduce the size of Unique Key from 20 to 10
--==============================================================================================
CREATE PROCEDURE [dbo].[GetDivisionInvnetoryDetails]
(
	@uniqKey AS CHAR(10)='', -- 08/5/2019 Mahesh B Reduce the size of Unique Key from 20 to 10
	@startRecord INT=1,
	@endRecord INT=10,
	@filterExpression NVARCHAR(1000) = null,
	@sortExpression NVARCHAR(1000) = null 
)
AS
BEGIN
		SET NOCOUNT ON;

		DECLARE @sqlQuery NVARCHAR(MAX), @rowCount NVARCHAR(MAX);
		SELECT i.UNIQ_KEY 
		,mm.PartMfgr AS Mfgr
		,mf.QTY_OH AS 'OnHand'
		,mf.RESERVED AS 'Reserved'
		,LOCATION
		,(QTY_OH-RESERVED) AS Available
		,mf.UNIQMFGRHD
		,mm.mfgr_pt_no AS 'Mfgr_PartNo'
		,mf.UNIQWH,wh.WAREHOUSE,wh.WAREHOUSE+'/'+LOCATION  AS WHLoc
		INTO  #TEMP  
		FROM INVENTOR i 
		JOIN INVTMFGR mf ON i.UNIQ_KEY  = mf.UNIQ_KEY  AND  i.UNIQ_KEY = @uniqKey  AND mf.IS_DELETED = 0
		JOIN InvtMPNLink mpn ON mf.UNIQMFGRHD = mpn.uniqmfgrhd
		JOIN MfgrMaster mm ON mpn.MfgrMasterId = mm.MfgrMasterId AND mm.is_deleted = 0
		JOIN WAREHOUS wh ON mf.UNIQWH = wh.UNIQWH 
		WHERE wh.WAREHOUSE NOT IN ('WO-WIP','MRB','WIP')
		
		SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TEMP',@filterExpression,@sortExpression,'','Mfgr',@startRecord,@endRecord))       
		EXEC sp_executesql @rowCount  
		
		SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * from #TEMP ',@filterExpression,@sortExpression,N'Mfgr','',@startRecord,@endRecord)) 
		EXEC sp_executesql @sqlQuery

END