-- =============================================
-- Author:		David Sharp
-- Create date: 8/13/2012
-- Description:	DROP a UDF table
-- 06/30/2016 Satish : Added '@section' to get section name from mnxUdfSections table
-- 06/30/2016 Satish : Added '@section' to get udf table name based on 'section' from mnxUdfSections table
-- =============================================
CREATE PROCEDURE [dbo].[UDFTableDrop] 
	-- Add the parameters for the stored procedure here
	@sectionName varchar(200)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @udfTableName varchar(200),@SQL varchar(MAX),@udfTableKeyName varchar(200),@tableName varchar(200),@section varchar(200)
	
	SELECT @tableName=mainTable FROM MnxUdfSections WHERE section=@sectionName
	-- 06/30/2016 Satish : Added '@section' to get section name from mnxUdfSections table
	SELECT @section=REPLACE(section,' ','_')FROM MnxUdfSections WHERE section=@sectionName

	SET @udfTableName = 'udf'+@section  -- 06/30/2016 Satish : Added '@section' to get udf table name based on 'section' from mnxUdfSections table
	BEGIN TRANSACTION
		SET @SQL = 'IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id= object_id(N''dbo.'+@udfTableName+''') and OBJECTPROPERTY(id,N''IsUserTable'')=1)
		DROP TABLE dbo.'+@udfTableName
		EXEC (@SQL)
	COMMIT
END