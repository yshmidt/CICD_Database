-- =============================================
-- Author:Satish Bhosle
-- Create date: 10/09/2014
-- Description:	 Get Work Shift details based on deptId
--[DeptsShiftDetails] 'STAG' 
-- =============================================
Create  procedure [dbo].[DeptsShiftDetails] 
	@p_DeptId nvarchar(50) = NULL
	 as

IF @p_DeptId IS NULL
	  BEGIN
		  SELECT shift_no, Wrkshift.shift_desc,wrkshift.UNIQUEREC,
		  CAST(dbo.PADL(RTRIM(LTRIM(STR(dhr_strt,2))),2,'0')+':'+dbo.PADL(RTRIM(LTRIM(STR(dmin_strt,2))),2,'0') as char(5)) AS FromHr,
		  CAST(dbo.PADL(RTRIM(LTRIM(STR(dhr_end,2))),2,'0')+':'+dbo.PADL(RTRIM(LTRIM(STR(dmin_end,2))),2,'0') as char(5)) AS ToHr,
		  CAST((tot_min-(break_min+lunch_min))/60 as numeric(12,2)) AS TotalHrs
		  FROM wrkshift 
		   ORDER BY SHIFT_NO
	  END
 ELSE
	BEGIN
		  SELECT Wrkshift.shift_desc, Deptshft.dept_id, Deptshft.shift_no,
		  CAST(dbo.PADL(RTRIM(LTRIM(STR(dhr_strt,2))),2,'0')+':'+dbo.PADL(RTRIM(LTRIM(STR(dmin_strt,2))),2,'0') as char(5)) AS FromHr,
		  CAST(dbo.PADL(RTRIM(LTRIM(STR(dhr_end,2))),2,'0')+':'+dbo.PADL(RTRIM(LTRIM(STR(dmin_end,2))),2,'0') as char(5)) AS ToHr,
		  CAST((tot_min-(break_min+lunch_min))/60 as numeric(12,2)) AS TotalHrs,
		  Deptshft.uniquerec
		 FROM deptshft,wrkshift
		 WHERE  Wrkshift.shift_no = Deptshft.shift_no AND dept_id= @p_DeptId
		 ORDER BY Dept_id,Deptshft.shift_no
	END
