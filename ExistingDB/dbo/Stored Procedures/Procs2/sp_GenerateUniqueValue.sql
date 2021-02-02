
CREATE PROCEDURE [dbo].[sp_GenerateUniqueValue]
	@pcUniqNumber char(10) OUTPUT
AS
DECLARE @Length int
DECLARE @UniqueID varchar(32)
DECLARE @counter smallint
DECLARE @RandomNumber float
DECLARE @RandomNumberInt tinyint
DECLARE @CurrentCharacter varchar(1)
DECLARE @ValidCharacters varchar(255)
SET @ValidCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'
DECLARE @ValidCharactersLength int
SET @ValidCharactersLength = len(@ValidCharacters)
SET @CurrentCharacter = ''
SET @RandomNumber = 0
SET @RandomNumberInt = 0
SET @UniqueID = ''

SET NOCOUNT ON

SET @counter = 1
SET @Length = 10
WHILE @counter < (@Length + 1)

BEGIN

        SET @RandomNumber = Rand()
        SET @RandomNumberInt = Convert(tinyint, ((@ValidCharactersLength - 1) * @RandomNumber + 1))

        SELECT @CurrentCharacter = SUBSTRING(@ValidCharacters, @RandomNumberInt, 1)

        SET @counter = @counter + 1

        SET @UniqueID = @UniqueID + @CurrentCharacter

END
SET @pcUniqNumber = @UniqueID;
