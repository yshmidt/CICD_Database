-- =============================================
-- Author:	Raviraj P
-- Create date: 09/28/2017
-- Description:	Get Team user list with their respective wc,department or company
-- exec [dbo].[GetTeamUsersList] '1FC41B35-67FE-6824-88BE-948AF948A710'
-- 10/11/2017 Raviraj P: No need of type 'E' contacts
-- =============================================
CREATE PROCEDURE [dbo].[GetTeamUsersList] 
	-- Add the parameters for the stored procedure here
	@fkWmNoteGroupId uniqueidentifier 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		SELECT WmNoteGroupUsers.FkWmNoteGroupId,WmNoteGroupUsers.UserId,WmNoteGroupUsers.WmNoteGroupUsersId,aspnetUser.UserName,aspnetProfile.externalEmp AS IsExternal ,
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
				   END AS DeptWcCompany
		FROM WmNoteGroupUsers
		OUTER APPLY (SELECT * 
					   FROM WmNoteGroup 
					   WHERE WmNoteGroup.WmNoteGroupId = WmNoteGroupUsers.FkWmNoteGroupId) wmNoteGroup
		OUTER APPLY (SELECT * 
					   FROM aspnet_Users 
					   WHERE aspnet_Users.UserId = WmNoteGroupUsers.UserId) aspnetUser
		OUTER APPLY (SELECT * 
					   FROM aspnet_profile 
					   WHERE aspnet_profile.UserId = WmNoteGroupUsers.UserId) aspnetProfile
		LEFT JOIN CCONTACT on WmNoteGroupUsers.UserId = CCONTACT.FkUserId and CCONTACT.TYPE <> 'E' -- 10/11/2017 Raviraj P: No need of type 'E' contacts
		LEFT JOIN SUPINFO on CCONTACT.CUSTNO = SUPINFO.SUPID and CCONTACT.TYPE='S'
		LEFT JOIN Customer on CCONTACT.CUSTNO = Customer.Custno and CCONTACT.TYPE='C'
		WHERE WmNoteGroupUsers.FkWmNoteGroupId =@fkWmNoteGroupId
END