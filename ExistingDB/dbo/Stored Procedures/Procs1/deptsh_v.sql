-- 04/03/13 VL added LEFT(), without LEFT(), in VFP, the 'FromHr' and 'ToHr' become memo field, has to add LEFT(), so it's character type
CREATE PROC [dbo].[deptsh_v] 
	@pShftDept_id as char(4)='' as
SELECT Wrkshift.shift_desc, Deptshft.dept_id, Deptshft.shift_no,
  LEFT(dbo.PADL(RTRIM(LTRIM(STR(dhr_strt,2))),2,'0')+':'+dbo.PADL(RTRIM(LTRIM(STR(dmin_strt,2))),2,'0'),5) AS FromHr,
  LEFT(dbo.PADL(RTRIM(LTRIM(STR(dhr_end,2))),2,'0')+':'+dbo.PADL(RTRIM(LTRIM(STR(dmin_end,2))),2,'0'),5) AS ToHr,
  dbo.PADL(RTRIM(LTRIM(STR((tot_min-(break_min+lunch_min))/60,6,2))),8,' ') AS TotalHrs,
  Deptshft.gldivno, Deptshft.uniquerec
 FROM deptshft,wrkshift
 WHERE  Wrkshift.shift_no = Deptshft.shift_no
   AND  Deptshft.dept_id = @pShftDept_id 
 ORDER BY Deptshft.gldivno, Deptshft.shift_no
 
 
  
