
CREATE FUNCTION [dbo].[fn_orderedVarcharlistToTable] (@list nvarchar(MAX),@Split varchar(5)=',')
   RETURNS @tbl TABLE (colOrder int IDENTITY,id varchar(40) NOT NULL) AS
BEGIN
   IF (@list is null) OR (@list='')
	    RETURN
   ELSE	    
   --DECLARE  @Split char(1)=',', @X xml;
   DECLARE @X xml;
   SELECT @X = CONVERT(xml,'<root><s>' + REPLACE(@list,@Split,'</s><s>') + '</s></root>');
   INSERT INTO @tbl SELECT t.c.value('.','varchar(40)')
		FROM @X.nodes('/root/s') T(c)
   RETURN
END
