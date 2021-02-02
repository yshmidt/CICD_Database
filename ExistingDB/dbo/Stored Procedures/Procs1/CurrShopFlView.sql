-- =============================================
-- Author:		
-- Create date: 
-- Description:	Used For Get Current Shop Fl Data
-- 06/21/2018 Shripati U Add the @uniqRout in the join with QUOTDEPT table and Add NCount on Condition
-- =============================================

CREATE PROC [dbo].[CurrShopFlView] 

@lcWono AS CHAR(10) = ''

AS

SET NOCOUNT ON;  

DECLARE @uniqRout CHAR(10)
SELECT @uniqRout = uniquerout FROM WOENTRY WHERE WONO =@lcWono

SELECT Depts.Dept_name, Dueoutdt, CAST(ISNULL(QuotDept.SETUPSEC/60.00,0.00) AS NUMERIC(11,3)) AS Setuptimem, 
CAST(ISNULL(QuotDept.RUNTIMESEC/60.00,0.00) AS NUMERIC(11,3)) AS Runtimem, Dept_pri, Curr_qty,
Dept_qty.Wono, Dept_qty.Dept_id, Xfer_qty,Dept_qty.Number,dept_qty.UNIQUEREC ,
Capctyneed, Wo_wc_note, Deptkey, Dept_qty.Serialstrt, Depts.Wcnote, Dept_qty.Capctyneed/3600.00 AS Process_time_h,
CAST(0.00 AS NUMERIC(7,5)) AS Wc_Avg_CapacityH,
Woentry.Uniq_key
FROM Dept_qty 
INNER JOIN Depts ON Depts.dept_id = Dept_qty.dept_id
INNER JOIN WOENTRY ON dept_qty.WONO=Woentry.Wono
LEFT OUTER JOIN QUOTDEPT ON Woentry.UNIQ_KEY=Quotdept.UNIQ_KEY AND Dept_qty.NUMBER=QUOTDEPT.Number AND QUOTDEPT.uniquerout =@uniqRout
WHERE Dept_qty.wono = @lcWono
ORDER BY Dept_qty.wono, Dept_qty.number