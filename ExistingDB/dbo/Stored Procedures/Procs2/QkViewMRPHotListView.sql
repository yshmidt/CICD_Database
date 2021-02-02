
-- =============================================
-- Modified:  04/04/17 DRP:  The Sort order had "DAY" when it should have been "Days" Desc
-- 06/15/17 DRP:  changed the sort order to be Days desc
-- 06/26/17 DRP:  Added a filter so that I would not include inventory parts that had an 'Inactive' status
-- =============================================

CREATE PROCEDURE [dbo].[QkViewMRPHotListView]
@userid uniqueidentifier = null
AS
BEGIN

SET NOCOUNT ON;

SELECT Days, ReqDate, Part_no, Revision, Part_Class, Part_type, Action, DtTakeAct, Buyer_Type, ReqQty - Balance AS Qty 
	FROM MrpAct, Inventor 
	WHERE Inventor.Uniq_Key = MrpAct.Uniq_Key 
	AND CHARINDEX('PO', Action) > 0
	AND Days > 0 
	and INVENTOR.STATUS <> 'Inactive'
	ORDER BY Days desc, ReqDate, Part_no, Revision
  
END