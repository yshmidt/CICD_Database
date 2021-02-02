-- =============================================
-- Author:		Satish Bhosle	
-- Create date: <03/08/16>
-- Description:	<Search kitting List Accourding Work Order Number>
-- =============================================
CREATE PROCEDURE sp_Get_KitListBy_WorkOrderNumber
	-- Add the parameters for the stored procedure here
       @gInput AS varchar(10)
AS
BEGIN

	SELECT DISTINCT  wo.WONO,wo.BLDQTY,i.REVISION,i.PART_NO,wo.OPENCLOS,c.CUSTNAME
    FROM WOENTRY wo
	INNER JOIN Inventor i ON i.UNIQ_KEY = wo.UNIQ_KEY
	INNER JOIN CUSTOMER C ON C.Custno = wo.CUSTNO
	INNER JOIN PJCTMAIN p on p.PRJUNIQUE=wo.PRJUNIQUE
    WHERE (wo.WONO LIKE '%' +@gInput+ '%')


END
