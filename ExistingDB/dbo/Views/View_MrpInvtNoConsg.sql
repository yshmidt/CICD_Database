/*This view is used on the following report: mrpptvw*/
	CREATE VIEW dbo.View_MrpInvtNoConsg
	AS
	SELECT TOP (100) PERCENT UNIQ_KEY, PART_CLASS, PART_TYPE, PART_NO, REVISION, DESCRIPT, PART_SOURC
	FROM     dbo.MrpInvt
	WHERE  (PART_SOURC <> 'CONSG') AND EXISTS
						  (SELECT 1 AS Expr1
						   FROM      dbo.MRPACT
						   WHERE   (UNIQ_KEY = dbo.MrpInvt.UNIQ_KEY))
	ORDER BY PART_NO, REVISION