-- =====================================================================================
-- Author		: Shrikant   
-- Date			: 07/15/2019			
-- Description  : MFGR Upload from template
-- EXEC UploadMFGRs @ImportId='ED177ACE-9C4F-4B32-8F5E-AE251A95252F'
-- =====================================================================================
CREATE PROC UploadMFGRs
	@ImportId UNIQUEIDENTIFIER
AS
BEGIN
	INSERT INTO SUPPORT(FIELDNAME, [TEXT],TEXT2,TEXT3,NUMBER,PREFIX,LOGIC1,UNIQFIELD,LOGIC2,IsSynchronizedFlag)
	SELECT 'PARTMFGR',pvt.[MFGRDESCRIPT],pvt.[PartMfgr],'' TEXT3,
			(ROW_NUMBER() Over(ORDER BY pvt.[PartMfgr]) + (SELECT MAX(NUMBER) FROM SUPPORT WHERE FIELDNAME = 'PARTMFGR')) NUMBER,
			'' PREFIX,0 LOGIC1,(SELECT dbo.fn_GenerateUniqueNumber()) UNIQFIELD,0 LOGIC2,0 IsSynchronizedFlag 
	FROM        
	(
		SELECT ibf.fkImportId AS importId,ibf.rowId,sub.class AS CssClass,sub.Validation,fd.fieldName,adjusted FROM ImportFieldDefinitions fd          
			INNER JOIN ImportMFGRFieldsDetail ibf ON fd.FieldName = ibf.FieldName           
			INNER JOIN ImportMFGRHeader h ON h.ImportId = ibf.FkImportId       
			INNER JOIN (
				SELECT fkImportId,rowid,MAX(status) as Class ,MIN(Message) as Validation      
					FROM ImportMFGRFieldsDetail fd WHERE   
						FieldName IN ('PartMfgr','MFGRDESCRIPT') 
					AND fkImportId = @Importid    
				GROUP BY fkImportId,rowid
				having MAX(status) <> 'i05red'
				and MAX(fd.Message) = ''
				) Sub    
		ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid        
		WHERE ibf.fkImportId = @Importid        
	) st        
	PIVOT (MAX(adjusted) FOR fieldName IN (PartMfgr,MFGRDESCRIPT)) AS PVT    
	GROUP BY [PartMfgr],[MFGRDESCRIPT]
	ORDER BY [PartMfgr],[MFGRDESCRIPT]	
END