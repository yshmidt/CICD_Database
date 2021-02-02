CREATE PROC [dbo].[KitMainView] @gWono AS char(10) = ''
AS
--- 06/13/18 YS no rej_qty, Rej_date, Rej_reson in the kamain table. Structure changed
-- 08/08/20 VL Changed to add AllocatedQty and UserId which are new fields added in Kamain

DECLARE @WoUniq_key char(10);

SELECT @WoUniq_key = Uniq_key FROM WOENTRY WHERE WONO = @gWono;

SELECT DispPart_no = 
	CASE Inventor.Part_sourc
		WHEN 'CONSG' THEN Inventor.CustPartNo
		ELSE Inventor.Part_no
	END, Kamain.shortqty+Kamain.act_qty AS Req_Qty,
	Phantom = 
	CASE Kamain.lineshort	
		WHEN 1 THEN 's'
		ELSE
			CASE @WoUniq_key
				WHEN Kamain.BomParent THEN ' '
				ELSE 'f'
			END
	END,
	DispRevision = 
	CASE Inventor.Part_sourc
		WHEN 'CONSG' THEN Inventor.Custrev
		ELSE Inventor.Revision
	END,
    Part_class, Part_type, Kaseqnum, Entrydate, Initials, 
	--- 06/13/18 YS no rej_qty, Rej_date, Rej_reson in the kamain table. Structure changed
	---Rej_qty, Rej_date, Rej_reson, 
	Kitclosed, 
	Act_qty, Kamain.Uniq_key, Kamain.Dept_id, Depts.Dept_name, Kamain.Wono, Scrap, Setupscrap, 
	Bomparent, Shortqty, Lineshort, Part_sourc, Qty, Descript, Inv_note, U_of_meas, Pur_uofm, Ref_des,
	Part_no, Custpartno, Ignorekit, Phant_make, Revision, Serialyes, Matltype, CustRev
	-- 08/08/20 VL Changed to add AllocatedQty and UserId which are new fields added in Kamain
	,allocatedQty, userid
FROM Inventor
INNER JOIN Kamain
LEFT OUTER JOIN Depts 
ON Kamain.dept_id = Depts.dept_id
ON Inventor.uniq_key = Kamain.uniq_key
WHERE Kamain.Wono = @gWono
ORDER BY Depts.dept_name, 1, 4, Kamain.Bomparent



