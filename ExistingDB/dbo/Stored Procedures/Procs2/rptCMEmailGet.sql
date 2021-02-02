-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/20/2013
-- Description:	Get e-mail address for the given Credit memo
-- =============================================
CREATE PROCEDURE [dbo].[rptCMEmailGet]
	-- Add the parameters for the stored procedure here
	@RecordNumber varchar(10)=NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--- padl with '0'
	SET @RecordNumber = CASE WHEN @RecordNumber IS  NULL THEN @RecordNumber
		 WHEN LEFT(@RecordNumber,2)='CM' THEN @RecordNumber ELSE
		'CM'+ dbo.PADL(@RecordNumber,8,'0')  END 
    -- Insert statements for procedure here
	
	
	select CMMAIN.CMEMONO ,
	CAST(CASE WHEN CCONTACT.EMAIL IS null THEN ISNULL(ShipBill.E_MAIL,'') ELSE ccontact.EMAIL END as varchar(max)) as toAddress  ,
	cast(CASE WHEN Ccontact.firstname is null THEN '' ELSE RTRIM(Ccontact.firstname)+' '+RTRIM(Ccontact.lastname) end as varchar(max)) AS name
	from cmmain 
	LEFT outer join SHIPBILL ON CMMAIN.custno=SHIPBILL.CUSTNO and 
	cmmain.Blinkadd =ShipBill.LINKADD and Shipbill.recordtype ='B'
	LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'C'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )
	where cmmain.CMEMONO =@RecordNumber
	
	
END