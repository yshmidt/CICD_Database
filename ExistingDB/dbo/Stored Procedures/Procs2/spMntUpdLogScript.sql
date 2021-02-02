-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 04/29/2013
-- Description:	Maintenance script: Update Log information
-- =============================================
CREATE PROCEDURE dbo.spMntUpdLogScript
	-- Add the parameters for the stored procedure here
	@ScriptName nvarchar(50) =null,
	@ScriptTYpe nchar(20)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF @ScriptName IS NULL
		print 'Need script name to populate information'
	else -- @ScriptName IS NULL
	BEGIN	
    -- Insert statements for procedure here
	BEGIN TRANSACTION
	INSERT INTO [UpdateScriptLog]
           ([ScriptName]
           ,[ScriptType])
     VALUES
           (@ScriptName,
           @ScriptTYpe);
	COMMIT
	END -- @ScriptName IS NULL
END
