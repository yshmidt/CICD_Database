
CREATE PROC [dbo].[RollupView] @lcRollType AS char(4) = ' '

 , @userId uniqueidentifier=null 
AS
BEGIN
SET NOCOUNT ON;

-- 05/02/17 VL added functional currency code
SELECT Part_no, Revision, Part_class, Part_type, Descript, Roll_qty, Wipqty, Stdcost, 
		Usecalc, Manual, Delta, Uniq_roll, Rollup.Uniq_key, Rundate, Pct, Rolltype, 
		Manualcost, Calccost, Newmatlcst, Matl_cost, Newlabrcst, Laborcost, Newovhdcst, 
		Overhead, Newothrcst, Othercost2, Newudcst, Other_cost, Namountdiff,
		-- 05/02/17 VL added functional currency code
		StdcostPR, DeltaPR, ManualCostPR, CalcCostPR, NewmatlcstPR, Matl_costPR, 
		NewlabrcstPR, LaborcostPR, NewovhdcstPR, OverheadPR, NewothrcstPR, 
		Othercost2PR, NewudcstPR, Other_costPR, NamountdiffPR
	FROM Rollup INNER JOIN Inventor 
	ON Rollup.Uniq_key = Inventor.Uniq_key
	WHERE Rollup.Rolltype = @lcRollType
	ORDER BY Part_no, Revision
 
END 




