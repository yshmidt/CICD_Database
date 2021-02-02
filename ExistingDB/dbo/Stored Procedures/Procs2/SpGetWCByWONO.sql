-- =============================================
-- Author:		Nilesh Sa
-- Create date: 6/10/2016
-- Description:	get the work centers based on the Work Order Number.
-- [dbo].[SpGetWCByWONO] '0000000103'
-- Raviraj P : 9/1/2016 check for WO without status Cancel 
-- 12/16/2015 Raviraj P  : Select the respected number of dept
-- =============================================
CREATE PROCEDURE [dbo].[SpGetWCByWONO] 
	-- Add the parameters for the stored procedure here
	@wono char(10) ='' --'0000000006'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;

     SELECT CONCAT(DQ.NUMBER,'-',DEPT.DEPT_ID) As NumberDeptId,DQ.NUMBER, --12/16/2015 Raviraj P  : Select the respected number of dept
	   DEPT.DEPT_ID 
	 FROM 
		DEPTS DEPT(nolock) 
	 INNER JOIN DEPT_QTY DQ (nolock) on DEPT.DEPT_ID = DQ.DEPT_ID 
	 INNER JOIN WOENTRY WE (nolock) on WE.WONO = DQ.WONO 
	 WHERE DQ.WONO= @wono and WE.OPENCLOS <> 'Cancel'-- Raviraj P : 9/1/2016 check for WO without status Cancel
	 ORDER BY DQ.NUMBER
END