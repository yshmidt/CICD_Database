CREATE PROC [dbo].[PhyDtlPcView] @lcUniqPiHead AS char(10) = ' '
AS
SELECT Uniqpihead, Uniqpihdtl, Part_class
	FROM
	Phyhdtl
	WHERE PART_CLASS <> ''
	AND UniqPiHead = @lcUniqPiHead
	ORDER BY Part_class
	
	
	
	
	
	
	
	
	
