-- 03/29/13 VL changed the CAST() to make it show number after decimal point
--CAST((tot_min-(break_min+lunch_min))/60 as numeric(8,0)) AS TotalHrs,

CREATE proc [dbo].[DeptsShiftView]  
	 as
SELECT Wrkshift.shift_desc, Deptshft.dept_id, Deptshft.shift_no,
  CAST(dbo.PADL(RTRIM(LTRIM(STR(dhr_strt,2))),2,'0')+':'+dbo.PADL(RTRIM(LTRIM(STR(dmin_strt,2))),2,'0') as char(5)) AS FromHr,
  CAST(dbo.PADL(RTRIM(LTRIM(STR(dhr_end,2))),2,'0')+':'+dbo.PADL(RTRIM(LTRIM(STR(dmin_end,2))),2,'0') as char(5)) AS ToHr,
  CAST((tot_min-(break_min+lunch_min))/60 as numeric(12,2)) AS TotalHrs,
  Deptshft.uniquerec
 FROM deptshft,wrkshift
 WHERE  Wrkshift.shift_no = Deptshft.shift_no
 ORDER BY Dept_id,Deptshft.shift_no
