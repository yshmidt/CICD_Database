CREATE PROCEDURE [dbo].[Sinvoice_Mast_view]
	-- Add the parameters for the stored procedure here
	@gcsinv_uniq as char(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  -- Insert statements for procedure here
  -- 02/05/15 VL added FC fields:SubtotalFC, TaxFC, FreightFC, InvAmountFC, DiscountFC, FrtTaxAmtFC, FcUsed_uniq and Fchist_key
  -- 11/16/16 VL added presentation fields
  SELECT  Sinvoice.sinv_uniq,  pOrder.ponum,
  Sinvoice.transno, Sinvoice.trans_dt, Sinvoice.Suppkno, Sinvoice.invno,
  Sinvoice.terms, Sinvoice.due_date,
  pOrder.Date, Sinvoice.subtotal, Sinvoice.tax, Sinvoice.freight,
  Sinvoice.invdate, Sinvoice.invamount, Sinvoice.aptype,
  Sinvoice.freightgl, Sinvoice.is_rel_gl, Sinvoice.recon_date,
  Sinvoice.saveinit, Sinvoice.discount, Sinvoice.vdisc_gl_n, Sinvoice.fob,
  Sinvoice.shipvia, Sinvoice.invnote, Sinvoice.frttaxamt,
  Sinvoice.frttaxgl, Sinvoice.is_rel_ap,  Sinvoice.tax_pct,Sinvoice.receiverno,
  pOrder.supname, pOrder.recontodt, pOrder.lfreightinclude, ENTRYDATE,sinvoice.fk_uniqaphead,Sinvoice.recver,
  SubtotalFC, TaxFC, FreightFC, InvAmountFC, DiscountFC, FrtTaxAmtFC, FcUsed_uniq, Fchist_key,
  SubtotalPR, TaxPR, FreightPR, InvAmountPR, DiscountPR, FrtTaxAmtPR, PRFcused_uniq, FuncFcused_uniq
 FROM 
    sinvoice 
    inner join 
    ( select DISTINCT Pomain.ponum,MIN(Porecdtl.RecvDate) AS Date,Pomain.recontodt, Pomain.lfreightinclude, Supinfo.supname,porecloc.SINV_UNIQ
    from POMAIN inner join POITEMS on pomain.PONUM=POITEMS.PONUM
    INNER JOIN PORECDTL on poitems.UNIQLNNO =porecdtl.UNIQLNNO 
    INNER JOIN PORECLOC on porecdtl.UNIQRECDTL =PORECLOC.FK_UNIQRECDTL  
    INNER JOIN SUPINFO on pomain.UNIQSUPNO =Supinfo.UNIQSUPNO 
    WHERE porecloc.SINV_UNIQ = @gcsinv_uniq  GROUP BY Pomain.ponum,Pomain.recontodt, Pomain.lfreightinclude, Supinfo.supname,porecloc.SINV_UNIQ ) as pOrder
    ON sinvoice.SINV_UNIQ =pOrder.SINV_UNIQ 
      WHERE  Sinvoice.sinv_uniq = @gcsinv_uniq
    
    
   
END