

CREATE FUNCTION [dbo].[fn_selectToHtmlTable] (@columNames varchar(MAX),@select selectToHtmlType READONLY)
	RETURNS varchar(MAX) AS
	BEGIN
	DECLARE @htmlTable varchar(max) = '',@c1 varchar(MAX),@c2 varchar(MAX)='',
		@c3 varchar(MAX)='',@c4 varchar(MAX)='',@c5 varchar(MAX)='',@c6 varchar(MAX)='',
		@c7 varchar(MAX)='',@c8 varchar(MAX)='',@c9 varchar(MAX)=''
	
	SELECT @c1=c1 FROM @select
	IF (@c1 is null) OR (@c1='')
		RETURN @htmlTable
	ELSE
	BEGIN	    
		DECLARE  @thead varchar(max) = '<style type="text/css">td{padding-right:20px;}</style><table padding={pad} border="{border}"><tr><th>'+ REPLACE(@columNames,',','</th><th>') + '</th></tr>',@tRows varchar(MAX)='',@id int,@tt varchar(MAX)='' 
		BEGIN    
			DECLARE rt_cursor CURSOR LOCAL FAST_FORWARD
			FOR
			SELECT 		id
				FROM		@select
			OPEN		rt_cursor; 
		END
		FETCH NEXT FROM rt_cursor INTO @id

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @c1=c1,@c2=c2,@c3=c3,@c4=c4,@c5=c5 FROM @select WHERE id=@id
			
			--SET @tt += '<tr><td>'+CAST(COALESCE(@c1,'')as varchar(MAX))
			SET @tRows = ISNULL(CAST(@tRows AS VARCHAR(MAX)), '')+'<tr><td>'+
				 CAST(RTRIM(COALESCE(@c1,''))as varchar(MAX))+'</td><td>'+
				CAST(RTRIM(COALESCE(@c2,''))as varchar(MAX))+'</td><td>'+
				CASE WHEN @c3 = '' THEN '' ELSE CAST(RTRIM(COALESCE(@c3,''))as varchar(MAX))+'</td><td>' END +
				CASE WHEN @c4 = '' THEN '' ELSE CAST(RTRIM(COALESCE(@c4,''))as varchar(MAX))+'</td><td>' END+
				CASE WHEN @c5 = '' THEN '' ELSE CAST(RTRIM(COALESCE(@c5,''))as varchar(MAX))+'</td><td>' END+
				CASE WHEN @c6 = '' THEN '' ELSE CAST(RTRIM(COALESCE(@c6,''))as varchar(MAX))+'</td><td>' END+
				CASE WHEN @c7 = '' THEN '' ELSE CAST(RTRIM(COALESCE(@c7,''))as varchar(MAX))+'</td><td>' END+
				CASE WHEN @c8 = '' THEN '' ELSE CAST(RTRIM(COALESCE(@c8,''))as varchar(MAX))+'</td><td>' END+
				CASE WHEN @c9 = '' THEN '' ELSE CAST(RTRIM(COALESCE(@c9,''))as varchar(MAX))+'</td></tr>' END
			--SET @tt = @tRows
			--SET @tRows = @tRows + '<tr><td>'+COALESCE(@c1,'')+'</td><td>'+COALESCE(@c3,'')+'</td><td>'+COALESCE(@c5,'')+'</td></tr>'
			FETCH NEXT FROM rt_cursor INTO @id
		END
		CLOSE rt_cursor
		DEALLOCATE rt_cursor
		
		SET @htmlTable = @thead + @tRows + '</table>'
	END
	
	RETURN @htmlTable
END

