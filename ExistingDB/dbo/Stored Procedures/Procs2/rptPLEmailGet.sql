-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/20/2013
-- Description:	Get e-mail address for the given Packing List
-- =============================================
CREATE PROCEDURE [dbo].[rptPLEmailGet]
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
	
	
	select packlistno,
	CAST(CASE WHEN CCONTACT.EMAIL IS null THEN ISNULL(ShipBill.E_MAIL,'') ELSE ccontact.EMAIL END as varchar(max)) as toAddress  ,
	cast(CASE WHEN Ccontact.firstname is null THEN '' ELSE RTRIM(Ccontact.firstname)+' '+RTRIM(Ccontact.lastname) end as varchar(max)) AS name
	from plmain 
	LEFT outer join SHIPBILL ON plmain.custno=SHIPBILL.CUSTNO and 
	plmain.linkadd =ShipBill.LINKADD and Shipbill.recordtype ='S'
	LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'C'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )
	where plmain.PACKLISTNO=@RecordNumber
	
	
END