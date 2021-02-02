-- =============================================
-- Author:		Anuj Kumar
-- Create date: <11/30/2015>
-- Description:	Get Item information by packing list number
-- =============================================
-- 2/12/2016 Anuj: Get the quantity from PlPrices table only.
CREATE PROCEDURE GetItemByPackingList 
@packingListNo char(10)
AS
BEGIN
	select distinct pl.PACKLISTNO, inv.PART_NO , isu.GL_NBR_INV as 'WH_GL_NBR', sp.COG_GL_NBR, 
	CASE WHEN sd.sono <>'' THEN sp.PL_GL_NBR	ELSE pd.plpl_gl_nbr END as Gl_NBR,
	CASE WHEN sd.UNIQ_KEY<>'' THEN 
		('Part No: ' + inv.PART_NO + 'Revision: ' + inv.REVISION + 'Class: ' + inv.PART_CLASS + 'Type: ' + inv.PART_TYPE + 'DESCRIPTION: ' + inv.DESCRIPT)
	WHEN sd.UNIQ_KEY='' THEN sd.Sodet_Desc ELSE pl.DESCRIPT	END as DESCRIPT
	,pl.PRICE,
	-- 2/12/2016 Anuj: Get the quantity from PlPrices table only.
	--CASE WHEN sd.UNIQ_KEY='' OR sd.UNIQ_KEY IS NULL THEN pl.QUANTITY ELSE isu.QTYISU END as QUANTITY, 
	pl.QUANTITY  as QUANTITY,
	pl.FLAT, sd.UNIQ_KEY as UniqKey,
	sd.sono
	 from 
PLPRICES pl left outer join SOPRICES sp on pl.PLPRICELNK = sp.PLPRICELNK
left outer join PLDETAIL pd on pl.PACKLISTNO = pd.PACKLISTNO and pl.UNIQUELN = pd.UNIQUELN
left outer join SODETAIL sd on  pl.UNIQUELN=sd.UNIQUELN 
left outer join INVT_ISU isu on  sd.UNIQ_KEY=isu.UNIQ_KEY and isu.ISSUEDTO = 'REQ PKLST-'+pl.packlistno
left outer join INVENTOR inv on sd.UNIQ_KEY=inv.uniq_key
--left outer join INVTMFGR mfgr on isu.w_key=mfgr.W_KEY
--left outer join WAREHOUS w on mfgr.UNIQWH=w.UNIQWH 
where pl.PACKLISTNO = @packingListNo
END
