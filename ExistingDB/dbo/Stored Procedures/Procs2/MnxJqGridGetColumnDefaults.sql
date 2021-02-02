-- =============================================
-- Author:		David Sharp
-- Create date: 11/29/2012
-- Description:	gets the jqGrid defaults for a list of column names
-- 11/11/13 DS  Added adtlParams columns
-- 11/16/18	DS	Added ability to format generic money and percent columns by simply adding those symbols to the column name
-- =============================================
CREATE PROCEDURE [dbo].[MnxJqGridGetColumnDefaults] 
	-- Add the parameters for the stored procedure here
	@columnNames varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @columnList Table (colOrder int,columnName varchar(200),linkedCol varchar(50))
    INSERT INTO @columnList SELECT colOrder,CAST(id as varchar(200)),'' from fn_orderedVarcharlistToTable(@columnNames,',');
     /* Added linkedCol field and populated it with the default column to use based on the included characters in the column name */
	 UPDATE @columnList 
		SET linkedCol = CASE WHEN CHARINDEX('$',columnName,1) > 0 THEN '__default$'
				WHEN CHARINDEX('%',columnName,1) > 0 THEN '__default%'
				WHEN CHARINDEX('!',columnName,1) > 0 THEN '_defaultQty'
				ELSE '' END
		FROM @columnList c
    
    /* Create a list of matched columns */
	;WITH MATCHED_COLS(colOrder,columnName,localizationKey,editable,sortable,width,align,hidden,sorttype,formatter,formatoptions,datefmt,adtlParams)
    AS
    (   
		SELECT c.colOrder,c.columnName,j.localizationKey,CAST(j.editable AS bit),CAST(j.sortable AS bit),j.width,j.align,CAST(j.hidden AS bit),j.sorttype,
				j.formatter,j.formatoptions,j.datefmt,j.adtlParams
			FROM @columnList c INNER JOIN MnxJqGridDefaults j ON c.columnName=j.fieldName 
		UNION
		SELECT c.colOrder,c.columnName,j.localizationKey,1,1,50,'right',1,'','','','',''
			FROM @columnList c INNER JOIN MnxJqGridHiddenColumns j ON c.columnName=j.fieldName 
			WHERE j.fieldName NOT IN(SELECT fieldName FROM MnxJqGridDefaults)
		UNION /* Added additional link based on default values, if the column isn't already defined */
		SELECT c.colOrder,c.columnName,c.columnName,CAST(j.editable AS bit),CAST(j.sortable AS bit),j.width,j.align,CAST(j.hidden AS bit),j.sorttype,
				j.formatter,j.formatoptions,j.datefmt,j.adtlParams
			FROM @columnList c INNER JOIN MnxJqGridDefaults j ON c.linkedCol=j.fieldName 
			WHERE c.[columnName] NOT IN (SELECT [fieldName] FROM MnxJqGridDefaults)
	)
	SELECT c.colOrder,c.columnName,j.localizationKey,CAST(j.editable AS bit)editable,CAST(j.sortable AS bit)sortable,j.width,j.align,CAST(j.hidden AS bit)hidden
			,j.sorttype,j.formatter,j.formatoptions,j.datefmt,j.adtlParams
		FROM @columnList c LEFT OUTER JOIN MATCHED_COLS j ON c.columnName=j.columnName 
	--SELECT c.colOrder,c.columnName,j.localizationKey,j.editable,j.sortable,j.width,j.align,j.hidden,j.sorttype,j.formatter,j.formatoptions 
	--		FROM @columnList c LEFT OUTER JOIN MnxJqGridDefaults j ON c.columnName=j.fieldName 
	UNION ALL
	SELECT 0,* FROM MnxJqGridDefaults WHERE fieldName LIKE '_default%'
	ORDER BY colOrder
END