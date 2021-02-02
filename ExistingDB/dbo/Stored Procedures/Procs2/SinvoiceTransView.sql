-- =============================================
-- Author:		???
-- Create date: ???
-- Description:	Get information for the reconciled and not transferred to AP invoices
-- Modified: --02/12/15 YS added because paramit had many records with the receiverno for different PO. Maybe service PO
 -- but not sure how we get that yet or if it is still a problem
 -- 02/09/15 VL added FC fields
-- 06/16/15 VL added symbol field and Fcused table
-- 11/16/16 VL added presentation fields
-- =============================================
CREATE PROCEDURE [dbo].[SinvoiceTransView]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- 02/09/15 VL added FC fields
	-- 06/16/15 VL added symbol field and Fcused table
	SELECT distinct Sinvoice.sinv_uniq, Sinvoice.invno, POMAIN.ponum,
  Sinvoice.due_date, Sinvoice.invamount, Sinvoice.is_rel_ap,
  Sinvoice.recon_date, Supinfo.supname, 
  Supinfo.uniqsupno, Sinvoice.subtotal, Sinvoice.tax, Sinvoice.freight,
  Sinvoice.invdate, Sinvoice.terms, Pomain.c_link, Pomain.r_link,
  Sinvoice.transno, Sinvoice.trans_dt, Sinvoice.suppkno,
  Sinvoice.EntryDate, Sinvoice.freightgl, Sinvoice.aptype,
  Sinvoice.is_rel_gl, Sinvoice.saveinit, Sinvoice.discount,
  Sinvoice.vdisc_gl_n, Sinvoice.fob, Sinvoice.shipvia,
  Sinvoice.frttaxamt, Sinvoice.frttaxgl, Sinvoice.tax_pct, Sinvoice.Fk_uniqAPhead,
  Sinvoice.invamountFC,  Sinvoice.subtotalFC, Sinvoice.taxFC, Sinvoice.freightFC, 
  Sinvoice.discountFC, Sinvoice.frttaxamtFC, Sinvoice.FcUsed_uniq, Sinvoice.Fchist_key, 
  CASE WHEN Sinvoice.Fcused_Uniq = '' THEN SPACE(3) ELSE FcUsed.Symbol END AS Symbol,
  Sinvoice.invamountPR,  Sinvoice.subtotalPR, Sinvoice.taxPR, Sinvoice.freightPR, 
  Sinvoice.discountPR, Sinvoice.frttaxamtPR, Sinvoice.PRFcused_uniq, Sinvoice.FuncFcused_uniq
 FROM 
     Sinvoice 
    INNER JOIN  PoRecdtl 
    ON  PORECDTL.RECEIVERNO = Sinvoice.receiverno
    inner join POItems
    on  PORECDTL.UNIQLNNO = POITEMS.UNIQLNNO 
    inner join PoMain
    on POMAIN.PONUM = POITEMS.PONUM 
    inner join SUPINFO
    on SUPINFO.UNIQSUPNO = POMAIN.UNIQSUPNO
	LEFT OUTER JOIN Fcused
	ON Sinvoice.Fcused_uniq = Fcused.FcUsed_Uniq 
 WHERE  Sinvoice.is_rel_ap <> 1
 --02/12/15 YS added because paramit had many records with the receiverno for different PO. Maybe service PO
 -- but not sure how we get that yet or if it is still a problem
 and exists (select 1 from porecloc inner join sinvdetl on sinvdetl.LOC_UNIQ=porecloc.LOC_UNIQ 
	where  porecloc.FK_UNIQRECDTL=porecdtl.uniqrecdtl and sinvdetl.SINV_UNIQ=sinvoice.sinv_uniq)
END