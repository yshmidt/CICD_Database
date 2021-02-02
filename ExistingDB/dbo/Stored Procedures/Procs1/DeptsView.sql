
		CREATE PROC [dbo].[DeptsView] 
		--09/19/13 YS added parameter for userid, will be used when the user will be assigned in .net security to view certain parameters
		--05/02/14 DRP:  Switched Dept_name and Dept_id field around in order to work properly with WebManex Parameter selections
		@Userid uniqueidentifier = null
		AS 
		SELECT  Dept_id,Dept_name, Number
			FROM Depts
			ORDER BY Number