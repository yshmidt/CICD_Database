
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/25/2014
-- Description:	Script to retreive schema information
-- 01/07/15 YS added parameteres for table names if only specific table information is needed and column names
-- e.g. @tableNames='PLMAIN,PLPRICES,SOPRICES,SOMAIN,CUSTOMER,INVENTOR' if left empty all tables are selected
-- e.g. @ColumnNames='Custno,Uniq_key,W_key' if left empty will find only tables that have these columns
-- =============================================
CREATE PROCEDURE [dbo].[mnxRetrieveSchema] 
@tableNames nvarchar(max)='',@columnNames nvarchar(max)	='' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select table_name,column_name,data_type from INFORMATION_SCHEMA.COLUMNS 
	WHERE (@tableNames='' OR CHARINDEX(Table_name,@tableNames)<>0) and (@columnNames='' OR charindex(column_name,@columnNames)<>0 )
	order by table_name,column_name
	-- creating pivot table 

	
	--DECLARE @SQL nvarchar(max)
	-- if you know which columns you are looking for ,
	-- the following will creat a list of files that are using one of the columns listed above

	--SET @ColumnNames='[Custno],[Uniq_key],[W_key]'

	--SELECT @SQL = N'
	--SELECT * 
	--FROM ( SELECT Table_Name,data_type,Column_name FROM INFORMATION_SCHEMA.COLUMNS)  tData  
	--PIVOT (COUNT(data_type) FOR Column_name in ('+@ColumnNames+')) tPivot' +' WHERE CUSTNO<>0 or Uniq_key<>0 or w_key<>0 '
	-- exec sp_executesql @SQL
END