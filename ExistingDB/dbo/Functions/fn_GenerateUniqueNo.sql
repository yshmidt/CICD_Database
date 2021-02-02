-- =============================================
-- Author:Satish B
-- Create date: 06/27/2017
-- Description:	Used to generate uniq number of eight digit
-- Modified : 05-4-2018 : Satish B : Added parameter @keyLength to function
-- Modified : 05-4-2018 : Satish B : Set the parameter value to @Length
-- Select dbo.fn_GenerateUniqueNo(2)
-- =============================================
--05-4-2018 : Satish B : Added parameter @keyLength to function
CREATE FUNCTION dbo.[fn_GenerateUniqueNo](@keyLength int)
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
	--05-4-2018 : Satish B : Set the parameter value to @Length
    SET @Length =@keyLength --8
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