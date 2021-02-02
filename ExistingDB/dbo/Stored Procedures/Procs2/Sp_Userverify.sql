-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/03/2011
-- Description:	Check for the correct password
-- =============================================
CREATE PROCEDURE [dbo].[Sp_Userverify] 
	-- Add the parameters for the stored procedure here
	@pcUserEntry varchar(10) = NULL,@pcUserId char(10)= NULL
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT USERS.*
		FROM USERS WHERE Celo=HashBytes('MD5',LTRIM(RTRIM(@pcUserEntry))) AND UserId=CASE WHEN @pcUserId IS NULL THEN USERID ELSE @pcUserId END  
END
