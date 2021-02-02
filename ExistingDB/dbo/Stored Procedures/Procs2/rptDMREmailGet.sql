-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/18/2013
-- Description:	Get e-mail address for the given DMR number
-- =============================================
CREATE PROCEDURE [dbo].[rptDMREmailGet]
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
	select  Porecmrb.Dmr_no,
		CAST(CASE WHEN ISNULL(CD.EMAIL,SD.E_MAIL) IS NOT NULL THEN ISNULL(CD.EMAIL,SD.E_MAIL)
		WHEN ISNULL(CP.EMAIL ,SP.E_MAIL ) IS NOT NULL THEN ISNULL(CP.EMAIL ,SP.E_MAIL ) ELSE '' END as varchar(max)) as e_mail,
		cast(CASE WHEN ISNULL(CD.firstname,CP.FirstName) is null THEN '' 
				ELSE RTRIM(ISNULL(CD.firstname,Cp.firstname))+' '+RTRIM(ISNULL(cd.lastname,cp.lastname)) end as varchar(max)) AS name
		from porecmrb inner join PORECDTL on porecmrb.FK_UNIQRECDTL = porecdtl.UNIQRECDTL 
	inner join POITEMS on porecdtl.UNIQLNNO =poitems.uniqlnno
	inner join POMAIN on poitems.PONUM=pomain.ponum
	LEFT OUTER JOIN SHIPBILL SD on Porecmrb.LINKADD=SD.LINKADD and SD.RECORDTYPE ='C'
	LEFT OUTER JOIN SHIPBILL SP on Pomain.C_LINK=SP.LINKADD and sp.RECORDTYPE ='C'
	LEFT OUTER JOIN CCONTACT CD on (SD.custno+'S'+RTRIM(SD.attention)) = ( CD.custno+CD.type+CD.cid )
	LEFT OUTER JOIN CCONTACT CP on (SP.custno+'S'+RTRIM(SP.attention)) = ( CP.custno+CP.type+CP.cid )
	where DMR_NO=@RecordNumber 
	
	
END