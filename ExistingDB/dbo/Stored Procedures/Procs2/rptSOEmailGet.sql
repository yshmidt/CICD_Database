-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/20/2013
-- Description:	Get e-mail address for the given Sales Order
-- 04/05/16 YS chnaged the SP to get the e-mail from the link in the sodetail table to the shipbill table
-- need to check how we use it and if we have the ship address maybe we should pass it along to the SP
-- =============================================
CREATE PROCEDURE [dbo].[rptSOEmailGet]
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
	
	

	select Somain.sono,
	cast(D.E_MAIL as varchar(max)) as toAddress  ,
	cast(D.name  as varchar(max)) AS name
	from Somain OUTER APPLY
	(select top 1 cast(  case when (ccontact.email is null or ccontact.email='') and shipbill.e_mail is not null then shipbill.e_mail 
		else isnull(ccontact.email,'') end as varchar(max)) as e_mail,
		cast(isnull(ccontact.firstname+' '+RTRIM(Ccontact.lastname),'') as varchar(max)) as name from sodetail inner join shipbill on sodetail.slinkadd=shipbill.linkadd 
	left outer join CCONTACT  on Shipbill.custno=Ccontact.Custno and Ccontact.type='C' and Shipbill.attention=Ccontact.cid
		where Shipbill.recordtype ='S' and sodetail.sono=@RecordNumber  and somain.sono=sodetail.sono order by slinkadd) D
	--LEFT outer join SHIPBILL ON Somain.custno=SHIPBILL.CUSTNO and 
	--somain.slinkadd =ShipBill.LINKADD and Shipbill.recordtype ='S'
	--LEFT OUTER JOIN CCONTACT on (Shipbill.custno+'C'+RTRIM(Shipbill.attention)) = ( Ccontact.custno+Ccontact.type+Ccontact.cid )
	where somain.SONO=@RecordNumber
	
END