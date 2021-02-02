
CREATE PROCEDURE [dbo].[WoParentSubordinateView] 
	@WONO AS CHAR(10) = ''
AS
BEGIN

	SET NOCOUNT ON;

    ;WITH ParentSubordinate AS (
    SELECT WONO as WorkOrder, DUE_DATE AS DueDate, BLDQTY AS WOQty,  PART_NO AS AssemblyNumber, 
    CASE WHEN PARENTWO <> ' ' THEN 'Parent' ELSE '' END AS ParentSub, 
	ChildWo, PARENTWO,WCHILDPAUK	
	FROM Wchildpa, Woentry, Inventor
	WHERE Wchildpa.ChildWo = Woentry.Wono
	AND Woentry.Uniq_key = Inventor.Uniq_key
	AND ParentWo = @WONO

    UNION ALL

    SELECT WONO as WorkOrder, DUE_DATE AS DueDate, BLDQTY AS WOQty,  PART_NO AS AssemblyNumber, 
    CASE WHEN ChildWo <> ' ' THEN 'Subordinate' ELSE '' END  AS  ParentSub,
	ChildWo, PARENTWO,WCHILDPAUK	
	FROM Wchildpa, Woentry, Inventor
	WHERE Wchildpa.ParentWo = Woentry.Wono
	AND Woentry.Uniq_key = Inventor.Uniq_key
	AND ChildWo = @WONO
)
	-- 11/09/2018 Shripati U Remove leading zeros from work order.
	SELECT dbo.fRemoveLeadingZeros(WorkOrder) AS WorkOrder , DueDate, WOQty, AssemblyNumber, ParentSub,ChildWo,PARENTWO,WCHILDPAUK  FROM ParentSubordinate;  
END