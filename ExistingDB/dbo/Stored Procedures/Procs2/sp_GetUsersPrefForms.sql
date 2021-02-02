-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <05/09/2011>
-- Description:	<Integrate with new age project>
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetUsersPrefForms] 
	-- Add the parameters for the stored procedure here
	@lcFk_UniqUser char(10) = NULL,@lcUniqApp int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- if the second parameter (@lcUniqApp) is not provided return list of the forms saved for a user
	-- if @lcUniqApp is provided return only forms assigned to the provided application
    -- Insert statements for procedure here
	SELECT Users.USERID,
      WebFormslist.WebFormURL ,
      WebFormsList.WebFormName ,
      Usersprefforms.FormsOrder ,
      Usersprefforms.Fk_UniqUser ,
      UsersPrefForms.Fk_WebFormId,
      UsersPrefForms.UniqueUPFA
      FROM [dbo].[UsersPrefForms] INNER JOIN dbo.USERS ON Usersprefforms.Fk_UniqUser=USERS.UNIQ_USER 
		INNER JOIN WebFormsList ON Usersprefforms.[Fk_WebFormId]=WebFormsList.WebFormid 
		WHERE USERS.uniq_user = @lcFk_UniqUser
		AND WebFormsList.FK_uniqApp=CASE WHEN @lcUniqApp IS NULL THEN WebFormsList.FK_uniqApp ELSE @lcUniqApp END
		
		
END
