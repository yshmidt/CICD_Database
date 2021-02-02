-- =============================================
-- Author:		Vicky Lu
-- Create date: 05/28/19
-- Description:	<Gathering Cut Sheet column and data for the Bill of Material Reports>
-- =============================================
CREATE PROCEDURE GetBomDetCutSheet @lcUniqBomNo char (10), @output varchar(max) OUTPUT
AS 

BEGIN 
DECLARE @cntTotalField int, @cntTotalRecord int, @cntField int, @cntRecord int, @FieldName char(50), @Data_type char(20), @Fieldname2 char(50),
		@Udfid uniqueidentifier, @String nvarchar(max)
DECLARE @tUDTBom_DetField TABLE (Table_name char(50), Column_name char(50), Data_Type char(20), OrderNo int)
DECLARE @tUdtBom_det TABLE (UdfId char(36), nId Int Identity)
SELECT @output = ''

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'udtBOM_Details')
BEGIN
	INSERT INTO @tUdtBom_det SELECT udfid from udtBOM_Details WHERE fkUNIQBOMNO = @lcUniqBomNo
	SELECT @cntTotalRecord = @@ROWCOUNT

	-- Field information
	INSERT INTO @tUDTBom_DetField SELECT Table_name, Column_name, Data_type, Ordinal_position AS OrderNo
		FROM INFORMATION_SCHEMA.COLUMNS
		where TABLE_NAME='udtBOM_Details'
		AND ORDINAL_POSITION > 2 -- Remove udfId and fkuniqBomno, starting from 3

	SELECT @cntTotalField = @@ROWCOUNT+2
	SELECT @cntField = 2
	SELECT @cntRecord = 0
	

	IF @cntTotalRecord>0
		BEGIN
		WHILE @cntRecord < @cntTotalRecord	
			BEGIN
			SELECT @cntRecord = @cntRecord+1
			SELECT @Udfid = udfId FROM @tUdtBom_det WHERE nId = @cntRecord
			-- field
			SELECT @cntField = 2
			WHILE @cntField < @cntTotalField
				BEGIN
				SELECT @cntField= @cntField+1
				SELECT @FieldName = Column_name, @Data_type = Data_type FROM @tUDTBom_DetField WHERE OrderNo = @cntField

				SELECT @string= N'SELECT @Fieldname2 = '+
						CASE WHEN @Data_type IN ('decimal', 'numeric') THEN CONVERT(char, @Fieldname ) ELSE @Fieldname END  + ' FROM udtBOM_Details	where udfid='''+convert(nvarchar(36), @udfid)+''''

				exec SP_EXECUTESQL @query = @string
				, @params = N'@fieldname2 char(50) OUT'
				, @fieldname2 = @fieldname2 OUTPUT
			
				SELECT @output = @output + CASE WHEN @output='' THEN '' ELSE ', ' END +
					RTRIM(@FieldName)+ ': ' + RTRIM(CASE WHEN @Data_type LIKE '%date%' THEN CONVERT(char, @Fieldname2,20) ELSE @Fieldname2 END)

	
			END
		END
	END
END-- if table exist

END 
