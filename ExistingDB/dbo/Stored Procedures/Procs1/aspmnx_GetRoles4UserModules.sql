-- =============================================
-- Author:		Shripati
-- Create date: 07/06/2017 
-- Description:	Get roles for user modules
-- 09/19/2017 Sachin B Convert MOM to MOC
-- 12/18/2017 Shripati U :- Get the special roles of user 
-- 12/20/2017 Shripati U :- External API Authorization 
-- 05/25/2018 Raviraj P Convert ACCT to ACCTG
-- 06/18/2018 Raviraj P Convert MOC to MES
-- 11/14/2018 Shrikant B add Temp Table And Remove the unAssigned Permissions
-- 04/19/2019 Raviraj P Convert ACCTG to S,G&A
-- 06/25/2019 Mahesh B Added new ENG Menu 
-- 12/24/2019 Sachin Convert S,G&A to SGA  
-- 10/08/20achin B Convert MES to MFG
-- aspmnx_GetRoles4UserModules 'dc77b909-9b1c-4d71-9373-5ef085ded1ea',47
-- =============================================
CREATE PROCEDURE [dbo].[aspmnx_GetRoles4UserModules]

@userId uniqueidentifier , 
@moduleId int = null,
@parentModule varchar(100) = ' ',
@childModule varchar(100) = ' '

As
	SET NOCOUNT ON;
BEGIN

 -- 12/20/2017 Shripati U :- External API Authorization 
 IF(@moduleId IS NULL)
 BEGIN
    SELECT  @moduleId =ModuleId FROM Mnxmodule m  
   INNER JOIN MnxModuleRelationship mr ON m.moduleid = mr.childid 
                   AND (((@childModule IS NOT NULL OR @childModule  <> '')  AND  m.ModuleName= @childModule) 
				   OR  ((@childModule IS NULL OR @childModule ='') AND m.ModuleName=m.ModuleName))

   AND MR.PARENTID = (SELECT moduleid FROM MnxModule mm 
      WHERE  (((@parentModule IS NOT NULL OR @parentModule <> '') AND  mm.ModuleName =@parentModule) 
	  OR (@parentModule IS  NULL OR @parentModule = '') AND  mm.ModuleName =mm.ModuleName)) 
   END

DECLARE @ModuleName NVARCHAR(MAX)=''
;WITH items AS (      
    SELECT relationship.ParentId, 1 AS Level 
    FROM MnxModuleRelationship relationship JOIN MnxModule module on module.ModuleId = relationship.ParentId    
    WHERE  ChildId = @moduleId 
    UNION ALL    
    SELECT i.ParentId, Level+1 AS Level
    FROM MnxModuleRelationship i JOIN MnxModule module on module.ModuleId = i.ParentId  
    INNER JOIN items itms ON itms.ParentId = i.ChildId 
)      
SELECT TOP 1 @ModuleName=ModuleName FROM items i INNER JOIN MnxModule m on i.ParentId=m.ModuleId ORDER BY Level desc

-- 11/14/2018 Shrikant B add Temp Table And Remove the unAssigned Permissions
;with TempData as(SELECT RoleName,
	ISNULL(CASE WHEN p.CompanyAdmin=1 THEN p.CompanyAdmin
	-- 05/25/2018 Raviraj P Convert ACCT to ACCTG
  -- 04/19/2019 Raviraj P Convert ACCTG to S,G&A   
  -- 12/24/2019 Sachin Convert S,G&A to SGA  
 WHEN @ModuleName='SGA' THEN CASE WHEN p.AcctAdmin=1 THEN p.AcctAdmin ELSE Z.Assigned END    
	WHEN @ModuleName='SALES' THEN CASE WHEN ISNULL(p.CrmAdmin,0)=1 THEN ISNULL(p.AcctAdmin,0) ELSE Z.Assigned END
	-- 09/19/2017 Sachin B Convert MOM to MOC
	-- 06/18/2018 Raviraj P Convert MOC to MES
	-- 10/08/20achin B Convert MES to MFG
	WHEN @ModuleName='MFG' THEN CASE WHEN p.ProdAdmin=1 THEN p.ProdAdmin ELSE Z.Assigned END
	-- 06/25/2019 Mahesh B Added new ENG Menu 
	WHEN @ModuleName='ENG' THEN CASE WHEN p.EngAdmin=1 THEN p.EngAdmin ELSE Z.Assigned END    
	WHEN @ModuleName='SCM' THEN CASE WHEN ISNULL(p.ScmAdmin,0)=1 THEN ISNULL(p.ScmAdmin,0) ELSE Z.Assigned END
	ELSE Z.Assigned END,0) Assigned
	FROM aspnet_Roles ar
	INNER JOIN aspnet_Users u on u.UserId=@Userid
	INNER JOIN aspnet_Profile p on p.UserId=u.UserId
	LEFT JOIN aspmnx_groupUsers gu on gu.fkuserid = u.UserId  
	OUTER APPLY (SELECT CAST(1 as bit) as Assigned FROM aspmnx_GroupRoles gr WHERE fkGroupId = gu.fkGroupId AND fkRoleId =ar.roleId) AS Z 
	WHERE ar.ModuleId =@moduleId 
	UNION -- 12/18/2017 Shripati U :- Get the special Roles of user 
    SELECT  RoleName, Assigned FROM  aspnet_Roles ar
	INNER JOIN aspnet_Users u ON u.UserId=@Userid
	INNER JOIN aspnet_Profile p ON p.UserId=u.UserId
	LEFT JOIN aspmnx_groupUsers gu ON gu.fkuserid = u.UserId  
	OUTER  APPLY (SELECT CAST(1 AS BIT) as Assigned FROM aspmnx_GroupRoles gr WHERE fkGroupId = gu.fkGroupId AND fkRoleId =ar.roleId) AS Z
	WHERE  ar.IsSpecial=1 AND Z.Assigned IS NOT NULL  
	--ORDER By Assigned DESC 
	)
	-- 11/14/2018 Shrikant B add Temp Table And Remove the unAssigned Permissions
	SELECT * FROM TempData WHERE Assigned<>0
END