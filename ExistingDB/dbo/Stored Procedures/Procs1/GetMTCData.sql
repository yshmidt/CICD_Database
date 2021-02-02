  -- ============================================================================================================  
-- Date   : 12/18/2019  
-- Author  : Rajendra K 
-- Description : Used for get MTC upload data  
-- GetMTCData 'FAE77BDF-1ED2-4BCD-BDEA-630B29FB4CF0' 
-- ============================================================================================================    
CREATE PROC GetMTCData 
 @ImportId UNIQUEIDENTIFIER
AS  
SET NOCOUNT ON      
BEGIN
  SELECT importId,AssemblyRowId,CompRowId,AvlRowId,LotRowId,MTCRowId,MTC.*,ResQty,MTC
  FROM    
  (   
	SELECT DISTINCT fd.FkImportId AS importId,fd.AssemblyRowId,ic.CompRowId,ia.AvlRowId,il.LotRowId,mt.MTCRowId,mt.status ,mt.Message,ibf.fieldName,mt.Adjusted 
	FROM ImportBOMToKitAssemly fd  
		INNER JOIN ImportBOMToKitComponents ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
		INNER JOIN ImportBOMToKitAvls ia ON ic.CompRowId = ia.FKCompRowId
		INNER JOIN ImportBOMToKitMTC mt ON mt.FKAvlRowId = ia.AvlRowId
		LEFT JOIN ImportBOMToKitLot il ON il.LotRowId = mt.FkLotRowId
		INNER JOIN ImportFieldDefinitions ibf ON mt.FKFieldDefId = ibf.FieldDefId  
	WHERE fkImportId = @ImportId
		AND FieldName IN ('ResQty','MTC') 
	) st    
   PIVOT (MAX(Adjusted) FOR fieldName IN ([ResQty],[MTC])  
  ) as PVT
  OUTER APPLY
  (
		SELECT MAX(Status) CssClass,MIN(Message) Validation FROM ImportBOMToKitMTC where  MTCRowId = PVT.MTCRowId GROUP BY MTCRowId
  ) AS MTC
END