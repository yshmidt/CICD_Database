-- =============================================
-- Author:		David Sharp
-- Create date: 11/15/2011
-- Description:	converts role codes, to full role names
-- =============================================
CREATE FUNCTION [dbo].[fn_convertToRoleNames] (@roleCodes varchar(MAX))
	RETURNS @fullRoles TABLE (roleName varchar(50)) AS
BEGIN 
	IF (@roleCodes is null) OR (@roleCodes='')
	    RETURN
	ELSE	    
	DECLARE @tbl TABLE (roleRoot varchar(50) NOT NULL)
	DECLARE @roleCode varchar(100)
	
	DECLARE @Split char(1)=',', @X xml;
	SELECT @X = CONVERT(xml,'<root><s>' + REPLACE(@roleCodes,@Split,'</s><s>') + '</s></root>');
	INSERT INTO @tbl SELECT t.c.value('.','varchar(40)')
		FROM @X.nodes('/root/s') T(c)
		
	BEGIN
		DECLARE rt_cursor CURSOR LOCAL FAST_FORWARD
		FOR
		SELECT		roleRoot
		FROM		@tbl 
		OPEN		rt_cursor
	END

	FETCH NEXT FROM rt_cursor INTO @roleCode
	
    WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @roleCodeLength int = LEN(@roleCode)
		DECLARE @startChar int = CHARINDEX('_',@roleCode,0)
		DECLARE @roleCore varchar(10) = SUBSTRING(@roleCode,1,@startChar)
		DECLARE @nextChar varchar(1)
		WHILE @startChar < @roleCodeLength
		BEGIN
			SET @nextChar = SUBSTRING(@roleCode,@startChar+1,1)
			IF @nextChar = '*'
			BEGIN
				INSERT INTO @fullRoles SELECT @roleCore + 'View' 
				INSERT INTO @fullRoles SELECT @roleCore + 'Add'
				INSERT INTO @fullRoles SELECT @roleCore + 'Edit'
				INSERT INTO @fullRoles SELECT @roleCore + 'Delete'
				INSERT INTO @fullRoles SELECT @roleCore + 'Reports'
				
				SET @startChar = @roleCodeLength
			END
			ELSE
			BEGIN
				INSERT INTO @fullRoles
				SELECT @roleCore + CASE 
					WHEN @nextChar = 'V' THEN 'View' 
					WHEN @nextChar = 'A' THEN 'Add'
					WHEN @nextChar = 'E' THEN 'Edit'
					WHEN @nextChar = 'D' THEN 'Delete'
					WHEN @nextChar = 'R' THEN 'Reports' END
				
				SET @startChar = @startChar +1
			END
		END

		FETCH NEXT FROM rt_cursor INTO @roleCode
	END
	 
	CLOSE rt_cursor
	DEALLOCATE rt_cursor

	RETURN
END
