CREATE FUNCTION [dbo].[fn_XMLgetColNames] 
(
	@xml xml,
	@fixedOrder bit=1 --If true, then only the first node is checked for names.
)
   RETURNS VARCHAR(MAX) AS
BEGIN
	DECLARE @colNames varchar(MAX),@firstNode xml
	
	IF (@xml is null)
		RETURN ''
	ELSE	    
		IF @fixedOrder=1
		BEGIN
			SELECT top 1 @firstNode = a.c.query('.')
				FROM @xml.nodes('*') a(c)
			SELECT 	@colNames = COALESCE(@colNames + ',','') + a.c.value('local-name(.)', 'VARCHAR(50)')
				FROM @firstNode.nodes('*/*') a(c)
		END
		ELSE
		BEGIN
			SELECT 	@colNames = COALESCE(@colNames + ',','') + secondNodeNames
				FROM(SELECT DISTINCT a.c.value('local-name(.)', 'VARCHAR(50)') AS secondNodeNames
						FROM @xml.nodes('*/*') a(c))x
		END
		RETURN @colNames
END
