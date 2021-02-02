------------------------------------------------------------------
-- Modification
-- 12/05/14 VL added Inventor.taxable
-- 04/06/17 VL added to show MPN values that Paramit request
------------------------------------------------------------------

CREATE PROC [dbo].[SodetailView] @lcSono AS char(10) = ''
AS
SELECT Sodetail.*, ISNULL(Part_no,SPACE(25)) AS Part_no, ISNULL(Revision,SPACE(8)) AS Revision, 
	ISNULL(Part_Class,SPACE(8)) AS Part_Class, ISNULL(Part_Type,SPACE(8)) AS Part_Type, 
	ISNULL(Descript,Sodet_Desc) AS Descript, ISNULL(U_of_meas,SPACE(4)) AS U_of_meas, 
	ISNULL(Custno, SPACE(10)) AS Custno, ISNULL(Part_Sourc, SPACE(10)) AS Part_Sourc,
	ISNULL(SerialYes,0) AS SerialYes, ISNULL(SaleTypeid, SPACE(10)) AS SaleTypeid, 
	ISNULL(Make_Buy,0) AS Make_Buy, ISNULL(MinOrd,0) AS MinOrd, ISNULL(OrdMult,0) AS OrdMult, ISNULL(Taxable,0) AS Taxable ,
	-- 04/06/17 VL added to show MPN values that Paramit request
	ISNULL(m.Partmfgr,SPACE(8)) AS Partmfgr, ISNULL(m.Mfgr_pt_no,SPACE(30)) AS Mfgr_pt_no, ISNULL(g.Location, SPACE(17)) AS Location
	FROM Sodetail LEFT OUTER JOIN Inventor 
	ON Sodetail.Uniq_key = Inventor.Uniq_key
	-- 04/06/17 VL added to show MPN values that Paramit request
	left outer join invtmfgr G on Sodetail.w_key=g.w_key
	left outer join Invtmpnlink l on g.uniqmfgrhd=l.uniqmfgrhd
	left outer join MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid
	WHERE Sono = @lcSono
	ORDER BY Line_no