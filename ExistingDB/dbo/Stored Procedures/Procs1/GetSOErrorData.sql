-- ============================================================================================================    
-- Date   : 10/01/2019    
-- Author  : Mahesh B    
-- Description : Used for get Sales Order import error data for excel    
-- GetSOErrorData  '5FFAD754-5419-4CA1-BCAC-382F3F268C45'
-- ============================================================================================================    
    
CREATE PROC GetSOErrorData      
 @ImportId UNIQUEIDENTIFIER    
AS    
BEGIN    
     
SET NOCOUNT ON     
     
DECLARE @ModuleId INT,@partClassFieldDefid UNIQUEIDENTIFIER,@partTypeFieldDefid UNIQUEIDENTIFIER,@SOMainFieldName  NVARCHAR(MAX), @SOdetailFieldName NVARCHAR(MAX), @SOPriceFieldName NVARCHAR(MAX)
		,@SODuedtFieldName NVARCHAR(MAX), @SQL NVARCHAR(MAX)

SELECT @ModuleId = ModuleId from mnxmodule where ModuleName='Sales' AND FilePath = 'salesPrice' AND Abbreviation='PL'

DECLARE @SODetail TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),
							 Attention_Name VARCHAR(200), FirstName VARCHAR(100), LastName VARCHAR(100),Line_No VARCHAR(100), 
							 Location VARCHAR(100), MFGR_Part_No VARCHAR(100),Part_MFGR VARCHAR(100), 
							 Part_No VARCHAR(100), Revision VARCHAR(100), Sodet_Desc VARCHAR(100),  Warehouse VARCHAR(100))

DECLARE @SOMain TABLE  (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),Buyer VARCHAR(200),CustNo VARCHAR(100),OrderDate VARCHAR(100),SONO VARCHAR(100))   

DECLARE @SOPrice TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),Price VARCHAR(100),Qty VARCHAR(100),SaleTypeId VARCHAR(100),Taxable VARCHAR(10))

DECLARE @SODueDts TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),Commit_Dts VARCHAR(200),Due_Dts VARCHAR(100),Ship_Dts VARCHAR(100))

SELECT @SOMainFieldName = STUFF(    
      (    
			SELECT  ',[' +  F.FIELDNAME + ']' FROM   
			ImportFieldDefinitions F      
			WHERE ModuleId = @ModuleId  AND FieldName IN ('CustNo','Buyer','SONO','OrderDate')  
			ORDER BY F.FIELDNAME   
			FOR XML PATH('')    
      ),1,1,'')

SELECT @SOdetailFieldName = STUFF(    
      (    
       SELECT  ',[' +  F.FIELDNAME + ']' FROM   
       ImportFieldDefinitions F      
       WHERE ModuleId = @ModuleId AND FieldName IN ('Attention_Name','Part_No','Revision','Line_No','Sodet_Desc','Part_MFGR','MFGR_Part_No','Warehouse','Location','FirstName','LastName')  
       ORDER BY F.FIELDNAME   
       FOR XML PATH('')    
      ),    
      1,1,'')     

SELECT @SOPriceFieldName = STUFF(    
      (    
			SELECT  ',[' +  F.FIELDNAME + ']' FROM   
			ImportFieldDefinitions F      
			WHERE ModuleId = @ModuleId AND FieldName IN ('Price','Qty','SaleTypeId','Taxable')
			ORDER BY F.FIELDNAME   
			FOR XML PATH('')    
      ),    
      1,1,'')

SELECT @SODuedtFieldName = STUFF(    
      (    
		SELECT  ',[' +  F.FIELDNAME + ']' FROM   
		   ImportFieldDefinitions F      
		   WHERE ModuleId = @ModuleId AND FieldName IN ('Commit_Dts','Ship_Dts','Due_Dts')
		   ORDER BY F.FIELDNAME   
		   FOR XML PATH('') ),1,1,''
		)


---------------------------------SOMain Information ---------------------------------
 SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  (  
     SELECT so.fkImportId AS importId,so.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,so.adjusted 
	 FROM ImportFieldDefinitions fd      
     INNER JOIN ImportSOMainFields so ON so.FKFieldDefId=fd.FieldDefId
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId   
	 INNER JOIN   
	   (   
		SELECT fd.FkImportId,fd.RowId,MAX(fd.Status) as Class ,MIN(fd.Message) AS Validation		
		FROM ImportSOMainFields fd  
			INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
			INNER JOIN ImportSOUploadHeader h ON h.ImportId=fd.FkImportId
		WHERE  fd.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@SOMainFieldName,'[',''''),']','''')+')  
			GROUP BY fd.fkImportId,fd.RowId  
	   ) Sub    
   ON so.fkImportid=Sub.FkImportId AND so.RowId=Sub.RowId   
    WHERE so.fkImportId = '''+ CAST(@importId AS CHAR(36))+'''     
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @SOMainFieldName +')   
  ) AS PVT '  

 --PRINT @Sql
 INSERT INTO @SOMain EXEC SP_EXECUTESQL @SQL  
 --SELECT * FROM @SOMain

---------------------------------------SODetails Information ---------------------------------

 SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  (   SELECT so.fkImportId AS importId,ibf.RowId,sub.class AS CssClass,sub.Validation,fd.fieldName,ibf.Adjusted
	 FROM ImportFieldDefinitions fd      
     INNER JOIN ImportSODetailFields ibf ON fd.FieldDefId = ibf.FKFieldDefId 
	 INNER JOIN ImportSOMainFields so ON so.RowId=ibf.SOMainRowId
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId   
	 INNER JOIN   
	   (   
		SELECT so.fkImportId,so.RowId,MAX(fd.status) as Class ,MIN(fd.Message) AS Validation		
		FROM ImportSODetailFields fd  
			INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
			INNER JOIN ImportSOMainFields so ON so.RowId=fd.SOMainRowId
		WHERE so.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@SOdetailFieldName,'[',''''),']','''')+')  
		GROUP BY so.fkImportId,so.RowId
	   ) Sub    
   ON so.fkImportid=Sub.FkImportId AND ibf.SOMainRowId=sub.RowId   
   WHERE so.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''     
  ) st    
  PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @SOdetailFieldName +')) AS PVT '  
 
 ----PRINT @Sql
 INSERT INTO @SODetail EXEC SP_EXECUTESQL @SQL   
 --SELECT * FROM @SOMain
 --SELECT * FROM @SODetail

-------------------------------------SODueDts Information ---------------------------------

 SELECT @SQL = N'    
  SELECT PVT.*  
  FROM    
  ( SELECT isom.fkImportId AS importId,idtl.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,idts.adjusted 
	FROM ImportFieldDefinitions fd      
    INNER JOIN ImportSODueDtsFields idts ON fd.FieldDefId = idts.FKFieldDefId 
	INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId
	INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId
	INNER JOIN   
	   (   
		SELECT iso.fkImportId,fd.FKSODetailRowId,MAX(fd.Status) AS Class ,MIN(fd.Message) AS Validation		
		FROM ImportSODueDtsFields fd  
			INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
			INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId
			INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId
		WHERE iso.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@SODuedtFieldName,'[',''''),']','''')+')  
			GROUP BY iso.fkImportId,fd.FKSODetailRowId
	   ) Sub
    ON isom.fkImportid=Sub.FkImportId AND idtl.RowId=Sub.FKSODetailRowId
    WHERE isom.fkImportId =  '''+ CAST(@importId AS CHAR(36))+'''     
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @SODuedtFieldName +')   
  ) AS PVT '  
   
 --PRINT @Sql 
 INSERT INTO @SODueDts EXEC SP_EXECUTESQL @SQL 
 --SELECT * FROM @SODueDts

---------------------------------------SOPrice Information ---------------------------------

 SELECT @SQL = N'    
  SELECT PVT.*  
   FROM    
  ( SELECT isom.fkImportId AS importId,idtl.RowId,Sub.class AS CssClass,Sub.Validation,fd.fieldName,idts.adjusted 
	FROM ImportFieldDefinitions fd      
    INNER JOIN ImportSOPriceFields idts ON fd.FieldDefId = idts.FKFieldDefId 
	INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId
	INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId
	INNER JOIN   
	   (   
		SELECT iso.fkImportId,fd.FKSODetailRowId,MAX(fd.Status) AS Class ,MIN(fd.Message) AS Validation		
		FROM ImportSOPriceFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
			INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId
			INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId 
		WHERE iso.fkImportId ='''+ CAST(@importId AS CHAR(36))+'''   
			AND FieldName IN ('+REPLACE(REPLACE(@SOPriceFieldName,'[',''''),']','''')+')  
			GROUP BY iso.fkImportId,fd.FKSODetailRowId
	   ) Sub    
    ON isom.fkImportid=Sub.FkImportId AND idtl.RowId=Sub.FKSODetailRowId
    WHERE isom.fkImportId = '''+ CAST(@importId AS CHAR(36))+'''     
  ) st    
   PIVOT (MAX(adjusted) FOR fieldName'+ ' IN ('+ @SOPriceFieldName +')   
  ) AS PVT '

-- --PRINT @Sql 
 INSERT INTO @SOPrice EXEC SP_EXECUTESQL @SQL     
 --SELECT * FROM @SOPrice



 ;WITH
  SOMainImportError AS(
	SELECT ibf.fkImportId AS ImportId,ibf.RowId, idt.SONO,'' AS Part_No, fd.fieldName, ibf.Adjusted As Value, ibf.Message 
	FROM ImportFieldDefinitions fd      
		INNER JOIN ImportSOMainFields ibf ON fd.FieldDefId = ibf.FKFieldDefId AND fd.ModuleId =  @ModuleId 
		INNER JOIN ImportSOUploadHeader h ON h.ImportId = ibf.FkImportId   
		INNER JOIN   
		(   
				SELECT fkImportId,RowId 
				FROM ImportSOMainFields fd  
					INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
				WHERE fkImportId = @importId    
					AND FieldName IN ('CustNo','Contact_Name','SONO','OrderDate','Buyer')
					AND fd.Status = 'i05red'
				GROUP BY fkImportId,RowId 
				
		) Sub ON ibf.fkImportid=Sub.FkImportId and ibf.RowId=sub.RowId
		INNER JOIN @SOMain idt ON  ibf.fkImportid=idt.ImportId and idt.RowId  = sub.RowId
	WHERE ibf.Status = 'i05red'
)
,
SODetailsImportError AS(
	 SELECT so.fkImportId AS importId,ibf.SOMainRowId,TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.SONO),10)))) AS SONO,sd.Part_No AS Part_No,fd.fieldName, ibf.Adjusted As Value, ibf.Message
	 FROM ImportFieldDefinitions fd      
     INNER JOIN ImportSODetailFields ibf ON fd.FieldDefId = ibf.FKFieldDefId 
	 INNER JOIN ImportSOMainFields so ON so.RowId=ibf.SOMainRowId
     INNER JOIN ImportSOUploadHeader h ON h.ImportId = so.FkImportId   
	 INNER JOIN   
	   (   
			SELECT so.fkImportId,fd.RowId,fd.SOMainRowId,MAX(fd.status) AS Class ,MIN(fd.Message) AS Validation
			FROM ImportSODetailFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId  
				INNER JOIN ImportSOMainFields so ON so.RowId=fd.SOMainRowId
			WHERE so.fkImportId =  @ImportId AND fd.Status = 'i05red'
			GROUP BY so.fkImportId,fd.RowId,fd.SOMainRowId
	   ) Sub    
   ON so.fkImportid=Sub.FkImportId AND ibf.RowId=Sub.RowId
	INNER JOIN @SOMain sm ON sm.RowId  = sub.SOMainRowId
	INNER JOIN @SODetail sd ON sd.RowId = Sub.RowId
   WHERE ibf.Status = 'i05red'
)
,SODuedtsImportError AS(
	SELECT isom.fkImportId AS importId,idts.FKSODetailRowId,TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.SONO),10)))) AS SONO,sdt.Part_No  AS Part_No,fd.fieldName,idts.Adjusted As Value, idts.Message
	FROM ImportFieldDefinitions fd      
    INNER JOIN ImportSODueDtsFields idts ON fd.FieldDefId = idts.FKFieldDefId 
	INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId
	INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId
	INNER JOIN   
	   (   
			SELECT iso.fkImportId,fd.FKSODetailRowId,MAX(fd.Status) AS Class ,MIN(fd.Message) as Validation		
			FROM ImportSODueDtsFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
				INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId
				INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId  
			WHERE iso.fkImportId =  @ImportId AND fd.Status = 'i05red'
				AND FieldName IN ('Commit_Dts','Ship_Dts','Due_Dts')
				GROUP BY iso.fkImportId,fd.FKSODetailRowId  
	   ) Sub    
    ON isom.fkImportid=Sub.FkImportId AND idts.FKSODetailRowId=Sub.FKSODetailRowId
	INNER JOIN @SOMain sm ON  sm.RowId  = idtl.SOMainRowId
	INNER JOIN @SODueDts sd ON sd.importId = sm.importId
	INNER JOIN @SODetail sdt ON sdt.RowId=Sub.FKSODetailRowId
    WHERE idts.Status = 'i05red'
)
,SOPriceImportError AS(
	SELECT isom.fkImportId AS importId,idts.FKSODetailRowId,TRIM((TRIM(RIGHT('0000000000'+ CONVERT(VARCHAR, sm.SONO),10)))) AS SONO,sdt.Part_No  AS Part_No,fd.fieldName,idts.adjusted As Value, idts.Message
	FROM ImportFieldDefinitions fd      
    INNER JOIN ImportSOPriceFields idts ON fd.FieldDefId = idts.FKFieldDefId 
	INNER JOIN ImportSODetailFields idtl ON idtl.RowId=idts.FKSODetailRowId
	INNER JOIN ImportSOMainFields isom ON isom.RowId=idtl.SOMainRowId
	INNER JOIN   
	   (   
			SELECT iso.fkImportId,fd.FKSODetailRowId,MAX(fd.Status) AS Class ,MIN(fd.Message) AS Validation		
			FROM ImportSOPriceFields fd  
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId 
				INNER JOIN ImportSODetailFields isdt ON isdt.RowId=fd.FKSODetailRowId
				INNER JOIN ImportSOMainFields iso ON iso.RowId=isdt.SOMainRowId  
			WHERE iso.fkImportId = @ImportId  AND fd.Status = 'i05red'
				AND FieldName IN ('Price','Qty','SaleTypeId','Taxable')
				GROUP BY iso.fkImportId,fd.FKSODetailRowId  
	   ) Sub    
    ON isom.fkImportid=Sub.FkImportId AND idts.FKSODetailRowId=Sub.FKSODetailRowId
    INNER JOIN @SOMain sm ON  sm.RowId  = idtl.SOMainRowId
	INNER JOIN @SOPrice sd ON sd.importId = sm.importId
	INNER JOIN @SODetail sdt ON sdt.RowId=Sub.FKSODetailRowId
    WHERE idts.Status = 'i05red'
)

,AllError AS(
   SELECT SONO,Part_No,fieldName AS 'Field Name',Value,Message FROM SOMainImportError
  UNION	 
   SELECT SONO,Part_No,fieldName AS 'Field Name',Value,Message FROM SODetailsImportError
  UNION	  
   SELECT SONO,Part_No,fieldName AS 'Field Name',Value,Message FROM SODuedtsImportError
  UNION	  										
   SELECT SONO,Part_No,fieldName AS 'Field Name',Value,Message FROM SOPriceImportError
)
SELECT * FROM AllError 
END
