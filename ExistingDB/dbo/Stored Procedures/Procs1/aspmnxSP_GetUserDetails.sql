    
-- =============================================    
-- Author: Shripati U     
-- Create date: 08/21/17     
-- Description: Get User Details    
-- 11/29/2017 Shripati :- Added the CAPAdmin column in aspnet_Profile table     
-- 4/05/2018 Shripati :- Added the Email column in selection    
-- 4/05/2018 Shripati :- Get the Username     
-- 12/19/2018 Shrikant :- selects one more column API key to display on user access setup screen    
-- 05/23/2019 Raviraj P :- Get ProjectsTasks flag  
-- =============================================    
CREATE PROCEDURE [dbo].[aspmnxSP_GetUserDetails]     
 -- Add the parameters for the stored procedure here    
 @UserId UNIQUEIDENTIFIER    
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
 SELECT U.UserId,U.UserName,P.LicenseType,CAST(CASE WHEN M.IsApproved=1 THEN 0 ELSE 1 END AS BIT) AS UserSuspended,p.NPASSWORDEXPIN AS PasswordExpireInDay,    
 p.LastUpdatedDate,     
    p.minuteLimit,U.LastActivityDate, p.AcctAdmin,p.CompanyAdmin,p.ProdAdmin,p.ScmAdmin,p.CrmAdmin,p.EngAdmin,   
    p.CAPAAdmin, -- 11/29/2017 Shripati :- Added the CAPAdmin column in aspnet_Profile table     
    M.Email , -- 4/05/2018 Shripati :- Added the Email column in selection        
    cc.TYPE,    
  -- 12/19/2018 Shrikant :- selects one more column API key to display on user access setup screen    
    P.ApiKey,  
    p.ProjectsTasks -- 05/23/2019 Raviraj P :- Get ProjectsTasks flag  
    FROM aspnet_users U     
    
  INNER JOIN aspnet_Profile P ON U.UserId =p.UserId      
  INNER JOIN aspnet_Membership M ON u.userid=m.userid    
  LEFT join CCONTACT cc ON U.UserId = cc.fkUserId    
  WHERE  U.UserId=@UserId    
END