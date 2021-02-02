-- =============================================
-- Author:		David Sharp
-- Create date: 11/9/2012
-- Description:	add system tag
-- =============================================
CREATE PROCEDURE MnxSystemTagDelete
	-- Add the parameters for the stored procedure here
	@tagName varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    DECLARE @lRollback bit=0
    BEGIN TRY  -- outside begin try
    BEGIN TRANSACTION -- wrap transaction
		/* tagName is the primary key.  tagId is just for linking */
		DECLARE @tagId char(10)
		SELECT @tagId=sTagId FROM MnxSystemTags WHERE tagName = @tagName
	    
		/* Delete all instances of that tag prior to deleting the tag */
		DELETE FROM reportTags WHERE fksTagId=@tagId
	    
		/* DELETE the tag */
		DELETE FROM MnxSystemTags WHERE tagName = tagName
	COMMIT
	
	END TRY
	BEGIN CATCH
		SET @lRollback=1
		ROLLBACK
		RETURN -1
	END CATCH
END