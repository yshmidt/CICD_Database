-- =============================================
-- Author:		Satish Bhosle	
-- Create date: <03/18/16>
-- Description:	<Get work order details> 
-- =============================================
--[GetWorkOrderDetails] '0000000149'
CREATE PROC [GetWorkOrderDetails] --'0000000149'
	-- Add the parameters for the stored procedure here
       @woNumber AS char(10)
AS
BEGIN
   SELECT wo.WONO,i.UNIQ_KEY,wo.BLDQTY,wo.KITSTATUS,wo.KITLSTCHDT,wo.KITLSTCHINIT,wo.START_DATE,wo.KITSTARTINIT,wo.KITCOMPLETE,wo.KITCOMPLDT,
      -- (CASE WHEN (RTRIM(wo.OPENCLOS)<>'Closed' OR RTRIM(wo.OPENCLOS) <>'Cancel') THEN wo.OPENCLOS ='Open' ELSE  wo.OPENCLOS), 
	  'OPENCLOS'= CASE wo.OPENCLOS WHEN 'Closed' THEN wo.OPENCLOS
	                                WHEN 'Cancel' THEN wo.OPENCLOS
									ELSE 'Open' END,
	   wo.KITCLOSEDT,wo.KITCLOSEINIT,wo.KITCOMPLINIT,
       i.PART_NO,i.REVISION,c.CUSTNAME,i.PART_CLASS,i.PART_TYPE,i.DESCRIPT,p.PRJNUMBER
		
	FROM WOENTRY wo
	INNER JOIN INVENTOR i ON i.UNIQ_KEY = wo.UNIQ_KEY
	INNER JOIN CUSTOMER C ON C.Custno = wo.CUSTNO
	LEFT OUTER JOIN PJCTMAIN p on p.PRJUNIQUE=wo.PRJUNIQUE
	WHERE  wo.WONO = @woNumber
END

