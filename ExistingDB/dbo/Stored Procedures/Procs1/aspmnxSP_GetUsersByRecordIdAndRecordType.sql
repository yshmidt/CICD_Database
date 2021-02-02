-- =============================================
-- Author:		David Sharp
-- Create date: ???
-- Description:	
-- Modified  02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership
-- 03/07/2017 Raviraj P Rename workcenter columns to Department
-- =============================================

CREATE PROCEDURE [dbo].[aspmnxSP_GetUsersByRecordIdAndRecordType]  
 @RecordId varchar(100),  
 @RecordType varchar(50)  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    ---1. this will generate user information 
	-- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership 
 SELECT distinct U.ApplicationId,U.UserName,U.UserId,U.LoweredUserName,U.MobileAlias,U.IsAnonymous ,U.LastActivityDate,  
    M.EMAIL as emailAddress,p.FirstName,p.Initials,p.LastName ,p.ExternalEmp,  
    p.LCANNOTCHPASSWORD,p.LCHPASSWORDNEXT,p.LPASSWORDNEVEREXP,  
    p.NPASSWORDEXPIN,p.maxpasswc,p.CompanyAdmin,p.ProdAdmin,  
    p.SuperUser,p.AcctAdmin,p.homescreen,  
    p.homeapp,p.Department,-- 03/07/2017 Raviraj P Rename workcenter columns to Department
	p.dept_id,p.shift_no,p.exempt,   
    p.LastUpdatedDate,isnull(C.activeSeats,0) activeSeats   
  FROM aspnet_users U LEFT OUTER JOIN aspnet_Profile P ON U.UserId =p.UserId  
  LEFT OUTER JOIN aspnet_Membership m on u.userid=m.userid  
  OUTER APPLY (SELECT COUNT(sessionId)activeSeats from aspmnx_ActiveUsers where fkUserId = U.UserId ) C  
  inner join wmNotes n on n.fkCreatedUserId = U.UserId  
  inner join wmNoteToRecord nr on n.NoteId = nr.fkNoteId  
  WHERE nr.RecordId = @RecordId AND nr.RecordType = @RecordType AND n.IsDeleted = 0
END 