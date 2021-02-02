CREATE PROC [dbo].[wkstdfwcview] 
	@pShftDept_id as char(4)=''
	as SELECT Wkstdfwc.uniq_wswc, Wkstdfwc.wkst_name, Wkstdfwc.wkst_desc,
	Wkstdfwc.dept_id FROM wkstdfwc WHERE  Wkstdfwc.dept_id = @pShftDept_id 
 ORDER BY Wkstdfwc.wkst_name
