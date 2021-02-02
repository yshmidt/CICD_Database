CREATE PROCEDURE [dbo].[SinvoiceView]
	-- Add the parameters for the stored procedure here
	@lcSinv_uniq char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 11/16/16 VL added InvamountFC and InvAmountPR
	SELECT Sinv_uniq,SINVOICE.fk_uniqaphead,Sinvoice.ReceiverNo,INVNO,SINVOICE.IS_REL_AP, INVAMOUNT, INVAMOUNTFC, INVAMOUNTPR 
		FROM SINVOICE 
		WHERE SINV_UNIQ =@lcSinv_uniq 
END