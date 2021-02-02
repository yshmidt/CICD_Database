-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/18/2013
-- Description:	Get e-mail address for the given PO
-- =============================================
CREATE PROCEDURE [dbo].[rptPOEmailGet]
	-- Add the parameters for the stored procedure here
	@RecordNumber varchar(15)=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--- padl with '0'
	SET @RecordNumber = CASE WHEN @RecordNumber IS NOT NULL THEN dbo.PADL(@RecordNumber,15,'0') ELSE @RecordNumber END 
    -- Insert statements for procedure here
	select pomain.PONUM,
	CAST(CASE WHEN CCONTACT.EMAIL IS null THEN ISNULL(ShipBill.E_MAIL,'') ELSE ccontact.EMAIL END as varchar(max)) as toAddress  ,
	cast(CASE WHEN Ccontact.firstname is null THEN '' ELSE RTRIM(Ccontact.firstname)+' '+RTRIM(Ccontact.lastname) end as varchar(max)) AS name
	from POMAIN inner join SUPINFO on pomain.UNIQSUPNO =SUPINFO.uniqsupno
	LEFT outer join SHIPBILL ON SUPINFO.supid=SHIPBILL.CUSTNO and 
	Pomain.C_LINK =ShipBill.LINKADD and Shipbill.recordtype ='C'
	LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'S'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )
	where pomain.PONUM =@RecordNumber
	
	
END