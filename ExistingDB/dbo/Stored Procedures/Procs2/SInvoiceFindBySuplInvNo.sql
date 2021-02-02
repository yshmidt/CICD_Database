-- =============================================
-- Author:		Bill Blake
-- Create date: ???
-- Description:	validate invoice number. Make sure that the same invoice is not entered twice for the same supplier
-- Modified: 08/16/16 YS We allow changign supplier in the manual apentry screen. The below procedure rely on the supplier
--- staying the same as in the pomain table. When this is not the case (paramit had an issue with inv # 156714), we will show 
-- false message. Use sinvoice table for records that are not in the apmaster yet, and use apmaster for the rest
-- =============================================
CREATE PROCEDURE [dbo].[SInvoiceFindBySuplInvNo] 
	-- Add the parameters for the stored procedure here
	-- 09/18/13 YS change @gcInvNo parameter from char(10) to char(20), we had changed the length of the invoice number, but this procedure did not change.
	@gcSinv_Uniq as char(10)=' ' ,@gcUniqSupNo as char(10) = ' ', @gcInvNo as char(20) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT SInvoice.InvNo
		from SINVOICE 
		where Sinvoice.INVNO = @gcInvNo
		and Sinvoice.Sinv_Uniq <> @gcSinv_Uniq
-- 08/16/16 YS Use sinvoice table for records that are not in the apmaster yet, and use apmaster for the rest
		and Sinvoice.fk_uniqaphead=''
		AND EXISTS (SELECT UniqSupno FROM POMAIN inner join POITEMS on Pomain.PONUM=poitems.PONUM 
						inner join PORECDTL on poitems.UNIQLNNO =porecdtl.UNIQLNNO and porecdtl.RECEIVERNO = sinvoice.receiverno 
						where pomain.UNIQSUPNO =@gcUniqSupNo)  
	UNION --- manual invoice only in the apmaster table no sinvoice records
	--- 08/16/16 YS Use sinvoice table for records that are not in the apmaster yet, and use apmaster for the rest. Remove aptype='manual'
	SELECT Invno from APMASTER WHERE INVNO=	@gcInvNo AND UniqSupno=@gcUniqSupNo 
	--and APTYPE='MANUAL'				
		
END