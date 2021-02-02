-- =============================================
-- Author:		Yelena SHmidt
-- Create date: 
-- Description:	BOM for the given parent
---Modified: 03/17/2014 YS added lead time
-- =============================================
CREATE PROC [dbo].[Bom_det_view] @gUniq_key AS char(10) = ''
AS
SELECT Item_no, Part_sourc,CASE WHEN Inventor.part_sourc='CONSG' THEN Inventor.Custpartno ELSE Inventor.Part_no END  AS ViewPartNo,
CASE WHEN Inventor.part_sourc='CONSG' THEN Inventor.Custrev ELSE Inventor.Revision END AS ViewRev,
Part_class, Part_type, Descript, Qty, Part_no, Revision, CustPartno, Custrev, BomParent, Bom_det.Uniq_key,
Dept_id, Item_note, Offset, Term_dt, Eff_dt, Used_inKit,Inventor.Custno, Inv_note, U_of_meas, Scrap, Setupscrap,
UniqBomno, Phant_Make, StdCost, Make_buy, [Status],
 LeadTime = 
		CASE 
			WHEN Inventor.Part_Sourc = 'PHANTOM' THEN 0000
			WHEN Inventor.Part_Sourc = 'MAKE' AND Inventor.Make_Buy = 0 THEN 
				CASE 
					WHEN Inventor.Prod_lunit = 'DY' THEN Inventor.Prod_ltime
					WHEN Inventor.Prod_lunit = 'WK' THEN Inventor.Prod_ltime * 5
					WHEN Inventor.Prod_lunit = 'MO' THEN Inventor.Prod_ltime * 20
					ELSE Inventor.Prod_ltime
				END +
				CASE 
					WHEN Inventor.Kit_lunit = 'DY' THEN Inventor.Kit_ltime
					WHEN Inventor.Kit_lunit = 'WK' THEN Inventor.Kit_ltime * 5
					WHEN Inventor.Kit_lunit = 'MO' THEN Inventor.Kit_ltime * 20
					ELSE Inventor.Kit_ltime
				END
			ELSE
				CASE
					WHEN Inventor.Pur_lunit = 'DY' THEN Inventor.Pur_ltime
					WHEN Inventor.Pur_lunit = 'WK' THEN Inventor.Pur_ltime * 5
					WHEN Inventor.Pur_lunit = 'MO' THEN Inventor.Pur_ltime * 20
					ELSE Inventor.Pur_ltime
				END
		END
	FROM Bom_det, Inventor 
	WHERE Bom_det.Uniq_key = Inventor.Uniq_key
	AND Bom_det.BomParent = @gUniq_key
	ORDER BY Item_no