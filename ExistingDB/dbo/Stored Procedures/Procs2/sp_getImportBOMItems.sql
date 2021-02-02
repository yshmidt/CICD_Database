-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/15/2012
-- Description:	pivots import items into an importBOM table
-- use in place of the [fn_getImportBOMItems]
-- to be able to create dynamic pivot table
-- 04/25/13 YS modiciations see comments inside the procedure
-- 10/30/13 DS added the ability to filter by row
-- 11/05/13 DS added RTRIM and LTRIM prior to pivot so it isn't needed when using the results
-- 09/07/2017 VIjay G class alises to CssClass
-- 10/04/2017 Vijay G get UseCustPFX column value.
-- =============================================
CREATE PROCEDURE [dbo].[sp_getImportBOMItems] 
	-- Add the parameters for the stored procedure here
	-- 04/25/13 YS added second parameter @lSourceFields, to use SourceFieldName in place of FieldName
	-- added third parameter @SourceTable - if not null get information for the values in a specific @sourceTable
	-- null will collect all the fields for all the tables
	--@sourceTable could have multiple tablename separated with comma, like 'Inventor,Invtmfgr'
	@importId uniqueidentifier = null,@lSourceFields bit = 0,@SourceTable varchar(50) = NULL,@getOriginal bit = 0,
	@rowId uniqueidentifier = null
	/* @lSourceFields value options
		0 = adjusted fields
		1 = alternate table field values
	*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @FieldName varchar(max),@SQL as nvarchar(max)
	
	 SELECT @FieldName =
	 STUFF(
	(
     select  ',[' +  CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END  + ']'
		from importBOMFieldDefinitions F  
		where 1=CASE WHEN @lSourceFields=0 THEN 1 
			WHEN (F.sourceFieldName=' ') THEN 0 ELSE 1 END 
			and sourceTableName = CASE WHEN @SourceTable IS NULL THEN sourceTableName
				Else @SourceTable END
		ORDER BY CASE WHEN @lSourceFields=0 THEN F.FIELDNAME ELSE F.sourceFieldName END  
		
		for xml path('')
	),
	1,1,'')
	
	--SELECT  @FieldName
	-- 04/22/13 YS added status(class) and validation to the returned list
	-- use ISNULL(ibf.adjusted,'') in place of COALESCE(ibf.adjusted,'''')adjusted ? Check with David why he had it there?
	
	SELECT @SQL = N'
	SELECT *
		FROM
		(SELECT ibf.fkImportId AS importId,ibf.rowId,ibf.uniq_key,ibf.UseCustPFX,sub.class as CssClass,sub.Validation,'+ ---Vijay G 09/07/2017  class alises to CssClass
				CASE WHEN @lSourceFields=0 THEN 'fd.fieldName' ELSE 'fd.sourceFieldName' END +', '+
				CASE WHEN @getOriginal=1 THEN 'RTRIM(LTRIM(ibf.original))AS original' ELSE 'RTRIM(LTRIM(ibf.adjusted))AS adjusted' END +
			' FROM importBOMFieldDefinitions fd INNER JOIN importBOMFields ibf ON fd.fieldDefId = ibf.fkFieldDefId
				INNER JOIN (SELECT fkImportId,rowid,MAX(status) as Class ,MIN(validation) as Validation  
					FROM importBOMFields WHERE fkImportId ='''+ cast(@importId as CHAR(36))+''' GROUP BY fkImportId,rowid) Sub
						ON ibf.fkImportid=Sub.FkImportId and ibf.rowid=sub.rowid
			WHERE ibf.fkImportId ='''+ cast(@importId as CHAR(36))+''' 
				AND 1='+ CASE WHEN NOT @rowId IS NULL THEN
					'CASE WHEN '''+ cast(@rowId as CHAR(36))+'''=ibf.rowId THEN 1 ELSE 0  END'
					ELSE '1' END+'
			) st
	PIVOT
		(
		MAX('+CASE WHEN @getOriginal=1 THEN 'original' ELSE 'adjusted' END+') FOR '+CASE WHEN @lSourceFields=0 THEN 'fieldName' ELSE 'sourceFieldName' END +' IN ('+@FieldName+')) as PVT'
		
	--SELECT @SQL
	exec sp_executesql @SQL		
END

