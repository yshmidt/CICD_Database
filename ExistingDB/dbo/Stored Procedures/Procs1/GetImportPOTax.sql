-- =============================================
-- Author:		Satish B
-- Create date:  6/15/2018
-- Description:	Pivots import items into an import PO tax table
-- exec GetImportPOTax '1172A7AC-5A8E-4817-94F0-D66B2B9FB514','6238',null
-- =============================================
CREATE PROCEDURE [dbo].[GetImportPOTax] 
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier = null
   ,@moduleId char(10) = ''
   ,@rowId uniqueidentifier = null
   ,@lSourceFields bit = 0
   ,@sourceTable varchar(50) = NULL
   ,@getOriginal bit = 0
   
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @FieldName varchar(max),@SQL as nvarchar(max)
	SELECT @FieldName =
	 STUFF(
	(
     SELECT  ',[' +  CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END  + ']'
		FROM ImportFieldDefinitions F  
		WHERE 1=CASE WHEN @lSourceFields=0 THEN 1 
					 WHEN (F.sourceFieldName=' ') THEN 0 ELSE 1 END 
				AND sourceTableName = CASE WHEN @sourceTable IS NULL THEN sourceTableName Else @sourceTable END 
				AND f.moduleId=@moduleId AND f.FieldName IN('TAXID')
		ORDER BY CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END  
		FOR XML PATH('')
	),
	1,1,'')
	
	SELECT *
		FROM
		(SELECT ipt.fkPOImportId AS ImportId,ipt.fkRowId,sub.class AS CssClass,sub.Validation,ISNULL(t.TAXDESC,'') AS TaxDescription,ISNULL(t.TAX_RATE,0) AS TaxRate,pfd.fieldName, RTRIM(LTRIM(ipt.adjusted))AS adjusted FROM ImportFieldDefinitions pfd INNER JOIN 
ImportPOTax ipt ON pfd.FieldDefId = ipt.fkFieldDefId
				INNER JOIN (SELECT fkPOImportId,fkRowId,MAX(status) as Class ,MIN(validation) as Validation  
					FROM ImportPOTax WHERE fkPOImportId =@importId GROUP BY fkPOImportId,fkRowId) Sub
						ON ipt.fkPOImportId=Sub.fkPOImportId and ipt.fkRowId=sub.fkRowId
                LEFT JOIN TAXTABL t on t.TAX_ID=ipt.adjusted
			WHERE ipt.fkPOImportId =@importId 
						 AND (@rowId  IS NULL OR ipt.fkRowId = @rowId)
			) st
	PIVOT
		(
		MAX(adjusted) FOR fieldName IN ([TAXID])) as PVT
END

