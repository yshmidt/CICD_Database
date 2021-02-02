-- ============================================================================================================  
-- Date   : 08/26/2019  
-- Author  : Rajendra K 
-- Description : Used for get Work order upload data  
-- GetWorkOrderData 'EC1C1293-FB2A-480A-8F45-F0846D35BFC4'    
-- ============================================================================================================    
CREATE PROC GetWorkOrderData  
 @ImportId UNIQUEIDENTIFIER  
AS 
SET NOCOUNT ON   
 
BEGIN  
;WITH  WOData AS (  
  SELECT PVT.*  
  FROM    
  (   
	  SELECT ibf.fkImportId AS importId,ic.WORowId,ibf.AssemblyRowId,sub.class as CssClass,sub.Validation,fd.fieldName,ic.Adjusted 
	  FROM ImportFieldDefinitions fd      
		 INNER JOIN ImportBOMToKitWorkOrder ic ON fd.FieldDefId = ic.FKFieldDefId
	    INNER JOIN ImportBOMToKitAssemly ibf ON ic.FKAssemblyRowId = ibf.AssemblyRowId
	    INNER JOIN ImportBOMToKitHeader h ON h.ImportId = ibf.FkImportId     
		 INNER JOIN   
		   (   
				SELECT fkImportId,WORowId,AssemblyRowId,MAX(ic.status) as Class ,MAX(ic.Message) as Validation		
				FROM ImportBOMToKitAssemly fd  
					INNER JOIN ImportBOMToKitWorkOrder ic ON fd.AssemblyRowId = ic.FKAssemblyRowId
					INNER JOIN ImportFieldDefinitions ibf ON ic.FKFieldDefId = ibf.FieldDefId   
				WHERE fkImportId =@ImportId   
					AND FieldName IN ('bldqty','Due_date','End_date','JobType','kitDefWarehouse','Line_no','OrderDate','PRJNUMBER','PRJUNIQUE','RELEDATE',
										'RoutingName','SONO','Start_date','wono','Wonote')     
				GROUP BY fkImportId,WORowId,AssemblyRowId 
		   ) Sub    
	  ON ibf.fkImportid=Sub.FkImportId and ic.WORowId = sub.WORowId AND ic.FKAssemblyRowId = sub.AssemblyRowId 
	  WHERE ibf.fkImportId = @ImportId 
  ) st    
  PIVOT (MAX(adjusted) FOR fieldName IN ([bldqty],[Due_date],[End_date],[JobType],[kitDefWarehouse],[Line_no],[OrderDate],[PRJNUMBER],[PRJUNIQUE],[RELEDATE],
			[RoutingName],[SONO],[Start_date],[wono],[Wonote])   
) as PVT 
)
	SELECT importId
			,AssemblyRowId
			,WORowId
			,CAST(bldqty as decimal) as BldQty
			,CAST(Due_date AS DATETIME) AS Due_date
			,CAST(End_date AS DATETIME) AS End_date
			,CAST(OrderDate AS DATETIME) AS OrderDate
			,CAST(Start_date AS DATETIME) AS Start_date 
			,CAST(RELEDATE AS DATETIME) AS RELEDATE
			,JobType
			,kitDefWarehouse
			,Line_no
			,PRJNUMBER
			,PRJUNIQUE
			,RoutingName
			,SONO
			,wono
			,Wonote
			,CssClass
			,Validation
	FROM WOData
END