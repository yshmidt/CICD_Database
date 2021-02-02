
CREATE FUNCTION dbo.[fn_GenerateUniqueNumber]()
RETURNS char(10)

AS 
BEGIN
    --DECLARE VARIABLES
    DECLARE @RandomNumber VARCHAR(10)
    DECLARE @I SMALLINT
    DECLARE @RandNumber FLOAT
    DECLARE @Position TINYINT
    DECLARE @ExtractedCharacter VARCHAR(1)
    DECLARE @ValidCharacters VARCHAR(255)
    DECLARE @VCLength INT
    DECLARE @Length INT

    --SET VARIABLES VALUE
    SET @ValidCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_'   
    SET @VCLength = LEN(@ValidCharacters)
    SET @ExtractedCharacter = ''
    SET @RandNumber = 0
    SET @Position = 0
    SET @RandomNumber = ''
    SET @Length = 10
    SET @I = 1

    WHILE @I < ( @Length + 1 )
        BEGIN
            SET @RandNumber = (SELECT RandNumber FROM [RandNumberView])
            SET @Position = CONVERT(TINYINT, ( ( @VCLength - 1 ) * @RandNumber + 1 ))
            SELECT  @ExtractedCharacter = SUBSTRING(@ValidCharacters, @Position, 1)
            SET @I = @I + 1
            SET @RandomNumber = @RandomNumber + @ExtractedCharacter
        END

    RETURN @RandomNumber
END
