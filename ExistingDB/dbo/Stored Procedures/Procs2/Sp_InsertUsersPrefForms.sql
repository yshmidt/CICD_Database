-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <05/09/11>
-- Description:	<Integrate with Emanex>
-- =============================================
CREATE PROCEDURE [dbo].[Sp_InsertUsersPrefForms]
	-- Add the parameters for the stored procedure here
	@lcFk_UniqUser char(10) = NULL,@lnFk_UniqForms int=NULL ,@RETURN_VALUE int=NULL OUTPUT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @lcFk_UniqUser IS NULL OR @lnFk_UniqForms IS NULL
		RETURN 0
	ELSE	
	BEGIN
    -- Insert statements for procedure here
	-- check if [FK_WebFormID] exists
		
	BEGIN TRANSACTION ;
	BEGIN TRY
		INSERT INTO [UsersPrefForms]
           ([Fk_UniqUser]
           ,[FK_WebFormID]
           ,[FormsOrder])
		SELECT Users.Uniq_user,WebFormsList.WebFormID,
			(SELECT ISNULL(MAX(FormsOrder),0) FROM [UsersPrefForms] where fk_uniqUser=@lcFk_UniqUser)+1 
		FROM Users CROSS JOIN WebFormsList 
		WHERE Users.Uniq_user=@lcFk_UniqUser
        AND WebFormsList.WebFormId=@lnFk_UniqForms ;
        SELECT @RETURN_VALUE = SCOPE_IDENTITY()
    END TRY  
    BEGIN  CATCH
		IF ERROR_NUMBER()<>2601   --- Cannot insert duplicate key row in object 'dbo.UsersPrefApps' with unique index 'UserApps'.
			-- if error 2601 we will just ignore this. Means user is trying to add an application to their list, which is already on the list.
		BEGIN
			PRINT
				 N'Error inserting record into UsersPrefApps table: '+
				  'Error Number: '+ ERROR_NUMBER()+
				  'Error Message: '+ ERROR_MESSAGE()+
				  'Error Procedure: '+ERROR_PROCEDURE()+
				  'Error Line: '+	Error_Line()+
				'Rolling back transaction.'
		END
		END CATCH ;
    -- Test XACT_STATE:
        -- If 1, the transaction is committable.
        -- If -1, the transaction is uncommittable and should 
        --     be rolled back.
        -- XACT_STATE = 0 means that there is no transaction and
        --     a commit or rollback operation would generate an error.


    -- XACT_STATE() will return -1 if there is no BEGIN TRANSACTION and 1 - if BEGIN TRANSACTION was issued
    if (XACT_STATE()) = 1
		COMMIT TRANSACTION;
	if (XACT_STATE()) = -1
		ROLLBACK TRANSACTION;	
    END       
END      
