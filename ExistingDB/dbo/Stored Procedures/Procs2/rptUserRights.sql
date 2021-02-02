
-- =============================================
-- Author:			Debbie
-- Create date:		07/11/2012
-- Description:		Created for the User Rights Report per Selected Department/Module
-- Reports Using Stored Procedure:  rightspermod.rpt
-- Modifications:	10/09/2012 DRP: I had to add the @lcDept Parameter into the procedure itself, because it was found that as soon as I added the parameter within the Crystal Report
--									that it would then prompt the user with the SQL Authentication pw entry screen.  
-- 11/16/17 DRP:  added @userId, Changed the @lcDept * to be All  
-- =============================================
		CREATE PROCEDURE [dbo].[rptUserRights]

			@lcDept char (15) = 'All' --The user can select the Department Name.
			,@userId uniqueidentifier=null	--11/16/17 DRP:  added

		as
		begin
		;
		with Zresults as (
		select	items.DEPTS,items.SCREENDESC,items.Installed,users.userid,users.NAME,users.firstname,CASE WHEN rights.SVIEW = 1 THEN CAST ('YES' AS CHAR(3)) ELSE CAST('NO' AS CHAR(3)) END AS SVIEW
				,CASE WHEN rights.SEDIT = 1 THEN CAST('YES' AS CHAR(3)) ELSE CAST('NO' AS CHAR(3)) END AS SEDIT,CASE WHEN rights.SCOPY = 1 THEN CAST ('YES' AS CHAR(3)) ELSE CAST('NO' AS CHAR(3)) END AS SCOPY
				,CASE WHEN rights.SADD = 1 THEN CAST ('YES' AS CHAR(3)) ELSE CAST ('NO' AS CHAR(3)) END AS SADD,CASE WHEN rights.SDELETE = 1 THEN CAST('YES' AS CHAR(3)) ELSE CAST('NO' AS CHAR(3)) END AS SDELETE
				,CASE WHEN rights.SALL = 1 THEN CAST ('YES' AS CHAR(3)) ELSE CAST('NO' AS CHAR(3)) END AS SALL,CASE WHEN rights.RVIEW = 1 THEN CAST('YES' AS CHAR(3)) ELSE CAST('NO' AS CHAR(3)) END AS RVIEW
				,CASE WHEN NPASSWORDEXPIN = 1 THEN 'PW Expired' else '' end as Expired
				,case when users.SUPERVISOR = 1 then CAST('Prod Supervisor' as CHAR(15)) when users.LASS = 1 then CAST ('Acct Supervisor' as CHAR(15)) else CAST ('' as CHAR(15)) end as ProdSuper
				,case when rightS.DEPTS = 'ACTG' THEN CAST('ACCOUNTING' AS CHAR (15))
					WHEN RIGHTS.DEPTS = 'ADMN' THEN CAST ('ADMINISTRATION' AS CHAR(15))
					WHEN RIGHTS.DEPTS = 'MATL' THEN CAST ('MATERIAL' AS CHAR(15))
					WHEN RIGHTS.DEPTS = 'PROD' THEN CAST('PRODUCTION' AS CHAR(15))
					WHEN RIGHTS.DEPTS = 'QUAL' THEN CAST ('QUALITY' AS CHAR(15))
					WHEN RIGHTS.DEPTS = 'SALE' THEN CAST ('SALES' AS CHAR(15)) END AS DeptName


		from	ITEMS
				inner join RIGHTS on items.depts = rights.DEPTS and items.UNIQUENUM = rights.Fk_Uniquenum
				inner join USERS on rights.FK_uniqUser = users.UNIQ_USER

		where	items.Installed = 1
		) 

		select * from Zresults where DeptName like case when @lcDept ='All' then '%' else @lcDept end	--11/16/17 DRP:  changed the @lcDept to be 'All' instead of '*'
		end