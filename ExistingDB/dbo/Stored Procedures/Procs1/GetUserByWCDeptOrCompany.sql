-- =============================================
-- Author:		Raviraj P
-- Create date: 08/10/2017
-- Description:	Get User with dept_id,department and company info
-- exec [dbo].[GetUserByWCDeptOrCompany] 
-- 9/28/2017 Raviraj P : Added new column in selection
-- 10/11/2017 Raviraj P: No need of type 'E' contacts
-- =============================================
CREATE PROCEDURE [dbo].[GetUserByWCDeptOrCompany] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		SELECT au.UserId,au.UserName,ap.externalEmp AS IsExternalEmp,
		CONCAT(ap.FirstName,ap.LastName) AS EmpName, --9/28/2017 Raviraj P : Added new column in selection
		CASE 
		   WHEN CCONTACT.TYPE = 'S' AND ap.externalEmp = 1  THEN SUPINFO.SUPNAME 
		   WHEN CCONTACT.TYPE = 'C' AND ap.externalEmp = 1 THEN Customer.CUSTNAME
		   WHEN CCONTACT.TYPE = 'E' OR CCONTACT.TYPE IS NULL OR ap.externalEmp = 0 THEN (
			   CASE
					WHEN ap.dept_id  IS NOT NULL AND RTRIM(LTRIM(ap.dept_id)) <> '' THEN ap.dept_id
					WHEN ap.department IS NOT NULL AND RTRIM(LTRIM(ap.department)) <> '' THEN ap.department
					ELSE ''
				END)
		   ELSE ''
		   END AS DeptWcCompany
		FROM aspnet_Users au
		LEFT JOIN aspnet_profile ap ON au.UserId = ap.UserId
		LEFT JOIN CCONTACT ON au.UserId = CCONTACT.FkUserId AND CCONTACT.TYPE <> 'E' -- 10/11/2017 Raviraj P: No need of type 'E' contacts
		LEFT JOIN SUPINFO ON CCONTACT.CUSTNO = SUPINFO.SUPID AND CCONTACT.TYPE='S'
		LEFT JOIN Customer ON CCONTACT.CUSTNO = Customer.Custno AND CCONTACT.TYPE='C'
		WHERE  ap.STATUS  = 'active'
		ORDER BY ap.externalEmp
END