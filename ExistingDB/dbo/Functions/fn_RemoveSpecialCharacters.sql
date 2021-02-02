-- =============================================
-- Author:		David Sharp
-- Create date: 5/7/2012
-- Description:	strips special characters from a string
-- (DO NOT REMOVE SPACES)
-- =============================================
CREATE FUNCTION [dbo].[fn_RemoveSpecialCharacters] 
(@inputString varchar(MAX))
RETURNS varchar(MAX)
AS
BEGIN
	DECLARE @newString VARCHAR(MAX) 
	
	SET @newString = @inputString ; 
	With SPECIAL_CHARACTER as
	(
		SELECT '>' as item
		UNION ALL 
		SELECT '<' as item
		UNION ALL 
		SELECT '(' as item
		UNION ALL 
		SELECT ')' as item
		UNION ALL 
		SELECT '!' as item
		UNION ALL 
		SELECT '?' as item
		UNION ALL 
		SELECT '@' as item
		UNION ALL 
		SELECT '*' as item
		UNION ALL 
		SELECT '%' as item
		UNION ALL 
		SELECT '$' as item
		UNION ALL 
		SELECT '_' as item
		UNION ALL 
		SELECT '.' as item
		UNION ALL 
		SELECT '-' as item
		UNION ALL 
		SELECT '[' as item
		UNION ALL 
		SELECT ']' as item
		UNION ALL 
		SELECT '{' as item
		UNION ALL 
		SELECT '}' as item
		UNION ALL 
		SELECT '#' as item
		UNION ALL 
		SELECT '!' as item
	 )
	SELECT @newString = Replace(@newString, ITEM, '') FROM SPECIAL_CHARACTER  
	return RTRIM(LTRIM(@newString))

END
