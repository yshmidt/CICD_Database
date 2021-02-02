-- =============================================
-- Author:		Sachin B
-- Create date: <11/07/2016>
-- Description:	Get basic information for all Users.
-- 04/08/2017 Sachin B Change column name for select from WorkCenter to Department as WorkCenter column is rename in aspnet_Profile by Department
-- =============================================
CREATE PROCEDURE [dbo].[GetAllUsersBasicInfo]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT U.ApplicationId,U.UserName,U.UserId,U.LoweredUserName,U.MobileAlias,U.IsAnonymous ,U.LastActivityDate,
		  M.EMAIL as emailaddress,p.FirstName,p.Initials,p.LastName ,p.ExternalEmp,
		  p.LCANNOTCHPASSWORD,p.LCHPASSWORDNEXT,p.LPASSWORDNEVEREXP,
		  p.NPASSWORDEXPIN,p.maxpasswc,p.CompanyAdmin,p.ProdAdmin,
		  p.SuperUser,p.AcctAdmin,p.homescreen,
		  p.homeapp,p.Department,p.dept_id,p.shift_no,p.exempt, 
		  p.LastUpdatedDate,isnull(C.activeSeats,0) activeSeats	
		FROM aspnet_users U 
		LEFT OUTER JOIN aspnet_Profile P ON U.UserId =p.UserId  
		LEFT OUTER JOIN aspnet_Membership M on u.userid=m.userid
		OUTER APPLY (SELECT COUNT(sessionId)activeSeats from aspmnx_ActiveUsers where fkUserId = U.UserId ) C
		where Initials !=''
END