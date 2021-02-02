-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- 11/20/14 VL added taxable for GST project
-- Modidifed: 02/26/18: Vijay G: To get part type on the basis of provided part type parameter. 
-- =============================================
CREATE proc [dbo].[Part_type_view] (@gcPart_class CHAR(8) ='',@partType VARCHAR(8) = '' )
AS
BEGIN
-- 02/26/18: Vijay G: Get parttype on the basis of partclass parameter and part type name. If part type parameter value is empty then get all part type list for provided part class.
IF @partType <> ''
 SELECT Parttype.uniqptype, Parttype.part_class, Parttype.part_type,
  Parttype.prefix, Parttype.template, Parttype.part_pkg, Parttype.package,
  Parttype.u_of_meas, Parttype.pur_uofm, Parttype.ord_policy,
  Parttype.buyer_type, Parttype.reordpoint, Parttype.minord,
  Parttype.ordmult, Parttype.abc, Parttype.reorderqty, Parttype.insp_req,
  Parttype.cert_req, Parttype.cert_type, Parttype.scrap,
  Parttype.setupscrap, Parttype.loc_type, Parttype.number,
  Parttype.pur_ltime, Parttype.pur_lunit, Parttype.kit_ltime,
  Parttype.kit_lunit, Parttype.prod_ltime, Parttype.prod_lunit,
  Parttype.pull_in, Parttype.push_out, Parttype.ord_freq, Parttype.day,
  Parttype.dayofmo, Parttype.dayofmo2, Parttype.lotdetail, Parttype.autodt,
  Parttype.fgiexpdays, Parttype.stdcost, Parttype.matl_cost,
  Parttype.other_cost, Parttype.overhead, Parttype.laborcost,
  Parttype.autonum, Parttype.mrc, Parttype.autolocation,
  Parttype.othercost2, Parttype.targetprice, Parttype.Taxable
 FROM parttype
 WHERE  Parttype.part_class = @gcPart_Class AND Parttype.part_type LIKE '%'+ @partType +'%'
 ORDER BY Parttype.number
ELSE
 SELECT Parttype.uniqptype, Parttype.part_class, Parttype.part_type,
  Parttype.prefix, Parttype.template, Parttype.part_pkg, Parttype.package,
  Parttype.u_of_meas, Parttype.pur_uofm, Parttype.ord_policy,
  Parttype.buyer_type, Parttype.reordpoint, Parttype.minord,
  Parttype.ordmult, Parttype.abc, Parttype.reorderqty, Parttype.insp_req,
  Parttype.cert_req, Parttype.cert_type, Parttype.scrap,
  Parttype.setupscrap, Parttype.loc_type, Parttype.number,
  Parttype.pur_ltime, Parttype.pur_lunit, Parttype.kit_ltime,
  Parttype.kit_lunit, Parttype.prod_ltime, Parttype.prod_lunit,
  Parttype.pull_in, Parttype.push_out, Parttype.ord_freq, Parttype.day,
  Parttype.dayofmo, Parttype.dayofmo2, Parttype.lotdetail, Parttype.autodt,
  Parttype.fgiexpdays, Parttype.stdcost, Parttype.matl_cost,
  Parttype.other_cost, Parttype.overhead, Parttype.laborcost,
  Parttype.autonum, Parttype.mrc, Parttype.autolocation,
  Parttype.othercost2, Parttype.targetprice, Parttype.Taxable
 FROM 
     parttype
 WHERE  Parttype.part_class = @gcPart_Class 
 ORDER BY Parttype.number
END