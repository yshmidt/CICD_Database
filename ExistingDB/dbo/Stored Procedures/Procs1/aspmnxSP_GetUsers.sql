-- =============================================    
-- Author:      
-- Create date:     
-- Description: Get Users     
-- 09/15/2017 Shripati change where condition for filter user    
-- 04/12/2018 Shripati Filter user based on firstname and lastname    
-- 04/30/2018 Shripati Added condition with is null if CContact table not have record    
-- 04/30/2018 Shripati Added check usertype and user in internal or external based on that seletct users    
-- 04/02/2019 Shrikant Modify setting value to @isExternalEmp condition    
-- 02/26/2020 MaheshB added two columns for set the values to autocomplete dropdown  
-- 05/11/2020 Sachin B: Short the users data by the LastName then by FirstName
-- 10/07/2020 Sachin B: Get  p.dept_id and p.Department AS WCDept 
-- aspmnxSP_GetUsers '' , 'C'    
-- =============================================    
    
CREATE PROCEDURE [dbo].[aspmnxSP_GetUsers]     
 -- Add the parameters for the stored procedure here    
 --@UserId uniqueidentifier=' '    
 --aspmnxSP_GetUsers @userName=''    
 @userName VARCHAR(50)='',    
 @userType CHAR(1)='e'    
AS    
BEGIN    
 -- SET NOCOUNT ON added to prevent extra result sets from    
 -- interfering with SELECT statements.    
 SET NOCOUNT ON;    
    
 -- 04/30/2018 Shripati Added check usertype and user in internal or external based on that seletct users    
 DECLARE @isExternalEmp BIT = 0 ;    
 --IF @userType = 's' or @userType ='c'      
 --   BEGIN      
 -- SET @isExternalEmp = 1;      
 --   END      
 --   ELSE    
    
 -- 04/02/2019 Shrikant Modify setting value to @isExternalEmp condition    
  SET @isExternalEmp = CASE WHEN @userType = 's' or @userType ='c'  THEN  1 ELSE 0  END     
    
    -- Insert statements for procedure here    
    ---1. this will generate user information    
 -- 02/04/16 YS remove aspnet_profile.emailaddress and use email column from aspnet_membership    
 SELECT U.ApplicationId,U.UserName ,U.UserId,U.LoweredUserName,U.MobileAlias,U.IsAnonymous ,U.LastActivityDate,    
    M.EMAIL AS emailaddress,p.FirstName,p.Initials,p.LastName ,p.ExternalEmp,    
    p.LCANNOTCHPASSWORD,p.LCHPASSWORDNEXT,p.LPASSWORDNEVEREXP,    
    p.NPASSWORDEXPIN,p.maxpasswc,p.CompanyAdmin,p.ProdAdmin,    
    p.SuperUser,p.AcctAdmin,p.homescreen,    
    p.homeapp,p.Department,-- 03/07/2017 Raviraj P Rename workcenter columns to Department  
	-- 10/07/2020 Sachin B: Get  p.dept_id and p.Department AS WCDept 
    p.dept_id, CASE WHEN p.dept_id <> '' AND p.Department <> '' THEN p.dept_id + ' / ' + p.Department 
					WHEN p.dept_id <> '' THEN p.dept_id ELSE p.Department END AS WCDept,
	p.shift_no,p.exempt,     
    p.LastUpdatedDate,P.LicenseType,p.badgeCode, p.minuteLimit,ISNULL(C.activeSeats,0) activeSeats,    
    p.ScmAdmin,p.CrmAdmin,    
    cc.TYPE,    
    CASE WHEN cc.TYPE='c' THEN ccustomer.CUSTNAME     
         WHEN cc.TYPE='s' THEN s.SUPNAME END AS CompanyName,  
    U.UserName as Value,U.UserId as Id -- 02/26/2020 MaheshB added two columns for set the values to autocomplete dropdown  
  FROM aspnet_users U LEFT OUTER JOIN aspnet_Profile P ON U.UserId =p.UserId AND P.externalEmp= @isExternalEmp    
  -- 04/30/2018 Shripati Added check usertype and user in internal or external based on that seletct users    
  LEFT OUTER JOIN aspnet_Membership M ON u.userid=m.userid    
  LEFT JOIN CCONTACT cc ON U.UserId = cc.fkUserId    
  LEFT OUTER JOIN customer ccustomer ON cc.custno = ccustomer.custno    
  LEFT OUTER JOIN supinfo s ON cc.custno = s.SUPID    
  OUTER APPLY (SELECT COUNT(sessionId)activeSeats FROM aspmnx_ActiveUsers WHERE fkUserId = U.UserId ) C    
  WHERE ( UserName LIKE ''+ @userName + '%' OR P.FirstName LIKE ''+@userName+ '%' OR P.LastName LIKE ''+ @userName + '%' ) --04/12/2018 Shripati Filter user based on firstname and lastname    
  AND p.STATUS='Active' AND ((p.externalEmp = 0 AND (cc.TYPE=@userType OR cc.TYPE IS NULL)) OR (p.externalEmp = 1 AND cc.TYPE = @userType))  -- 09/15/2017 Shripati change where condition for filter user    
  -- 05/11/2020 Sachin B: Short the users data by the LastName then by FirstName
  ORDER by p.LastName,p.FirstName 
   -- 04/30/2018 Shripati Added condition with is null if CContact table not have record    
END 