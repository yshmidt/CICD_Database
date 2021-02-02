CREATE PROCEDURE [dbo].[QkViewKitRequiredView2] @lcFilter AS char(10) = 'ALL'
AS
BEGIN
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 08/25/17 VL we had different ways of calculating required date.  MRP and BOM counts 5 days for a week, 20 days for a month, here we had 7 days for a week, 30 days for a mont, changed to work the same as MRP and BOM
-- Modified: 09/18/17 YS added JobType to Woentry table to separate Status (OpenClos) from Type
-- @lcFilter:  'ALL', 'BOM', 'REL'
SET NOCOUNT ON;
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZKitRequired TABLE (Wono char(10), Part_no char(35), Revision char(8), Descript char(45), Balance numeric(7,0), Uniq_key char(10),
							Due_date smalldatetime, ReqDate smalldatetime, LateDay numeric(4,0), BomCnt numeric(4,0) default 0, Prod_LTime numeric(3,0),
							Prod_LUnit char(2), Kit_LTime numeric(3,0), Kit_LUnit char(2))

BEGIN
IF @lcFilter = 'BOM'
	INSERT @ZKitRequired (Wono, Part_no, Revision, Descript, Balance, Woentry.Uniq_key, Due_date, Prod_LTime, Prod_LUnit, Kit_LTime, Kit_LUnit)
		SELECT DISTINCT Wono, Part_no, Revision, Descript, Balance, Woentry.Uniq_key, Due_date, Prod_LTime, Prod_LUnit, Kit_LTime, Kit_LUnit
		FROM Woentry, Bom_det, Inventor 
		WHERE Woentry.Uniq_key = Inventor.Uniq_key 
		AND Woentry.Uniq_key = Bom_det.BomParent 
		AND Woentry.OpenClos <> 'Closed'
		AND Woentry.OpenClos <> 'Cancel'
		AND Woentry.KitStatus = ''
		AND Woentry.Balance > 0 
		-- Modified: 09/18/17 YS added JobType to Woentry table to separate Status (OpenClos) from Type
		--AND CHARINDEX('Rework',OPENCLOS)=0
		AND CHARINDEX('Rework',Jobtype)=0
ELSE
	INSERT @ZKitRequired (Wono, Part_no, Revision, Descript, Balance, Woentry.Uniq_key, Due_date, Prod_LTime, Prod_LUnit, Kit_LTime, Kit_LUnit)
		SELECT Wono, Part_no, Revision, Descript, Balance, Woentry.Uniq_key, Due_date, Prod_LTime, Prod_LUnit, Kit_LTime, Kit_LUnit
		FROM Woentry, Inventor
		WHERE Woentry.Uniq_key = Inventor.Uniq_key 
		AND Woentry.OpenClos <> 'Closed'
		AND Woentry.OpenClos <> 'Cancel'
		AND Woentry.KitStatus = ''
		AND Woentry.Balance > 0 
		AND Woentry.Kit = 1
		-- Modified: 09/18/17 YS added JobType to Woentry table to separate Status (OpenClos) from Type
		--AND CHARINDEX('Rework',OPENCLOS)=0
			AND CHARINDEX('Rework',JobType)=0
END				

-- 08/25/17 VL we had different ways of calculating required date.  MRP and BOM counts 5 days for a week, 20 days for a month, here we had 7 days for a week, 30 days for a mont, changed to work the same as MRP and BOM
UPDATE @ZKitRequired
	SET ReqDate = dbo.fn_GetWorkDayWithOffset(Due_date, Prod_ltime*(CASE WHEN Prod_lunit = 'DY' THEN 1 ELSE
			CASE WHEN Prod_lunit = 'WK' THEN 5 ELSE
			CASE WHEN Prod_lunit = 'MO' THEN 20 ELSE 1 END END END) + 
				Kit_ltime*(CASE WHEN Kit_lunit = 'DY' THEN 1 ELSE
			CASE WHEN Kit_lunit = 'WK' THEN 5 ELSE
			CASE WHEN Kit_lunit = 'MO' THEN 20 ELSE 1 END END END),'-'),
		LateDay = dbo.fn_FindNumberOfWorkingDays(dbo.fn_GetWorkDayWithOffset(Due_date, Prod_ltime*(CASE WHEN Prod_lunit = 'DY' THEN 1 ELSE
			CASE WHEN Prod_lunit = 'WK' THEN 5 ELSE
			CASE WHEN Prod_lunit = 'MO' THEN 20 ELSE 1 END END END) + 
				Kit_ltime*(CASE WHEN Kit_lunit = 'DY' THEN 1 ELSE
			CASE WHEN Kit_lunit = 'WK' THEN 5 ELSE
			CASE WHEN Kit_lunit = 'MO' THEN 20 ELSE 1 END END END),'-'),GETDATE())
			
;
WITH ZBomCnt
AS
(SELECT Bomparent, ISNULL(COUNT(*),0) AS BomCnt 
	FROM Bom_det 
	WHERE Bomparent IN 
		(SELECT Uniq_key 
			FROM @ZKitRequired) 
	GROUP BY Bomparent
)

UPDATE @ZKitRequired
	SET BomCnt = ZBomCnt.BomCnt
	FROM @ZKitRequired ZK, ZBomCnt
	WHERe ZK.Uniq_key = ZBomCnt.BomParent


SELECT * FROM @ZKitRequired ORDER BY ReqDate
END			