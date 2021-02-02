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
-- 12/29/2017 Raviraj P: Use to serch result according to filter 
-- 03/05/2020 Sachin B : Added 2 parameters @categoryType and @subCategory to filtred the data on there selection
-- 03/05/11/2020 Sachin B: Removed and condition
-- 03/05/11/2020 Sachin B: filtered data based on @categoryType and @subCategory
-- GetTeamAndParticipantsListFilter 1,2000,'','internal',''   -- 96
-- GetTeamAndParticipantsListFilter 1,2000,'','external',''   -- 34
-- GetTeamAndParticipantsListFilter 1,2000,'','Supplier','0000000002'   -- 128 --32
-- GetTeamAndParticipantsListFilter 1,2000,'','customer','0000000002'   -- 106 --10
-- GetTeamAndParticipantsListFilter 1, 80, '', 'Internal', ''

-- =============================================
CREATE PROCEDURE [dbo].[GetTeamAndParticipantsListFilter] 
	-- Add the parameters for the stored procedure here
	--@userId uniqueidentifier  -- 10/18/2017 Raviraj P: no need of parameter @userId
	 @pageIndex INT = 1, -- 12/29/2017 Raviraj P: Add parameter for pagging and filter
	 @pageSize INT = 100,
	 @filter NVARCHAR(100) = NULL,
	 -- 03/05/2020 Sachin B : Added 2 parameters @categoryType and @subCategory to filtred the data on there selection
	 @categoryType NVARCHAR(100) = NULL,
     @subCategory NVARCHAR(100) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
 SET @pageIndex = @pageIndex-1  
	SET NOCOUNT ON;
	SELECT aspnetUser.UserId AS Id,CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER) AS GroupId,aspnetUser.UserName AS Name,
	aspnetProfile.externalEmp AS IsExternalEmp, CONCAT(aspnetProfile.FirstName, ' ', aspnetProfile.LastName) AS EmpName,CAST(0 AS BIT) AS IsGroup,
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
	JOIN aspnet_Profile aspnetProfile ON aspnetUser.UserId = aspnetProfile.UserId AND aspnetProfile.STATUS='active' AND 
	(aspnetUser.UserName like '%' + @filter + '%' OR aspnetProfile.FirstName like '%' + @filter + '%' Or  aspnetProfile.LastName like '%' + @filter + '%') -- 12/29/2017 Raviraj P: Filter on first/last name and user name
	LEFT JOIN CCONTACT on aspnetUser.UserId = CCONTACT.FkUserId  
    -- 03/05/11/2020 Sachin B: Removed and condition
	--AND CCONTACT.TYPE <> 'E'  -- 10/11/2017 Raviraj P: No need of type 'E' contacts 
	LEFT JOIN SUPINFO on CCONTACT.CUSTNO = SUPINFO.SUPID AND CCONTACT.TYPE='S'
	LEFT JOIN Customer on CCONTACT.CUSTNO = Customer.Custno AND CCONTACT.TYPE='C'
    -- 03/05/11/2020 Sachin B: filtered data based on @categoryType and @subCategory
	 WHERE ( (LOWER(@categoryType) = 'internal' AND CCONTACT.TYPE in ('E'))
	        OR (LOWER(@categoryType) = 'supplier' AND CCONTACT.TYPE in ('S','E')) 
		    OR (LOWER(@categoryType) = 'customer' AND CCONTACT.TYPE in ('C','E')) 
		    OR (LOWER(@categoryType) = 'external' AND CCONTACT.TYPE in ('S','C')) 
		  )
 
 AND  ( (CCONTACT.CUSTNO = CASE WHEN (@subCategory IS NOT NULL AND @subCategory<>'' ) THEN @subCategory ELSE CCONTACT.CUSTNO END) OR CCONTACT.CUSTNO ='')

UNION ALL
	SELECT WmNoteGroup.WmNoteGroupId as Id,WmNoteGroup.WmNoteGroupId AS GroupId,WmNoteGroup.GroupName AS Name ,CAST(0 AS BIT) AS IsExternalEmp, '' AS EmpName,
		CAST(1 AS BIT) AS IsGroup,'mnx-users' AS CssClass,-- 09/29/2017 Raviraj P : Used To display Icon in participant list
		CAST(CAST(0 AS BINARY) AS uniqueidentifier) AS UserId,
		'' AS DeptWcCompany,'' AS UserName
	FROM WmNoteGroup 
	WHERE WmNoteGroup.GroupName like '%' + @filter + '%' -- 12/29/2017 Raviraj P: Filter on first/last name and user name
	ORDER BY Id 
	OFFSET (@pageIndex) ROWS  -- 12/29/2017 Raviraj P: Implement pagging
	FETCH NEXT @pageSize ROWS ONLY;  
	--WHERE CreatedBy = @userId -- 10/12/2017 Raviraj P: added new paramter @userId to userwise team
	-- 10/18/2017 Raviraj P: For participant multiselect need all teams
END