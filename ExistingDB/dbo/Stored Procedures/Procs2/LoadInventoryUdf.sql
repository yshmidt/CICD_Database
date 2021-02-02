-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03.05.2019
-- Description:	load inventory udf
-- this SP will take a name of the table created by upload
--  part_no, revision, part_sourc (provided by the user),uniq_key and part_class are always present in the provided table + UDF columns 
---
-- =============================================
CREATE PROCEDURE [dbo].[LoadInventoryUdf] 
	-- Add the parameters for the stored procedure here
	@randomTName nvarchar(20) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRY
	BEGIN TRAN

    -- Insert statements for procedure here
	declare @sqlCommandUDF nvarchar(max)  --- command to populate  uniq_key and part_class in @randomTName table
	select @sqlCommandUDF = '
	UPDATE '+@randomTName +' set part_class=Inventor.part_class,uniq_key=Inventor.Uniq_key from Inventor '+
	' where inventor.PART_NO= '+@randomTName+'.part_no and inventor.Revision =ISNULL('+@randomTName+'.Revision,'''') and '+
	'Inventor.Part_sourc='+@randomTName+'.Part_sourc'
	/*-- for test only
		select @sqlCommandUDF
	*/
	exec sp_sqlexec @sqlCommandUDF

	declare @sqlCommandUDFCursor nvarchar(max)
	/*
	 create cursor to idenify part_class of the uploaded records and which tables we have to update , 
		e.g. if the part_class='IND' the table to update udfInventor_IND
		Then we find all the fileds that are available in the udfInventor_IND and update/insert only those fileds
		!!! need to check for the type of the fields and convert if needed
	*/
	select @sqlCommandUDFCursor='
	set NOCOUNT ON ;

	declare @udfTName nvarchar(30),@part_class nvarchar(8) ,
	@FieldNameUDF nvarchar(max),
	 @fieldnameFrom nvarchar(max),
	 @FieldsUpdate nvarchar(max),
	 @sqlMerge nvarchar(max) ;'+CHAR(13)+'
	DECLARE cuUdf CURSOR LOCAL FAST_FORWARD '+CHAR(13)+'
	FOR
		select distinct ''udfInventor_''+part_class as udfTName,part_class from '+@randomTName +';'+CHAR(13)+
		' OPEN cuUdf; '+CHAR(13)+
	' FETCH NEXT FROM cuUdf INTO @udfTName,@part_class ;'+CHAR(13)+
	'WHILE @@FETCH_STATUS = 0 '+
	'BEGIN '+CHAR(13)+
		' if EXISTS(select * from sys.tables where name = @udfTName ) '+CHAR(13)+
	       ' BEGIN	'+CHAR(13)+	
				
			 'SELECT @FieldNameUDF = '+CHAR(13)+     
			' stuff((select '',['' + c.name +'']'''+CHAR(13)+
				'from sys.tables t '+CHAR(13)+
				'inner join sys.all_columns c on c.object_id=t.object_id'+CHAR(13)+
			'where t.name = @udfTName'+CHAR(13)+
			' and c.name<>''udfId'''+CHAR(13)+
			' for xml path('''')),  1, 1, '''');'+CHAR(13)+
			' SELECT @FieldNameFrom =     '+CHAR(13)+ 
			'stuff((select '',['' + c.name +'']'''+CHAR(13)+
			'	from sys.tables t '+CHAR(13)+
			'	inner join sys.all_columns c on c.object_id=t.object_id '+CHAR(13)+
			' where t.name = '''+@randomTName+''''+
			' and CHARINDEX(c.name,@fieldnameUdf)<>0    '+CHAR(13)+
			'for xml path('''')),  1, 1, '''') ;'+CHAR(13)+
			
			'SELECT @FieldsUpdate = '+CHAR(13)+     
			' stuff((select '',t.['' + c.name +'']=CASE WHEN ISNULL(s.[''+c.name +''],'''''''' ) ='''''''' THEN t.['' + c.name +''] ELSE s.[''+c.name +''] END'''+CHAR(13)+
				' from sys.tables t '+CHAR(13)+
				' inner join sys.all_columns c on c.object_id=t.object_id'+CHAR(13)+
			' where t.name ='''+@randomTName+''''+ 
			' and c.name<>''uniq_key'' and CHARINDEX(c.name,@fieldnameUdf)<>0    '+CHAR(13)+
			' for xml path('''')),  1, 1, '''') ;'+
			
			'select @sqlMerge=''MERGE ''+@udfTName+'' T ''+	'' USING (SELECT ''+@fieldnameFrom +'' FROM '+@randomTName+' where part_class=''''''+@part_class+'''''') as S  
			 ON (s.uniq_key=T.fkUniq_key )      
		 WHEN MATCHED  THEN UPDATE 
		 SET ''+@FieldsUpdate + '' WHEN NOT MATCHED BY TARGET THEN    
		INSERT (''+ @FieldNameUDF+'') VALUES (''+REPLACE(@fieldnameUDF,''fkuniq_key'',''uniq_key'')+'');'''+
		'exec sp_sqlexec @sqlMerge;'+
		' FETCH NEXT FROM cuUdf INTO @udfTName,@part_class ;'+
	 ' END 
	 END '+
	'CLOSE cuUdf;'+
	'DEALLOCATE cuUdf;'
	/* for test only
		select @sqlCommandUDFCursor
    */
	exec sp_sqlexec @sqlCommandUDFCursor
	IF @@TRANCOUNT>0
	COMMIT
	exec spMntUpdLogScript 'LoadInventoryUdf','SP Load'
END TRY
BEGIN CATCH
	IF @@TRANCOUNT>0
	ROLLBACK
	SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

END CATCH
END