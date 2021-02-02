
-- =============================================
-- Author:		Shripati
-- Create date: 08/06/2017
-- Description:	Get Users with Active seats only
-- =============================================
CREATE PROCEDURE [dbo].[aspmnxSP_GetActiveSeatsUsers]
	-- Add the parameters for the stored procedure here
    @userName VARCHAR(50)='',
	@userType VARCHAR(50)=''
AS
BEGIN
		SET NOCOUNT ON;

    SELECT U.UserName,U.UserId,p.FirstName,p.Initials,p.LastName, p.LicenseType,isnull(C.ActiveSeats,0) ActiveSeats
		FROM aspnet_users U LEFT OUTER JOIN aspnet_Profile P ON U.UserId =p.UserId  
		LEFT OUTER JOIN aspnet_Membership M on u.UserId=M.UserId
		OUTER APPLY (SELECT COUNT(sessionId)ActiveSeats from aspmnx_ActiveUsers   where fkUserId = U.UserId ) C
		where  UserName like ''+@userName+ '%' and STATUS='Active' and ActiveSeats > 0
END