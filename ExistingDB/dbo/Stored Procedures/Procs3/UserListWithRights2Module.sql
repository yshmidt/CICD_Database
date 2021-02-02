
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <07/06/2011>
-- Description:	<Get all users that have rights to a given module (screen) including SuprUser>
-- =============================================
CREATE PROCEDURE [dbo].[UserListWithRights2Module]
	-- Add the parameters for the stored procedure here
	@pnScreenUniqueNum int=0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Name, FirstName, Users.UserID, Initials,Uniq_User 
	 FROM Users 
	 WHERE Users.SuperVisor=1  
	UNION 
	SELECT Name, FirstName, Users.UserID, Initials,Uniq_User 
		 FROM Users, Rights 
		WHERE Users.Uniq_User = Rights.FK_uniqUser  
		AND Users.SuperVisor = 0
		AND Rights.Fk_Uniquenum  = @pnScreenUniqueNum 
		AND (Rights.Sedit = 1
		OR Rights.SAdd = 1
		OR Rights.SDelete =1 )
	
END

