
CREATE FUNCTION [dbo].[fn_simpleVarcharlistToTable] (@list nvarchar(MAX),@Split varchar(5)=',')
   RETURNS @tbl TABLE (id varchar(MAX) NOT NULL) AS
BEGIN
   IF (@list is null) OR (@list='')
	    RETURN
   ELSE	    
   --DECLARE  @Split char(1)=',', @X xml;
   DECLARE @X xml;
  
  -- 11/01/13 YS change code in case the value of the @list is 'T&B      L-5-30-9-M,NAT-FAIR MM74HC14M' 
  -- '&' is xml special character and will generate an error the way this code is working
  -- SELECT @X = CONVERT(xml,'<root><s>' + REPLACE(@list,@Split,'</s><s>') + '</s></root>');
  -- INSERT INTO @tbl SELECT t.c.value('.','varchar(MAX)')
		--FROM @X.nodes('/root/s') T(c)
	select @X= convert(xml,replace(convert(varchar(max),(Select @list
				FOR XML PATH('s'),root('root'))),@Split,'</s><s>'))	
    INSERT INTO @tbl  SELECT t.c.value('.','varchar(MAX)')
		FROM @X.nodes('/root/s') T(c)
				
   RETURN
END
