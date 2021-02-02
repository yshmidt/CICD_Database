-- =============================================
-- Author:		David Sharp
-- Create date: 11/13/2012
-- Description:	add System Tags to a group
-- =============================================
CREATE PROCEDURE dbo.aspmnx_AddTagsToGroup 
	@tagIds varchar(MAX), 
	@groupId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @tTags TABLE (tagId char(10))
    DECLARE @lRollback bit=0
    
	BEGIN TRY  /* outside begin try */
		INSERT INTO @tTags SELECT CAST(id as CHAR(10)) from fn_simpleVarcharlistToTable(@tagIds,',')
		BEGIN TRY /* inside begin try */
			DELETE FROM [dbo].aspmnx_groupSystemTags 
			WHERE	fkgroupId = @groupId AND fksTagId NOT IN (SELECT tagId FROM @tTags)
						
		END TRY
		BEGIN CATCH	
			RAISERROR('Probelm during removeing records from aspmnx_groupSystemTags table. 
			Please contact ManEx with detailed information of the action prior to this message.',11,1)
		END CATCH
		/* check if @tagIds was empty */
		IF (@tagIds<>'')
		BEGIN
			BEGIN TRY		
				INSERT INTO [dbo].aspmnx_groupSystemTags (fkgroupId,fksTagId)
					SELECT	DISTINCT @groupId, tagId
						FROM	@tTags 
						WHERE tagId NOT IN (SELECT fksTagId FROM [dbo].aspmnx_groupSystemTags WHERE fkgroupId = @groupId)
			END TRY
			BEGIN CATCH
				RAISERROR('Probelm during inserting records into aspmnx_groupSystemTags table. 
				Please contact ManEx with detailed information of the action prior to this message.',11,1)
			END CATCH	
		END
	END TRY
	BEGIN CATCH
		SET @lRollback=1
		ROLLBACK
		RETURN -1
	END CATCH
END
