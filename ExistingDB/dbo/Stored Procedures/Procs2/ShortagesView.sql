-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <10/26/10>
-- Description:	<Create view for shortages for specific uniq_key to view in the PO receiving screens>
-- Modified: 03/25/2014 YS change inner join to left outer join for the depts table. Line shortages can be entered w/o depts
-- 07/25/2017 Shivshankar P : Display Prj/Wo number on Shortage Grid and  Used to shortqty while changing the qty on client side validating
--18/09/2017 Shivshankar P :Used to Display Line/Kit on the Short Grid
-- =============================================
CREATE PROCEDURE [dbo].[ShortagesView]
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' '
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Woentry.due_date, Kamain.wono, Customer.custname,
	      CASE WHEN Kamain.LINESHORT IS NULL THEN 'Line - ' + Kamain.wono ELSE 'Kit - '+ Kamain.wono END AS PrjWoNumber,   --07/25/2017 Shivshankar P :Used to Display Prj/Wo number on Shortage Grid
		  Inventor.part_no, Inventor.revision, Kamain.shortqty, Kamain.uniq_key,
		  Kamain.dept_id, Kamain.shortqty-Kamain.shortqty AS qtyissue, Kamain.shortqty-Kamain.shortqty AS OrgReserveQty,   --07/25/2017 Shivshankar P :Used to shortqty while changing the qty on client side validating
		  Woentry.prjunique, Kamain.shortqty AS shortbalance, Kamain.kaseqnum,
		  CAST(0 as bit) AS approved, Woentry.uniq_key AS bomparent,
		  ISNULL(DEPTS.DEPT_NAME,space(25)) as Dept_name, ISNULL(PJCTMAIN.PRJNUMBER,SPACE(10)) as PRJNUMBER,
		  CASE WHEN Kamain.LINESHORT = 1 THEN 'Line' ELSE  'Kit' END AS LineShort   --18/09/2017 Shivshankar P :Used to Display Line/Kit on the Short Grid
		FROM kamain INNER JOIN woentry 
			ON  Kamain.wono = Woentry.wono 
			INNER JOIN inventor 
			ON  Woentry.uniq_key = Inventor.uniq_key 
			INNER JOIN customer 
			ON  Woentry.custno = Customer.custno
			-- 03/25/14 YS change inner join to left outer join for the depts table. Line shortages can be entered w/o depts
			LEFT OUTER JOIN DEPTS on KAMAIN.DEPT_ID =DEPTS.DEPT_ID 
			LEFT OUTER JOIN PJCTMAIN ON WOENTRY.PRJUNIQUE = PJCTMAIN.PRJUNIQUE  
			WHERE  Kamain.shortqty >  0.00 
			AND  Kamain.ignorekit =0
			AND  Kamain.uniq_key = @lcUniq_key
			AND  Woentry.openclos NOT IN ('Closed','Cancel') 
			AND  Woentry.balance <>  0 
	 ORDER BY Woentry.due_date, Customer.custname, Woentry.wono
END