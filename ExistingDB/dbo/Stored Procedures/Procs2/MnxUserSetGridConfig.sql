-- =============================================
-- Author:		David Sharp
-- Create date: 12/30/2011
-- Description:	set the users preferences on grid configuration
-- =============================================
CREATE PROCEDURE [dbo].[MnxUserSetGridConfig] 
--ALTER PROCEDURE [dbo].[user_saveGridColModel] 
	-- Add the parameters for the stored procedure here
	@userId uniqueidentifier, 
	@gridId varchar(50),
	@colModel varchar(MAX),
	@colNames varchar(MAX),
	@groupedCol varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    IF @colModel = ''
    BEGIN
		DELETE FROM wmUserGridConfig
		WHERE (userId = @userId) AND (gridId = @gridId)
    END
    ELSE
    BEGIN
		DECLARE @table AS TABLE (userId uniqueidentifier, gridId varchar(50), colModel varchar(MAX), colNames varchar(MAX), groupedCol varchar(MAX))
		DECLARE @count int
		INSERT INTO @table
		SELECT userId,gridId,colModel,colNames, groupedCol
			FROM wmUserGridConfig
			WHERE (userId = @userId) AND (gridId = @gridId)
		SET @count = @@ROWCOUNT
		IF @count = 0
			INSERT INTO wmUserGridConfig (userId,gridId,colModel,colNames,groupedCol)
				VALUES (@userId,@gridId,@colModel,@colNames, @groupedCol) 
		ELSE IF @count = 1
			UPDATE wmUserGridConfig
				SET colModel = @colModel,colNames = @colNames, groupedCol = @groupedCol
				WHERE (userId = @userId) AND (gridId = @gridId)
    END

END
