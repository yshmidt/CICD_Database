-- =============================================
-- Author:		Vicky
-- Create date: 02/22/2013
-- Description:	Function to return the string to access web report with user's webauth
-- 07/10/13 YS added new parameter for sID - session id if passed use sID if not use webauth
-- 09/24/19 YS modified parameter @lcmodule to @moduleId int and userid 
-- 10/09/19 YS Happy BD Denis. Modified the parameter names to match .net app (case sensitive)
-- =============================================
CREATE FUNCTION [dbo].[fn_GetWebURLString] 
(
	-- Add the parameters for the function here
	@moduleId int, @lcUserId uniqueidentifier, @sID char(36)
)
RETURNS varchar(max)
AS
BEGIN

-- 04/24/13 VL added code to check if three variables are NULL or empty, if yes, return NULL
-- Declare the return variable here
--09/24/19 YS change the code to connect to web 
DECLARE @lcURLString varchar(300)='', 
@lcCustomRootURL varchar(max)='';

SELECT @sID = case when @sID='' then null else @sID end 

SELECT @lcCustomRootURL = LTRIM(RTRIM(CustomRootURL))
	FROM GENERALSETUP
	
--SELECT @lcTag = LTRIM(RTRIM(tagName))
--	FROM MnxSystemTags 
--	WHERE sTagId IN 
--		(SELECT fksTagId 
--			FROM aspmnx_RoleSystemTags
--			WHERE fkRoleId IN 
--				(SELECT RoleId 
--					FROM aspnet_Roles
--					WHERE RoleName = LTRIM(RTRIM(@lcModule))+'_Reports'))
-- 07/10/13 YS check if @sID is passed, if not find webauth
--IF (@sID IS null)
--SELECT @lcWebAuth = LTRIM(RTRIM(WebAuth))
--	FROM Users
--	WHERE USERID = @lcUserId
	

-- 04/24/13 VL added CASE WHEN to check if the 3 values are null or empty, then return NULL
--07/10/13 ys use @sID if not null
SELECT @lcURLString = CASE WHEN @lcCustomRootURL IS NULL OR @lcCustomRootURL ='' OR @lcUserId is null or @sID is null THEN NULL
ELSE
-- * URL/#/Reports?sid=sessionid&userid&moduleID 
	--REPLACE(LTRIM(RTRIM(@lcCustomRootURL+'#/reports?sid='+@sID+'&userid='+cast(@lcUserId as nvarchar(36))+CONCAT('&moduleId=',@moduleId) )),' ','%20')
	-- 10/09/19 YS Happy BD Denis. Modified the parameter names to match .net app (case sensitive)
	replace(CONCAT(@lcCustomRootURL,'#/Reports?sId=',trim(@sID),'&userId=',@lcuserid,'&moduleId=',@moduleId),' ','%20')
END
								--@lcTag IS NULL OR @lcTag = '' OR
							
					 -- WHEN @sID IS NULL
					 -- THEN		
						--REPLACE(LTRIM(RTRIM(@lcCustomRootURL+'reports/view/type/'+@lcTag+'?webauth='+@lcWebAuth)),' ','%20')
					 -- ELSE
					

-- Return the result of the function
RETURN @lcURLString

END
