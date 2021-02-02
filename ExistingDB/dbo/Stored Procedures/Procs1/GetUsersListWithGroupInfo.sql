-- =============================================
-- Author:	Raviraj P
-- Create date: 09/28/2017
-- Description:	Get Team user list with group info their respective wc,department or company and  if user belong set IsChecked as true
-- exec [dbo].[GetUsersListWithGroupInfo] '1FC41B35-67FE-6824-88BE-948AF948A710'
-- =============================================
CREATE PROCEDURE [dbo].[GetUsersListWithGroupInfo] 
	-- Add the parameters for the stored procedure here
	@fkWmNoteGroupId uniqueidentifier 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		SELECT aspnetUser.UserId,aspnetUser.UserName,
		CASE 
				   WHEN CCONTACT.TYPE = 'S' and aspnetProfile.externalEmp = 1  Then SUPINFO.SUPNAME 
				   WHEN CCONTACT.TYPE = 'C' and aspnetProfile.externalEmp = 1 Then Customer.CUSTNAME
				   WHEN CCONTACT.TYPE = 'E' or CCONTACT.TYPE is null or aspnetProfile.externalEmp = 0 Then (
					   CASE
							WHEN aspnetProfile.dept_id  is not null and RTRIM(LTRIM(aspnetProfile.dept_id)) <> '' then aspnetProfile.dept_id
							WHEN aspnetProfile.department  is not null and RTRIM(LTRIM(aspnetProfile.department)) <> '' then aspnetProfile.department
							ELSE ''
						END)
				   ELSE ''
				   END AS DeptWcCompany,
        CASE
			  WHEN aspnetUser.UserId = WmNoteGroupUser.UserId THEN CAST(1 as bit) ELSE CAST(0 as bit)
		END AS IsChecked
		FROM aspnet_Users aspnetUser
		LEFT JOIN WmNoteGroupUsers WmNoteGroupUser on aspnetUser.UserId = WmNoteGroupUser.UserId and WmNoteGroupUser.FkWmNoteGroupId = @fkWmNoteGroupId
		OUTER APPLY (SELECT * 
					   FROM WmNoteGroup 
					   WHERE WmNoteGroup.WmNoteGroupId = WmNoteGroupUser.FkWmNoteGroupId) wmNoteGroup
		OUTER APPLY (SELECT * 
					   FROM aspnet_profile 
					   WHERE aspnet_profile.UserId = aspnetUser.UserId) aspnetProfile
		LEFT JOIN CCONTACT on aspnetUser.UserId = CCONTACT.FkUserId
		LEFT JOIN SUPINFO on CCONTACT.CUSTNO = SUPINFO.SUPID and CCONTACT.TYPE='S'
		LEFT JOIN Customer on CCONTACT.CUSTNO = Customer.Custno and CCONTACT.TYPE='C'
		ORDER BY IsChecked desc
END