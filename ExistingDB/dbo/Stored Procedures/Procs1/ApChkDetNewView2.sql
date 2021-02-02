-- =============================================
-- Author:		Bill Blake
-- Create date: ??
-- Description:	get AP check detail
-- 10/09/15 VL rename Orig_Fchkey to Orig_Fchist_key
-- 02/07/17 VL added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[ApChkDetNewView2]
	-- Add the parameters for the stored procedure here
	@gcApchk_Uniq AS char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 07/17/15 VL added FC fields
SELECT Apchkdet.apckd_uniq, Apchkdet.apchk_uniq, Apchkdet.aprpay,
  Apchkdet.disc_tkn, Apchkdet.invno, Apchkdet.invamount,
  Apchkdet.item_desc, Apchkdet.gl_nbr, Apchkdet.uniqaphead,
  Apchkdet.item_no,  Apchkdet.itemnote,
  GL_NBRS.Gl_Descr, Apchkdet.balance, 
  Apchkdet.ponum, Apchkdet.invdate, Apchkdet.due_date,
  Apchkdet.aprpayFC, Apchkdet.disc_tknFC, Apchkdet.invamountFC, Apchkdet.balanceFC, ApChkdet.Orig_Fchist_key,
  -- 02/07/17 VL added functional currency code
  Apchkdet.aprpayPR, Apchkdet.disc_tknPR, Apchkdet.invamountPR, Apchkdet.balancePR
 FROM
     apchkdet 
    LEFT OUTER JOIN Gl_Nbrs 
   ON  Apchkdet.Gl_nbr = GL_NBRS.Gl_Nbr 
 WHERE  Apchkdet.apchk_uniq = @gcApchk_Uniq
   AND  Apchkdet.apchk_uniq <> ' '
END