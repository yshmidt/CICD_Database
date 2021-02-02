--=============================================
 --Author:		<Vicky>
 --Create date: 
 --Description:	
 --Modified:	
 -- 08/29/12 VL changed Custrev char(4) to char(8)
 -- 08/30/12 VL added LineShort, so Debbie can use it in Kit report
 -- 10/05/12 DP edited the description in sections that pulled from the @ZKitMain.. removed LTRIM(RTRIM(Inventor.Part_class))+' '+LTRIM(RTRIM(Inventor.Part_type))+' '+LTRIM(RTRIM(Inventor.Descript)) 
 -- had it pull just the descript field of the @Zkitmain table.  The way it was it was populating the Class & Type twice into the results causing a truncation issue.
 -- 03/13/13 VL can not figure why use RIGHT(STR(...)) code, decided just use original field, checked again, probably copied the code from 9.6.2
 -- 05/15/2015 DRP:	removed <<SELECT * FROM @ZKitBom>> the from the end of the <<(IF (@cDept_id = '')>> section.  It would then return results sets.  I believe it was left in by accident.
 --							Added the bom_det.Dept_id = Z1.Dept_id to a couple locations below.  In order to fix duplicating of item number when same part was loaded more than once on bom to different dept_id
 --							Added Dept_id to the  @ZKitBom TABLE  results. 	
 -- 05/15/15 VL un-comment <<SELECT * FROM @ZKitBom>>, we do need this when wono is not empty and dept_id is not empty as well	
 --- 03/28/17 YS changed length of the part_no column from 25 to 35				
 --=============================================
CREATE PROCEDURE [dbo].[KitBOMView] @gWono AS char(10) = '', @gUniq_key AS char(10) = '', 
	@ldDue_date AS smalldatetime = '', @cDept_id AS char(4) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

/* Get all Kitmainview data first*/
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZKitMain TABLE (Ignorekit Bit, Part_no char(35), Revision char(8), CustPartno char(35),
		CustRev char(8), Qty numeric(9,2), ReqQty numeric(12,2), IssuedQty numeric(12,2), ShortQty numeric(12,2),
		Part_Sourc char(10), Descript char(63), Kaseqnum char(10), Uniq_key2 char(10), Part_class char(8),
		Part_type char(8), Dept_id char(4), LineShort bit);

/* This table will keep all the kitbom data that will be return*/
-- 03/28/16 YS someone added dept_id in manexLoah but not here
--- 03/28/17 YS changed length of the part_no column from 25 to 35
DECLARE @ZKitBom TABLE (Ignorekit char(1), Item_no numeric(4,0), Part_no char(35), Revision char(8), CustPartno char(35),
		CustRev char(8), Qty numeric(9,2), ReqQty numeric(12,2), IssuedQty numeric(12,2), ShortQty numeric(12,2),
		Part_Sourc char(10), ChildUniq_key char(10), Descript char(63), UniqBomNo char(10), Kaseqnum char(10), 
		Eff_dt smalldatetime, Term_dt smalldatetime, LineShort bit,dept_id char(4));

BEGIN
IF (@gWono <> '')

	BEGIN
	INSERT @ZKitMain
		SELECT Ignorekit,Part_no, Revision, CustPartNo = CASE Inventor.Part_sourc
		WHEN 'CONSG' THEN Inventor.CustPartNo ELSE Inventor.Part_no	END, CustRev = CASE Inventor.Part_sourc
		WHEN 'CONSG' THEN Inventor.Custrev ELSE Inventor.Revision END, Qty,
		Kamain.shortqty+Kamain.act_qty AS ReqQty, Act_Qty AS IssuedQty, ShortQty,
		Part_Sourc,LTRIM(RTRIM(Inventor.Part_class))+' '+LTRIM(RTRIM(Inventor.Part_type))+' '+LTRIM(RTRIM(Inventor.Descript)) AS Descript,
		Kaseqnum, Kamain.Uniq_key AS Uniq_key2, Part_class, Part_type, Dept_id, LineShort
		FROM Inventor, Kamain
		WHERE Inventor.uniq_key = Kamain.uniq_key
		AND Kamain.Wono = @gWono;
	END

	BEGIN
	IF (@cDept_id = '')
		BEGIN
			/* Get all BOM data */
			-- 03/13/13 VL can not figure why use RIGHT(STR(...)) code, decided just use original field 
			INSERT @ZKitBom
			SELECT IgnoreKit = CASE WHEN IgnoreKit IS NULL THEN ' ' WHEN IgnoreKit = 1 THEN 'X' ELSE ' ' END,
			Item_no, Inventor.Part_no, Inventor.Revision, Inventor.CustPartno, Inventor.CustRev, Bom_det.Qty AS Qty, 
			--RIGHT(STR(ISNULL(ReqQty,0.00),13,2),9) AS ReqQty, RIGHT(STR(ISNULL(IssuedQty,0.00),12,2),8) AS IssuedQty,
			--RIGHT(STR(ISNULL(ShortQty,0.00),12,2),8) AS ShortQty, 
			ISNULL(ReqQty,0.00) AS ReqQty, ISNULL(IssuedQty,0.00) AS IssuedQty,
			ISNULL(ShortQty,0.00) AS ShortQty, 
			LEFT(Inventor.Part_sourc,7) AS Part_sourc, Bom_det.Uniq_key AS ChildUniq_key, 
			LTRIM(RTRIM(Inventor.Part_class))+' '+LTRIM(RTRIM(Inventor.Part_type))+' '+LTRIM(RTRIM(Inventor.Descript)) AS Descript, Bom_det.UniqBomNo,
			ISNULL(Kaseqnum,SPACE(10)) AS Kaseqnum, Eff_dt, Term_dt, LineShort,bom_det.Dept_id
			FROM Inventor, Bom_det LEFT OUTER JOIN @ZKitMain Z1
				ON Bom_det.Uniq_key = Z1.Uniq_key2 and bom_det.DEPT_ID = z1.Dept_id		--05/15/2015 DRP:  added the bom_det.Dept_id = Z1.Dept_id to fix duplicating of item number when same part was loaded more than once on bom to different dept_id
				WHERE Inventor.Uniq_key = Bom_det.Uniq_key 
				AND Bom_det.Bomparent = @gUniq_key 
				AND (Eff_dt<=CAST(CONVERT(char(20),@ldDue_date,101) as smalldatetime) OR Eff_dt IS NULL)
				AND (Term_dt>CAST(CONVERT(char(20),@ldDue_date,101) as smalldatetime) OR Term_dt IS NULL)
				ORDER BY 2;

			/* Now get what is in Kit not in BOM */
			INSERT @ZKitBom
			SELECT IgnoreKit = CASE WHEN IgnoreKit IS NULL THEN ' ' WHEN IgnoreKit = 1 THEN 'X' ELSE ' ' END,
				0 AS Item_no, Part_no, Revision, CustPartno, CustRev, Qty, ReqQty,
				IssuedQty, ShortQty, Part_sourc, Uniq_key2 AS ChildUniq_key, 
				Descript,
				SPACE(10) AS UniqBomNo, Kaseqnum, '' AS Eff_dt, '' AS Term_dt, LineShort ,Dept_id
				FROM @ZKitMain 
				WHERE Kaseqnum NOT IN 
					(SELECT Kaseqnum 
						FROM @ZKitBom);
			
			SELECT * FROM @ZKitBom;
		END
	ELSE
		BEGIN
			/* Get all BOM data */
			-- 03/13/13 VL can not figure why use RIGHT(STR(...)) code, decided just use original field 
			INSERT @ZKitBom
			SELECT IgnoreKit = CASE WHEN ISNULL(IgnoreKit,' ') = ' ' THEN ' ' WHEN IgnoreKit = 1 THEN 'X' 
					ELSE ' ' END,
			Item_no, Inventor.Part_no, Inventor.Revision, Inventor.CustPartno, Inventor.CustRev, Bom_det.Qty AS Qty, 
			--RIGHT(STR(ISNULL(ReqQty,0.00),13,2),9) AS ReqQty, RIGHT(STR(ISNULL(IssuedQty,0.00),12,2),8) AS IssuedQty,
			--RIGHT(STR(ISNULL(ShortQty,0.00),12,2),8) AS ShortQty, 
			ISNULL(ReqQty,0.00) AS ReqQty, ISNULL(IssuedQty,0.00) AS IssuedQty,
			ISNULL(ShortQty,0.00) AS ShortQty, 
			LEFT(Inventor.Part_sourc,7) AS Part_sourc, Bom_det.Uniq_key AS ChildUniq_key, 
			LTRIM(RTRIM(Inventor.Part_class))+' '+LTRIM(RTRIM(Inventor.Part_type))+' '+LTRIM(RTRIM(Inventor.Descript)) AS Descript, Bom_det.UniqBomNo,
			ISNULL(Kaseqnum,SPACE(10)) AS Kaseqnum, Eff_dt, Term_dt, LineShort ,bom_det.Dept_id
			FROM Inventor, Bom_det LEFT OUTER JOIN @ZKitMain
				ON Bom_det.Uniq_key = Uniq_key2
				WHERE Inventor.Uniq_key = Bom_det.Uniq_key 
				AND Bom_det.Bomparent = @gUniq_key 
				AND (Eff_dt<=CAST(CONVERT(char(20),@ldDue_date,101) as smalldatetime) OR Eff_dt IS NULL)
				AND (Term_dt>CAST(CONVERT(char(20),@ldDue_date,101) as smalldatetime) OR Term_dt IS NULL)
				AND Bom_det.Dept_id = @cDept_id
				ORDER BY 2;

			/* Now get what is in Kit not in BOM */
			INSERT @ZKitBom
			SELECT IgnoreKit = CASE WHEN ISNULL(IgnoreKit,' ') = ' ' THEN ' ' 
							WHEN IgnoreKit = 1 THEN 'X' 
							ELSE ' '
					 END,
				0 AS Item_no, Part_no, Revision, CustPartno, CustRev, Qty, ReqQty,
				IssuedQty, ShortQty, Part_sourc, Uniq_key2 AS ChildUniq_key, 
				Descript,
				SPACE(10) AS UniqBomNo, Kaseqnum, '' AS Eff_dt, '' AS Term_dt, LineShort ,dept_id
				FROM @ZKitMain 
				WHERE Kaseqnum NOT IN 
					(SELECT Kaseqnum 
						FROM @ZKitBom) 
				AND Dept_id = @cDept_id;
			-- 05/15/15 VL un-comment next line, we do need this when wono is not empty and dept_id is not empty as well
			SELECT * FROM @ZKitBom	--05/15/2015 DRP:  removed because it would then display two results instead of one.  I think it was accidentally left in by accident
			

		END
	END
END


BEGIN
IF (@gWono = '')
	IF (@cDept_id = '')
		-- 03/13/13 VL can not figure why use RIGHT(STR(...)) code, decided just use original field 
		SELECT Item_no, Part_no, Revision, Inventor.CustPartno, Inventor.CustRev,
			--RIGHT(STR(Bom_det.Qty,9,2),7) AS Qty, 
			Bom_det.Qty AS Qty,
			LEFT(Part_sourc,7) AS Part_sourc, Bom_det.Uniq_key AS ChildUniq_key, 
			LTRIM(RTRIM(Inventor.Part_class))+' '+LTRIM(RTRIM(Inventor.Part_type))+' '+LTRIM(RTRIM(Inventor.Descript)) AS Descript,
			Bom_det.UniqBomNo, Eff_dt, Term_dt, 0 AS LineShort  
			FROM Inventor, Bom_det 
			WHERE Inventor.Uniq_key = Bom_det.Uniq_key 
			AND Bom_det.Bomparent = @gUniq_key 
			ORDER BY 1 ;
	ELSE
		SELECT Item_no, Part_no, Revision, Inventor.CustPartno, Inventor.CustRev,
			--RIGHT(STR(Bom_det.Qty,9,2),7) AS Qty, 
			Bom_det.Qty AS Qty,
			LEFT(Part_sourc,7) AS Part_sourc, Bom_det.Uniq_key AS ChildUniq_key, 
			LTRIM(RTRIM(Inventor.Part_class))+' '+LTRIM(RTRIM(Inventor.Part_type))+' '+LTRIM(RTRIM(Inventor.Descript)) AS Descript,
			Bom_det.UniqBomNo, Eff_dt, Term_dt, 0 AS LineShort 
			FROM Inventor, Bom_det 
			WHERE Inventor.Uniq_key = Bom_det.Uniq_key 
			AND Bom_det.Bomparent = @gUniq_key 
			AND Bom_det.Dept_id = @cDept_id
			ORDER BY 1 ;

END


END