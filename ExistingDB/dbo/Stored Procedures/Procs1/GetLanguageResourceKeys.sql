-- =============================================          
-- Author:  Raviraj P          
-- Create date: 10/26/2018          
-- Description: Get all languare resource key          
-- Added changes for ENGLISH column set ManExValue as English           
-- Added Parameter @filter And @sortExpression
-- 07/17/2019 Mahesh B : Added where clause which should not fetch empty records 
-- [GetLanguageResourceKeys] '','',1,15000          
-- =============================================          
CREATE PROCEDURE [dbo].[GetLanguageResourceKeys] (          
@filter NVARCHAR(1000) = null,          
@sortExpression NVARCHAR(1000) = null ,             
@startRecord int =1,          
@endRecord int =100         
)          
AS          
BEGIN          
 SET NOCOUNT ON;          
          
 IF OBJECT_ID('tempdb..#TempLanguage') IS NOT NULL          
 BEGIN          
  DROP TABLE #TempLanguage          
 END          
          
 DECLARE @FieldName NVARCHAR(MAX),@sqlQuery NVARCHAR(MAX),@rowCount NVARCHAR(MAX)          
          
 SELECT @FieldName = STUFF(          
 (          
     SELECT  ',[' +  REPLACE(REPLACE(REPLACE(Language, '(', ''), ')', ''),' ', '') + ']'          
  FROM MnxResourceLanguages          
  FOR XML PATH('')          
 ),          
 1,1,'')           
 SET @FieldName = REPLACE(@FieldName,'[English],','')          
          
 SELECT resKey.ResourceKeyId, resKey.ResourceKeyName,resKey.ManExValue as English,          
 resLang.Language,Translation            
 INTO #TempLanguage           
 FROM MnxResourceKey resKey          
 LEFT JOIN WmResourceTranslation resTran ON resKey.ResourceKeyId = resTran.ResourceKeyId           
 LEFT JOIN MnxResourceLanguages resLang ON resTran.LanguageId = resLang.LanguageId AND [Language] <> 'ChineseSimplified'          
 WHERE  resKey.ManExValue!=''
 ORDER BY resKey.ResourceKeyId           
    
  SET @rowCount = (SELECT dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TempLanguage PIVOT (MAX(Translation) FOR Language IN ('+@FieldName+')) P',  
  @filter,@sortExpression,'','ResourceKeyId',@startRecord,@endRecord))         
  EXEC sp_executesql @rowCount     
  
 SET @sqlQuery =  (SELECT  dbo.fn_GetDataBySortAndFilters('SELECT * FROM #TempLanguage PIVOT (MAX(Translation) FOR Language IN ('+@FieldName+')) P'          
 ,@filter,@sortExpression,N'English','',@startRecord,@endRecord))          
    
     EXEC sp_executesql @sqlQuery          
END