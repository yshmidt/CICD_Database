-- ================================================================      
-- Author:  Nitesh B        
-- Create date: 11/05/2019         
-- Description: Used to Remove Special Chars  
-- ================================================================ 
CREATE FUNCTION dbo.RemoveSpecialChars (@s VARCHAR(256)) RETURNS VARCHAR(256)
   WITH SCHEMABINDING
BEGIN
   IF @s is null
      RETURN null
   DECLARE @s2 VARCHAR(256)
   SET @s2 = ''
   DECLARE @l INT
   SET @l = len(@s)
   DECLARE @p INT
   SET @p = 1
   WHILE @p <= @l BEGIN
      DECLARE @c INT
      SET @c = ascii(substring(@s, @p, 1))
      IF @c between 32 and 32 or @c between 48 and 57 or @c between 65 and 90 or @c between 97 and 122
         SET @s2 = @s2 + CHAR(@c)
      SET @p = @p + 1
      END
   IF len(@s2) = 0
      RETURN null
   RETURN @s2
   END