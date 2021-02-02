-- =============================================
-- Author:	Raviraj P
-- Create date: 09/28/2017
-- Description:	Get note user list with group and their respective wc,department or company
-- exec [dbo].[GetNoteUserList] '1FC41B35-67FE-6824-88BE-948AF948A710'
-- Ravi 10/11/2017 : No need of type 'E' contacts
-- =============================================
CREATE PROCEDURE [dbo].[GetNoteUserList] 
	-- Add the parameters for the stored procedure here
	@fkNoteId uniqueidentifier 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		SELECT DISTINCT(aspnetProfile.UserId), wmNoteUser.UserId,wmNoteUser.WmNoteUserId,wmNoteUser.NoteId,aspnetUser.UserName,
       wmNoteUser.IsGroup,wmNoteUser.GroupId, ISNULL (aspnetProfile.externalEmp,0) AS IsExternalEmp,CONCAT(aspnetProfile.FirstName,aspnetProfile.LastName) AS EmpName,
	   CASE 
	       WHEN wmNoteUser.IsGroup = 1 THEN wmNoteUser.GroupId ELSE wmNoteUser.UserId
	   END AS Id,
	   CASE 
	       WHEN wmNoteUser.IsGroup = 1 THEN wmNoteGroup.GroupName ELSE aspnetUser.UserName
	   END AS Name,
	   CASE 
	       WHEN wmnote.fkCreatedUserID = wmNoteUser.UserId THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT)
	   END AS IsOriginator,
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
	FROM WmNoteUser  
			OUTER APPLY (SELECT * FROM Wmnotes 
						   WHERE Wmnotes.NoteID = WmNoteUser.NoteId) wmnote
			OUTER APPLY (SELECT * FROM aspnet_Users 
						   WHERE aspnet_Users.UserId = WmNoteUser.UserId) aspnetUser
			OUTER APPLY (SELECT * FROM aspnet_profile 
						   WHERE aspnet_profile.UserId = WmNoteUser.UserId) aspnetProfile
			OUTER APPLY (SELECT * FROM WmNoteGroup 
						   WHERE WmNoteGroup.WmNoteGroupId = WmNoteUser.GroupId) wmNoteGroup
	LEFT JOIN CCONTACT ON wmNoteUser.UserId = CCONTACT.FkUserId  AND CCONTACT.TYPE <> 'E' -- Ravi 10/11/2017 : No need of type 'E' contacts
	LEFT JOIN SUPINFO ON CCONTACT.CUSTNO = SUPINFO.SUPID AND CCONTACT.TYPE='S'
	LEFT JOIN Customer ON CCONTACT.CUSTNO = Customer.Custno AND CCONTACT.TYPE='C'
	WHERE WmNoteUser.NoteId = @fkNoteId
	ORDER BY IsOriginator DESC
END