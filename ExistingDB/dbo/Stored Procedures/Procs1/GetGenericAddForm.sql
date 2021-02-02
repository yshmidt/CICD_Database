-- =============================================
-- Author: Shivshankar Patil	
-- Create date: <02/26/16>
-- Description:	<For Getting generic form data> 
-- =============================================
CREATE PROCEDURE [dbo].[GetGenericAddForm] 
	-- Add the parameters for the stored procedure here
	@formName nvarchar(200), --Generic add form name
	@tableName nvarchar(200) = null , --Table Name
    @uniqueId nvarchar(200) = null  --Table unique Column Name


	
AS
BEGIN
	SET NOCOUNT ON;
		DECLARE @SQL nvarchar(MAX),@edtiTableRecod varchar(50),@tableUniqueColumn nvarchar(200)
		--Declare #TempTable table(name varchar(200))
			   
			    select  gc.* ,mps.dataSource,mps.sourceType ,gt.tableName,gt.tableUniqueCol ,gt.tableUniqueColType 
				into #GenericAddTempData  from  mnxGenericForm gf 
				Inner join  mnxGenericFormTables gt on gf.GenericFormId = gt.fkGenericFormId 
				Inner join mnxGenericFormColumns gc on gf.GenericFormId = gt.fkGenericFormId 
			    LEFT OUTER JOIN  mnxGenericFormDataSource gtd 
				on gc.FieldId = gtd.fkFormColumnId  
				LEFT OUTER JOIN MnxParamSources mps on gtd.dataSourceName = mps.sourceName
				WHERE gc.fkFormId =gf.GenericFormId and gc.fkTableId =gt.FormTableId and gf.formName = @formName
			    select *  from #GenericAddTempData 

                -- @uniqueId exit add form open in edit mode
			   IF (@uniqueId  IS NOT NULL  AND @uniqueId <> '') 
			   BEGIN
			   SET @tableUniqueColumn =  (select top 1 tableUniqueCol  from #GenericAddTempData)
			   SET @SQL = 'SELECT * FROM dbo.'+ @tableName +' WHERE ' +@tableUniqueColumn + '=''' +  @uniqueId + ''''
			    EXEC(@SQL)
			   END

			  
END