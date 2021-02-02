-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/21/2013
-- Description:	Get e-mail address for the given Debit Memo
-- =============================================
CREATE PROCEDURE [dbo].[rptDMEmailGet]
	-- Add the parameters for the stored procedure here
	@RecordNumber varchar(10)=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--- padl with '0'
	SET @RecordNumber = CASE WHEN @RecordNumber IS NULL THEN @RecordNumber
			WHEN LEFT(@RecordNumber,2)='DM' THEN @RecordNumber ELSE 'DM'+dbo.PADL(@RecordNumber,8,'0') END 
	
    -- Insert statements for procedure here
	select DMEMOS.DMEMONO ,
	CAST(CASE WHEN CCONTACT.EMAIL IS null THEN ISNULL(ShipBill.E_MAIL,'') ELSE ccontact.EMAIL END as varchar(max)) as toAddress  ,
	cast(CASE WHEN Ccontact.firstname is null THEN '' ELSE RTRIM(Ccontact.firstname)+' '+RTRIM(Ccontact.lastname) end as varchar(max)) AS name
	from DMEMOS  inner join SUPINFO on dmemos.UNIQSUPNO =SUPINFO.uniqsupno
	LEFT outer join SHIPBILL ON SUPINFO.supid=SHIPBILL.CUSTNO and 
	Supinfo.C_LINK =ShipBill.LINKADD and Shipbill.recordtype ='C'
	LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'S'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )
	where dmemos.DMEMONO  =@RecordNumber
	
	
	
	
	
END