CREATE PROC [dbo].[AllMakePartView] 
AS
 SELECT Part_no, Revision, Part_class, Part_type, Descript, Uniq_key
 	FROM Inventor 
 	WHERE STATUS = 'Active'
 	AND PART_SOURC = 'MAKE'
 	ORDER BY 1,2