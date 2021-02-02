-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/02/2011>
-- Description:	<Drill Down into CM transactions>
-- Modification:
-- 09/15/15 VL Added FC fields
-- 05/27/16 VL: added if FC installed or not to separate the SQL because FC requires to join with Fcused to get currency
-- 12/13/16 VL: added presentation currency fields
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownCM]
	-- Add the parameters for the stored procedure here
	@cmunique char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- 05/27/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
		-- Insert statements for procedure here
		select customer.custname,cmmain.CMEMONO,cmmain.IS_RMA ,
	CASE WHEN cmmain.is_rma = 0 THEN cmmain.SONO ELSE cast(' ' as char(10)) END as Sono,
	CASE WHEN cmmain.is_rma = 1 THEN cmmain.SONO ELSE cast(' ' as char(10)) END as RMANO,
	case when CMTYPE='M' then 'General' ELSE 'Invoice' END as CM_Type, 
	case when CMTYPE='M' then CAST(' ' as CHAR(10)) ELSE cmmain.INVOICENO END as invoiceno,
	case when CMTYPE='M' then CAST(' ' as CHAR(10)) ELSE cmmain.PACKLISTNO  END as packlistno,
	cmmain.CMDATE,cmmain.CUSTNO,cmmain.CM_FRT,cmmain.CM_FRT_TAX,cmmain.CMTOTEXTEN,cmmain.CMTOTAL,cmmain.TOTTAXE,CMREASON,   
	cmprices.DESCRIPT,CMQUANTITY,CMPRICE ,CMEXTENDED,TAXABLE,
	CM_FRTFC,cmmain.CM_FRT_TAXFC,cmmain.CMTOTEXTENFC,cmmain.CMTOTALFC,cmmain.TOTTAXEFC, CMPRICEFC, CMEXTENDEDFC  
	from CMMAIN inner join CUSTOMER on cmmain.CUSTNO =customer.CUSTNO  
	INNER JOIN CMPRICES on cmmain.CMUNIQUE = cmprices.cmunique 
	where cmmain.cmunique=@cmunique
ELSE
	   -- Insert statements for procedure here
		select customer.custname,cmmain.CMEMONO,cmmain.IS_RMA ,
	CASE WHEN cmmain.is_rma = 0 THEN cmmain.SONO ELSE cast(' ' as char(10)) END as Sono,
	CASE WHEN cmmain.is_rma = 1 THEN cmmain.SONO ELSE cast(' ' as char(10)) END as RMANO,
	case when CMTYPE='M' then 'General' ELSE 'Invoice' END as CM_Type, 
	case when CMTYPE='M' then CAST(' ' as CHAR(10)) ELSE cmmain.INVOICENO END as invoiceno,
	case when CMTYPE='M' then CAST(' ' as CHAR(10)) ELSE cmmain.PACKLISTNO  END as packlistno,
	cmmain.CMDATE,cmmain.CUSTNO,cmmain.CM_FRT,cmmain.CM_FRT_TAX,cmmain.CMTOTEXTEN,cmmain.CMTOTAL,cmmain.TOTTAXE,CMREASON,   
	cmprices.DESCRIPT,CMQUANTITY,CMPRICE ,CMEXTENDED,FF.Symbol AS Functional_Currency,TAXABLE,
	CM_FRTFC,cmmain.CM_FRT_TAXFC,cmmain.CMTOTEXTENFC,cmmain.CMTOTALFC,cmmain.TOTTAXEFC, CMPRICEFC, CMEXTENDEDFC, TF.Symbol AS Transaction_Currency,   
	CM_FRTPR,cmmain.CM_FRT_TAXPR,cmmain.CMTOTEXTENPR,cmmain.CMTOTALPR,cmmain.TOTTAXEPR, CMPRICEPR, CMEXTENDEDPR, PF.Symbol AS Presentation_Currency
	from Cmmain
				INNER JOIN Fcused TF ON Cmmain.Fcused_uniq = TF.Fcused_uniq
				INNER JOIN Fcused PF ON Cmmain.PrFcused_uniq = PF.Fcused_uniq
				INNER JOIN Fcused FF ON Cmmain.FuncFcused_uniq = FF.Fcused_uniq
	inner join CUSTOMER on cmmain.CUSTNO =customer.CUSTNO  
	INNER JOIN CMPRICES on cmmain.CMUNIQUE = cmprices.cmunique 
	where cmmain.cmunique=@cmunique

END