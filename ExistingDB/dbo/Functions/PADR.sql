

CREATE Function [dbo].[PADR] (@_String nvarchar(255),@_Len int,@_PadChar char(1)='0')
        Returns nvarchar(254)
        BEGIN
			SET @_String=LTRIM(RTRIM(@_String))+REPLICATE(@_PadChar, case when @_Len>=len(LTRIM(RTRIM(@_String))) then @_Len-len(LTRIM(RTRIM(@_String))) else 0 end )
		    RETURN @_String
        END 


