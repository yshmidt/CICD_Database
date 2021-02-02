-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/11/12
-- Description:	Use this procedure to load record from Manex Users
-- table into aspnet_users table. Users table will have fk_aspnetusers field populated 
-- and will insert information into aspnet_users with userid=fk_aspnetusers
-- will use this procedure during data upload from manex9.6.2 and call it from Dataloader
--  The field fk_aspnetusers gets populated in the mnxupd962diffapproachtosql.prg (mnxupd962tosql.exe)
-- which runs as a first step of the load process
-- will use temporary password that will have to be re-set by the admin
--- 06/13/18 YS structure changed. I am notsure we will need it. We have used it only when initial convertion from vfp users to sql
-- =============================================
CREATE PROCEDURE [dbo].[SP_UploadUsersToAspNetUsers]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    BEGIN TRANSACTION
    -- Insert statements for procedure here
    IF NOT EXISTS(SELECT ApplicationName FROM aspnet_Applications where [LoweredApplicationName]='manex')

    INSERT INTO [aspnet_Applications]
           ([ApplicationName]
           ,[LoweredApplicationName]
           ,[ApplicationId]
           ,[Description])
     VALUES
           ('ManEx'
           ,'manex'
           ,'A7162530-0345-4D6E-A4C7-9A31BF806F15'
           ,'ManEx application')
           
	INSERT INTO [aspnet_Users]
           ([ApplicationId]
           ,[UserId]
           ,[UserName]
           ,[LoweredUserName]
           ,[IsAnonymous]
           ,[LastActivityDate])
     SELECT
           'A7162530-0345-4D6E-A4C7-9A31BF806F15'
           ,Users.fk_aspnetUsers
           ,Users.[UserId] 
           ,Lower(Users.[UserId])
           ,0
           ,GETDATE() FROM Users WHERE UserID<>'ONE' and NOT fk_aspnetusers is null

	INSERT INTO [aspnet_Profile]
           ([UserId]
           ,[LastUpdatedDate]
           ,[FirstName]
           ,[LastName]
           ,[Midname]
           ,[Initials]
           ,[dept_id]
           --,[workcenter]
           ,[SuperUser]
           ,[shift_no]
           ,[exempt]
           ,[maxpasswc]
           ,[homescreen]
           ,[homeapp]
           ,[CHGWKSTWC]
           ,[LCHPASSWORDNEXT]
           ,[LCANNOTCHPASSWORD]
           ,[LPASSWORDNEVEREXP]
           ,[NPASSWORDEXPIN]
           ,[TPASSWORDENETERED]
           ,[AcctAdmin]
           ,[CompanyAdmin]
           ,[externalEmp]
           ,[ProdAdmin]
           ,[LicenseType])
		SELECT 
           Users.fk_aspnetUsers
           ,GETDATE()
           ,Users.FirstName
           ,Users.Name
           ,Users.Midname
           ,Users.Initials
           ,Users.dept_id
          -- ,Users.workcenter
           ,Users.SUPERVISOR
           ,Users.shift_no
           ,Users.exempt
           ,Users.maxpasswc
           ,Users.homescreen
           ,Users.homeapp
           ,Users.CHGWKSTWC
           ,Users.LCHPASSWORDNEXT
           ,Users.LCANNOTCHPASSWORD
           ,Users.LPASSWORDNEVEREXP
           ,Users.NPASSWORDEXPIN
           ,Users.TPASSWORDENETERED
           ,Users.LASS 
           ,Users.SUPERVISOR
           ,0
           ,Users.SUPERVISOR
           ,'full'
			FROM Users WHERE UserID<>'ONE' and NOT fk_aspnetusers is null


	INSERT INTO [aspnet_Membership]
           ([ApplicationId]
           ,[UserId]
           ,[Password]
           ,[PasswordFormat]
           ,[PasswordSalt]
           ,[Email]
           ,[LoweredEmail]
           ,[IsApproved]
           ,[IsLockedOut]
           ,LastLoginDate 
           ,LastPasswordChangedDate  
           ,LastLockoutDate 
           ,FailedPasswordAttemptCount 
           ,FailedPasswordAttemptWindowStart 
           ,FailedPasswordAnswerAttemptCount 
           ,FailedPasswordAnswerAttemptWindowStart 
           ,[CreateDate])
     SELECT
            'A7162530-0345-4D6E-A4C7-9A31BF806F15'
           ,Users.fk_aspnetUsers
           ,'V4Svf69+T2yB1rTvwrIwA/3sKqTdHvQV5IOmEFr1HH8='
           ,2
           ,'Bh5RHcuAHYgisNFuNVi9NQ=='
           ,Users.EMAILADDRESS 
           ,Lower(Users.Emailaddress)
           ,0
           ,0
           ,GETDATE()
           ,GETDATE()
           ,GETDATE()
           ,0
           ,0
           ,0
           ,0
           ,GETDATE()
           FROM USERS WHERE UserID<>'ONE' and NOT fk_aspnetusers is null

	COMMIT
END