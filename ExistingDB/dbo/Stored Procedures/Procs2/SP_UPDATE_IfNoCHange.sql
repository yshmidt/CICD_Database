-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <08/03/10>
-- Description:	<This stored procedure is used for updating table with row version column if record version did not change>
-- =============================================
CREATE PROCEDURE [dbo].[SP_UPDATE_IfNoCHange]
	-- Add the parameters for the stored procedure here
	@lcTable2Update as nvarchar(50),
	@lcUpdateCommand as nvarchar(max), -- update command
	@lcRecVerValue as binary(8), -- original value of the rowversion field
	@lcIdColumnName as nvarchar(30),
	@lcIdValue as char(10)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- check if rowversion has changed
	DECLARE @lcRecVer rowversion,@lcCommand nvarchar(500), @ParameterList NVARCHAR(200)
	
	SET @lcCommand='SELECT @lcRecVer= RecVer FROM '+ @lcTable2Update+' WHERE '+@lcIdColumnName+'='''+@lcIdValue+'''' 
	SET @ParameterList = '@lcRecVer rowversion OUTPUT'    
	EXEC sp_executesql @lcCommand, @ParameterList,@lcRecVer=@lcRecVer OUTPUT
	
	--SELECT @lcRecVer = RecVer from CMMAIN where CMUNIQUE = @lcIdValue
	IF @lcRecVer<>CAST(@lcRecVerValue as rowversion)
		-- -raise an error
		RAISERROR ('Update Error!. Record in the %s table with unique ID %s was modified by another user while data was manipulated. '
            ,16 -- Severity.
            ,1 -- State 
            ,@lcTable2Update -- Table Name
            ,@lcIdValue) -- Unique ID 
	ELSE
		--SET @lcExpr=N'SELECT '+@lcRevVerName +'FROM MyTable WHERE '+@lcRevVerName+'<>CAST(?@lcRevVerValue as rowversion) '+
		--' and  '+@lcKeyName+'='+@lcKeyValue
	EXEC sp_executesql @lcUpdateCommand
	
END
