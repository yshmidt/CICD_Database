
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <02/24/2010>
-- Description:	<CustRefView>
-- =============================================
CREATE PROCEDURE [dbo].[CustRefView] 
	-- Add the parameters for the stored procedure here
@gUniq_key as char(10)=''	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Inventor.part_class, Inventor.uniq_key, Inventor.part_type,
  Inventor.custno, Inventor.part_no, Inventor.revision, Inventor.prod_id,
  Inventor.custpartno, Inventor.custrev, Inventor.descript,
  Inventor.u_of_meas, Inventor.pur_uofm, Inventor.ord_policy,
  Inventor.package, Inventor.no_pkg, Inventor.inv_note,
  Inventor.buyer_type, Inventor.stdcost, Inventor.minord, Inventor.ordmult,
  Inventor.usercost, Inventor.pull_in, Inventor.push_out,
  Inventor.ptlength, Inventor.ptwidth, Inventor.ptdepth, Inventor.fginote,
  Inventor.status, Inventor.perpanel, Inventor.abc, Inventor.layer,
  Inventor.ptwt, Inventor.grosswt, Inventor.reorderqty,
  Inventor.reordpoint, Inventor.part_spec, Inventor.pur_ltime,
  Inventor.pur_lunit, Inventor.kit_ltime, Inventor.kit_lunit,
  Inventor.prod_ltime, Inventor.prod_lunit, Inventor.udffield1,
  Inventor.wt_avg, Inventor.part_sourc, Inventor.insp_req,
  Inventor.cert_req, Inventor.cert_type, Inventor.scrap,
  Inventor.setupscrap, Inventor.outsnote, Inventor.bom_status,
  Inventor.bom_note, Inventor.bom_lastdt, Inventor.serialyes,
  Inventor.loc_type, Inventor.day, Inventor.dayofmo, Inventor.dayofmo2,
  Inventor.saletypeid, Inventor.feedback, 
  Inventor.eng_note, Inventor.bomcustno, Inventor.laborcost,
  Inventor.int_uniq, Customer.custname, Inventor.matltype,
  Inventor.mtchgdt, Inventor.mtchginit
 FROM inventor  INNER JOIN customer 
   ON  Inventor.custno = Customer.custno
 WHERE   Inventor.int_uniq = @gUniq_key 
   AND  Inventor.int_uniq <> SPACE(10)
   AND  Inventor.part_sourc =  'CONSG'
END