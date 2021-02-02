		-- =============================================
		-- Author:		Yelena Shmidt
		-- Create date: <09/07/2011>
		-- Description:	Get Users information. Will return multiple data sets
		-- 1. User information from aspnet_users and aspnet_profiler for a given user
		-- 2. All Active Customers and those that are assigned to a given user
		-- 3. All Active Suppliers and those that are assigned to a given user
		-- 4. All Groups and those that are assigned to a given user
		-- Modified Anuj:  12/02/2014 A LanguageId is selected for getting a language id of user
		-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
		-- 03/07/2017 Raviraj P Rename workcenter columns to Department
		-- =============================================
		CREATE PROCEDURE [dbo].[aspmnxSP_GetUserInfo]
			-- Add the parameters for the stored procedure here
			@UserId uniqueidentifier=NULL
		AS
		BEGIN

			-- SET NOCOUNT ON added to prevent extra result sets from
			-- interfering with SELECT statements.
			SET NOCOUNT ON;

			IF @UserId IS NULL
				RETURN
			ELSE
			BEGIN	
			-- Insert statements for procedure here
			---1. this will generate user information
			/* 2013-05-06 DS Added the Current WC to change which WC can be used as the current.  The default WC will be used if the user has not punched in to a job */
			DECLARE @currentWC varchar(20)=null
			SELECT @currentWC=DEPT_ID FROM DEPT_CUR WHERE inUserId = @UserId AND originalDateIn = (SELECT MAX(originalDateIn) FROM DEPT_CUR WHERE inUserId = @UserId)
			-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
			SELECT U.ApplicationId,U.UserName ,U.UserId,
				U.LoweredUserName,U.MobileAlias,U.IsAnonymous ,U.LastActivityDate,p.LanguageId,/* Anuj: A LanguageId is selected for getting a language id of user on 2014-02-12*/
				  ISNULL(M.EMAIL,cast('' as nvarchar(256))) as emailaddress,p.FirstName,p.Initials,p.LastName ,p.ExternalEmp,
				  p.LCANNOTCHPASSWORD,p.LCHPASSWORDNEXT,p.LPASSWORDNEVEREXP,
				  p.NPASSWORDEXPIN,p.maxpasswc,p.CompanyAdmin,p.ProdAdmin,
				  p.SuperUser,p.AcctAdmin,p.homescreen,
				  p.homeapp,p.Department,--03/07/2017 Raviraj P Rename workcenter columns to Department
				  p.dept_id,p.shift_no,p.exempt, 
				  p.LastUpdatedDate,p.licenseType, isnull(C.activeSeats,0) activeSeats,
				  Micssys.LADDRESS1,Micssys.LADDRESS2 , Micssys.lCity,Micssys.LSTATE,mIcssys.LZIP,Micssys.LCOUNTRY,Micssys.LPHONE,Micssys.LFAX,Micssys.LIC_NAME,
				  COALESCE(CASE WHEN @currentWC = '' THEN null ELSE @currentWC END,p.dept_id)  AS currentWC
				FROM aspnet_users U LEFT OUTER JOIN aspnet_Profile P ON U.UserId =p.UserId 
				left outer join aspnet_membership M on u.userid=m.userid
				CROSS JOIN MICSSYS 
				OUTER APPLY (SELECT COUNT(sessionId)activeSeats from aspmnx_ActiveUsers where fkUserId = U.UserId ) C
				WHERE U.UserId = @UserId

			
			--5. Count of current time records open for the user
			SELECT COUNT(inUserId)active
				FROM DEPT_CUR WHERE DATE_OUT IS NULL AND inUserId=@UserId
			END
		END