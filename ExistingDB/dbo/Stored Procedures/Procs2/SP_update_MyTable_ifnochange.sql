-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.SP_update_MyTable_ifnochange
	-- Add the parameters for the stored procedure here
	@lcUpdateCommand as nvarchar(500), -- update command
	@lcRecVerValue as binary(8), -- original value of the rowversion field
	@lcIdValue as int
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- check if rowversion has changed
	DECLARE @lcRecVer binary(8)
	SELECT @lcRecVer= RecVer FROm MyTable WHERE nId=@lcIdValue 
	IF @lcRecVer<>CAST(@lcRecVerValue as rowversion)
		-- -raise an error
		RAISERROR ('error changing row with nid = %d'
            ,16 -- Severity.
            ,1 -- State 
            ,1) -- myKey that was changed 
	ELSE
		--SET @lcExpr=N'SELECT '+@lcRevVerName +'FROM MyTable WHERE '+@lcRevVerName+'<>CAST(?@lcRevVerValue as rowversion) '+
		--' and  '+@lcKeyName+'='+@lcKeyValue
	EXEC sp_executesql @lcUpdateCommand
	
END

