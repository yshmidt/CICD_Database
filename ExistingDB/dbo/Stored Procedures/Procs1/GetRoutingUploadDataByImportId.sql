-- =============================================
-- Author:SachinB
-- Create date: 07/15/2019
-- Description:	This SP is Used for for get WO Uploaded Data
-- 10/09/2020 Sachin B Remove the Column WorkInstruction
-- GetRoutingUploadDataByImportId '9702C442-7E26-492F-AF5D-E6E66AEA112D'
-- =============================================

CREATE PROCEDURE GetRoutingUploadDataByImportId 
@Importid UNIQUEIDENTIFIER

AS
SET NOCOUNT ON; 

-- 10/09/2020 Sachin B Remove the Column WorkInstruction
SELECT Pvt.importId,ImportTemplateId,Pvt.rowId,Pvt.partNo,Pvt.revision,Pvt.templateName,Pvt.templateType,Pvt.UniqKey ,
	Pvt.CssClass,Pvt.Validation,Pvt.RUNTIMESEC,Pvt.SERIALSTRT,pvt.DEPT_ID as deptId,pvt.SETUPSEC,pvt.NUMBER	--,pvt.WorkInstruction
FROM        
(
	SELECT ibf.fkImportId AS importId,ti.ImportTemplateId,ibf.rowId,ti.partNo,ti.revision,ti.templateName,ti.templateType,ti.uniq_Key AS UniqKey ,
	sub.class as CssClass,sub.Validation,fd.fieldName,adjusted		   
	FROM ImportFieldDefinitions fd          			
	INNER JOIN importRoutingFields ibf ON fd.FieldDefId = ibf.FKFieldDefId           
	INNER JOIN importRoutingAssemblyInfo ti ON ti.ImportTemplateId = ibf.FKImportTemplateId    
	INNER JOIN importRoutingHeader h ON h.ImportId = ti.FkImportId       
	INNER JOIN 
	(
			SELECT fkImportId,rowid,MAX(STATUS) as Class ,MIN(MESSAGE) AS VALIDATION      
			FROM importRoutingFields rf
			inner join ImportFieldDefinitions ifd on ifd.FieldDefId = rf.FKFieldDefId
			WHERE ifd.FieldName IN ('RUNTIMESEC','SERIALSTRT','DEPT_ID','SETUPSEC','NUMBER') --,'WorkInstruction'
			AND fkImportId = @Importid    
			GROUP BY fkImportId,rowid
			HAVING MAX(STATUS) <> 'i05red'
	) Sub    
	ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid        
	WHERE ibf.fkImportId = @Importid        
) st        
PIVOT (MAX(adjusted) FOR fieldName IN (RUNTIMESEC,SERIALSTRT,DEPT_ID,SETUPSEC,NUMBER)) AS PVT  --,WorkInstruction  
ORDER BY [PVT].NUMBER
	