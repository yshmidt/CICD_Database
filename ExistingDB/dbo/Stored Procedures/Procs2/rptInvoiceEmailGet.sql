-- =============================================      
-- Author:  Yelena Shmidt      
-- Create date: 07/20/2013      
-- Description: Get e-mail address for the given Invoice Number      
--- 06/22/17 YS show invoice number instead of packing list number      
-- 03/31/2020 YS changed relationship between address and contact      
-- 05/01/2020 YS concatenate email address from all addresses linked to the bill to  
-- 05/04/2020 Satyawan H: if email is empty pass NULL otherwise pass email as it is
-- =============================================      
CREATE PROCEDURE [dbo].[rptInvoiceEmailGet]  
 -- Add the parameters for the stored procedure here      
 @RecordNumber varchar(10)=NULL      
AS      
BEGIN      
 -- SET NOCOUNT ON added to prevent extra result sets from      
 -- interfering with SELECT statements.      
 SET NOCOUNT ON;      
 --- padl with '0'      
 SET @RecordNumber = CASE WHEN @RecordNumber IS NOT NULL THEN dbo.PADL(@RecordNumber,10,'0') ELSE @RecordNumber END       
    -- Insert statements for procedure here      
       
 --- 06/22/17 YS show invoice number instead of packing list number      
 -- 03/31/2020 YS changed relationship between address and contact      
 --select INVOICENO,      
 --CAST(CASE WHEN CCONTACT.EMAIL IS null THEN ISNULL(ShipBill.E_MAIL,'') ELSE ccontact.EMAIL END as varchar(max)) as toAddress  ,      
 --cast(CASE WHEN Ccontact.firstname is null THEN '' ELSE RTRIM(Ccontact.firstname)+' '+RTRIM(Ccontact.lastname) end as varchar(max)) AS name      
 --from plmain       
 --LEFT outer join SHIPBILL ON plmain.custno=SHIPBILL.CUSTNO and       
 --plmain.Blinkadd =ShipBill.LINKADD and Shipbill.recordtype ='B'      
 --LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'C'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )      
 --where plmain.Invoiceno=@RecordNumber      
 --- new code      
 -- 05/01/2020 YS concatenate email address from all addresses linked to the same bill to      
 ;WITH      
 result       
 AS      
 (      
	 SELECT INVOICENO,plmain.BLINKADD,      
	 CAST(ISNULL(c.EMAIL,ISNULL(shipbill.e_mail,'')) AS VARCHAR(max)) AS toAddress,      
	 cast(ISNULL(RTRIM(C.firstname)+' '+RTRIM(C.lastname),'') AS VARCHAR(max)) AS NAME      
	 --CAST(CASE WHEN CCONTACT.EMAIL IS null THEN ISNULL(ShipBill.E_MAIL,'') ELSE ccontact.EMAIL END as varchar(max)) as toAddress  ,      
	 --cast(CASE WHEN Ccontact.firstname is null THEN '' ELSE RTRIM(Ccontact.firstname)+' '+RTRIM(Ccontact.lastname) end as varchar(max)) AS name      
	 FROM plmain 
	 LEFT OUTER JOIN SHIPBILL ON plmain.custno=SHIPBILL.CUSTNO AND plmain.Blinkadd =ShipBill.LINKADD and Shipbill.recordtype ='B'      
	 --LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'C'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )      
	 OUTER APPLY       
	 (  
		 -- 05/04/2020 Satyawan H: if email is empty pass NULL otherwise pass email as it is
		 SELECT cc.cid,lastname,firstname,IIF(TRIM(email)='',NULL,email) email,custno 
		 FROM CCONTACT cc 
		 INNER JOIN BillingContactLink bl ON cc.cid=bl.cid and bl.BillRemitAddess=plmain.BLINKADD
	 ) c      
     WHERE plmain.Invoiceno=@RecordNumber      
 )      
       
 SELECT DISTINCT INVOICENO,BLINKADD,      
 STUFF(      
 (      
  SELECT ','+toAddress       
  FROM result r1 WHERE  r1.BLINKADD=r2.BLINKADD      
  ORDER BY r1.NAME      
  FOR XML PATH('')      
  ), 1,1,'') [toAddress]      
 FROM result R2       
END