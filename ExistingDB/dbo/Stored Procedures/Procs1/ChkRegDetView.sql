
CREATE PROCEDURE [dbo].[ChkRegDetView]
	-- Add the parameters for the stored procedure here
	@gcChkRegUniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/23/15 VL added FC fields
	-- 02/07/17 VL added functional currency code
SELECT Apchkdet.item_no, Apchkdet.ponum, Apchkdet.invno,
  Apchkdet.invdate, Apchkdet.due_date, Apchkdet.item_desc,
  Apchkdet.invamount, Apchkdet.disc_tkn, Apchkdet.aprpay,
  Apchkdet.apchk_uniq, Apchkdet.itemnote, 
  Apchkdet.invamountFC, Apchkdet.disc_tknFC, Apchkdet.aprpayFC,
  Apchkdet.invamountPR, Apchkdet.disc_tknPR, Apchkdet.aprpayPR
 FROM
     apchkdet
 WHERE  Apchkdet.apchk_uniq = @gcChkRegUniq
 ORDER BY Apchkdet.item_no

END