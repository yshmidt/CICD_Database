-- =============================================
-- Author:		Bill Blake
-- Create date: ??
-- Description:	get AP check details
-- 10/09/15 VL rename Orig_Fchkey to Orig_Fchist_key
-- 08/18/16 VL added 0000000000.00 as AprpayBc to temporarily save bank currency value calculate on the fly 
-- 08/23/16	VL Changed AprpayBC from 0000000000.00 to CAST(0 AS numeric(12,2))
-- 02/07/17 VL Added functional currency changes
-- =============================================
CREATE PROCEDURE [dbo].[ApChkDetNewView]
	-- Add the parameters for the stored procedure here
	@gcApchk_Uniq AS char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    -- -3/15/12 YS added information from apmaster. Use to do it in the screen itself
	-- 05/16/15 VL added FC fields
	-- 02/07/17 VL added functional currency codes
SELECT Apchkdet.apckd_uniq, Apchkdet.apchk_uniq, Apchkdet.aprpay,
  Apchkdet.disc_tkn, ISNULL(Apmaster.Invno,Apchkdet.invno) as Invno, 
  Apchkdet.invamount,
  Apchkdet.item_desc, Apchkdet.gl_nbr, Apchkdet.uniqaphead,
  Apchkdet.item_no, Apchkdet.itemnote,
  GL_NBRS.Gl_Descr, Apchkdet.balance, 
  ISNULL(Apmaster.Ponum,Apchkdet.ponum) as PoNum, Apchkdet.invdate, Apchkdet.due_date,
  Apchkdet.aprpayFC, Apchkdet.disc_tknFC, Apchkdet.invamountFC, Apchkdet.balanceFC, Apchkdet.Orig_Fchist_key, CAST(0 AS numeric(12,2)) as AprpayBc,
  Apchkdet.aprpayPR, Apchkdet.disc_tknPR, Apchkdet.invamountPR, Apchkdet.balancePR
 FROM
     apchkdet 
    LEFT OUTER JOIN Gl_Nbrs  ON  Apchkdet.Gl_nbr = GL_NBRS.Gl_Nbr 
    LEFT OUTER JOIN APMASTER ON ApchkDet.UNIQAPHEAD =APMASTER.UNIQAPHEAD  
 WHERE  Apchkdet.apchk_uniq = @gcApchk_Uniq
   AND  Apchkdet.apchk_uniq <> ' '
END