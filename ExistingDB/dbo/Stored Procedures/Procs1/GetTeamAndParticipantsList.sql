-- =============================================
-- Author:	Raviraj P
-- Create date: 09/29/2017
-- Description:	Get the list of users and team
-- exec [dbo].[GetTeamAndParticipantsList] '49F80792-E15E-4B62-B720-21B360E3108A'
-- 09/29/2017 Raviraj P : Seletcted some values as '' to avoid .net exceptions & same for GroupId while selecting user list
-- 09/29/2017 Raviraj P : Used To display Icon in participant list
-- 10/11/2017 Raviraj P: No need of type 'E' contacts
-- 10/12/2017 Raviraj P: added new paramter @userId to userwise team
-- 10/18/2017 Raviraj P: For participant multiselect need all teams
-- 10/18/2017 Raviraj P: no need of parameter @userId
-- =============================================
CREATE PROCEDURE [dbo].[GetTeamAndParticipantsList] 
	-- Add the parameters for the stored procedure here
	 --@userId uniqueidentifier  -- 10/18/2017 Raviraj P: no need of parameter @userId
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SELECT aspnetUser.UserId AS Id,CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER) AS GroupId,aspnetUser.UserName AS Name,aspnetProfile.externalEmp AS IsExternalEmp, CONCAT(aspnetProfile.FirstName, ' ', aspnetProfile.LastName) AS EmpName,CAST(0 AS BIT) AS IsGroup	,
	'mnx-user' AS CssClass,-- 09/29/2017 Raviraj P : Used To display Icon in participant list
	aspnetUser.UserId,
	CASE 
	  WHEN CCONTACT.TYPE = 'S' AND aspnetProfile.externalEmp = 1  THEN SUPINFO.SUPNAME 
	  WHEN CCONTACT.TYPE = 'C' AND aspnetProfile.externalEmp = 1 THEN Customer.CUSTNAME
	  WHEN CCONTACT.TYPE = 'E' OR CCONTACT.TYPE IS NULL OR aspnetProfile.externalEmp = 0 THEN (
		CASE
		  WHEN aspnetProfile.dept_id  IS NOT NULL AND RTRIM(LTRIM(aspnetProfile.dept_id)) <> '' THEN aspnetProfile.dept_id
		  WHEN aspnetProfile.department  IS NOT NULL AND RTRIM(LTRIM(aspnetProfile.department)) <> '' THEN aspnetProfile.department
		ELSE ''
		END)
	ELSE ''
	END AS DeptWcCompany,
	aspnetUser.UserName 
	FROM aspnet_Users aspnetUser
	JOIN aspnet_Profile aspnetProfile ON aspnetUser.UserId = aspnetProfile.UserId AND aspnetProfile.STATUS='active'
	LEFT JOIN CCONTACT on aspnetUser.UserId = CCONTACT.FkUserId  AND CCONTACT.TYPE <> 'E' -- 10/11/2017 Raviraj P: No need of type 'E' contacts
	LEFT JOIN SUPINFO on CCONTACT.CUSTNO = SUPINFO.SUPID AND CCONTACT.TYPE='S'
	LEFT JOIN Customer on CCONTACT.CUSTNO = Customer.Custno AND CCONTACT.TYPE='C'
UNION ALL
	SELECT WmNoteGroup.WmNoteGroupId as Id,WmNoteGroup.WmNoteGroupId AS GroupId,WmNoteGroup.GroupName as Name ,CAST(0 AS BIT) AS IsExternalEmp, '' AS EmpName,
	CAST(1 AS BIT) AS IsGroup,'mnx-users' AS CssClass,-- 09/29/2017 Raviraj P : Used To display Icon in participant list
	CAST(CAST(0 AS BINARY) AS uniqueidentifier) AS UserId,
	'' AS DeptWcCompany,'' AS UserName
	FROM WmNoteGroup 
	--WHERE CreatedBy = @userId -- 10/12/2017 Raviraj P: added new paramter @userId to userwise team
	-- 10/18/2017 Raviraj P: For participant multiselect need all teams
END