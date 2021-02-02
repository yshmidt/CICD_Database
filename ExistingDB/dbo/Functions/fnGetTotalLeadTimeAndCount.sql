-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 02/09/18
-- Description:	Use this function to return toatal production and kit lead times for all sub-assemblies and total item count for all the levels, excluding MAKE parts
--- this function will be used in the Kitting Schedule Report ([QkViewKitRequiredView] SP)
--- reported by Arctronics zendesk ticket 1757
---- calculate lead time for make phantom parts only
--2/12/18 YS change to count only components on the top level and phantom or phant_make
---11/25/20 YS changed BomExplode.phant_make=1 to BomExplode.phant_make=0 and fix the count
--- calculate lead time for the top level+phat_make
-- =============================================
CREATE FUNCTION [dbo].[fnGetTotalLeadTimeAndCount] 
(
	-- Add the parameters for the function here
	@bomparent char(10)='', 
	@dDate date=null
)
RETURNS 
TABLE 
AS RETURN
(
WITH BomExplode as 
 (
 -- 02/12/15 VL found should not use 1 to multiple Bom_det.Qty, should use top level @nNeedQty to multiple, and at bottom when calculating ReqQty, don't multiple @nNeedQty
  SELECT Bom_det.Item_no,I1.Part_no,I1.Revision,I1.Custpartno,I1.Custrev,I1.Part_class,I1.Part_type,I1.Descript,
		CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) as varchar(max))),4,'0') as varchar(max)) AS Sort,
		Bomparent,Bom_det.Uniq_key,Bom_det.Dept_id,Bom_det.Item_note,Bom_det.Offset,Bom_det.Term_dt,Bom_det.Eff_dt,I1.Custno,
		I1.Part_sourc,I1.Perpanel,Bom_det.Used_inkit,I1.make_buy,I1.phant_make,
		LeadTime = 
		CASE 
			WHEN I1.Part_Sourc = 'PHANTOM' THEN 0000
			WHEN I1.Part_Sourc = 'MAKE' AND I1.Make_Buy = 0 THEN 
				CASE 
					WHEN I1.Prod_lunit = 'DY' THEN I1.Prod_ltime
					WHEN I1.Prod_lunit = 'WK' THEN I1.Prod_ltime * 5
					WHEN I1.Prod_lunit = 'MO' THEN I1.Prod_ltime * 20
					ELSE I1.Prod_ltime
				END +
				CASE 
					WHEN I1.Kit_lunit = 'DY' THEN I1.Kit_ltime
					WHEN I1.Kit_lunit = 'WK' THEN I1.Kit_ltime * 5
					WHEN I1.Kit_lunit = 'MO' THEN I1.Kit_ltime * 20
					ELSE I1.Kit_ltime
				END
			ELSE
				CASE
					WHEN I1.Pur_lunit = 'DY' THEN I1.Pur_ltime
					WHEN I1.Pur_lunit = 'WK' THEN I1.Pur_ltime * 5
					WHEN I1.Pur_lunit = 'MO' THEN I1.Pur_ltime * 20
					ELSE I1.Pur_ltime
				END
		END,
		CAST(1 as Integer) as Level,
		I1.Status
		FROM Bom_det,Inventor I1, Inventor I2
		WHERE Bom_det.Uniq_key=I1.Uniq_key
		AND Bom_det.Bomparent = @bomparent
		AND I2.Uniq_key = @bomparent
		AND (Eff_dt is null or DATEDIFF(day,EFF_DT,ISNULL(@dDate,EFF_DT))>=0)
		AND (Term_dt is Null or DATEDIFF(day,ISNULL(@dDate,TERM_DT),term_dt)>0) 
		AND I1.Status = 'Active' 
UNION ALL
SELECT B2.Item_no,I1.Part_no,I1.Revision,I1.Custpartno,I1.Custrev,I1.Part_class,I1.Part_type,I1.Descript,
		CAST(RTRIM(P.Sort)+'-'+	dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) as varchar(4))),4,'0') as varchar(max)) AS Sort,
		B2.Bomparent,B2.Uniq_key,B2.Dept_id,B2.Item_note,B2.Offset,B2.Term_dt,B2.Eff_dt,I1.Custno,
		I1.Part_sourc,I1.Perpanel,B2.Used_inkit,I1.make_buy,i1.phant_make,
		LeadTime = 
		CASE 
			WHEN I1.Part_Sourc = 'PHANTOM' THEN 0000
			WHEN I1.Part_Sourc = 'MAKE' AND I1.Make_Buy = 0 THEN 
				CASE 
					WHEN I1.Prod_lunit = 'DY' THEN I1.Prod_ltime
					WHEN I1.Prod_lunit = 'WK' THEN I1.Prod_ltime * 5
					WHEN I1.Prod_lunit = 'MO' THEN I1.Prod_ltime * 20
					ELSE I1.Prod_ltime
				END +
				CASE 
					WHEN I1.Kit_lunit = 'DY' THEN I1.Kit_ltime
					WHEN I1.Kit_lunit = 'WK' THEN I1.Kit_ltime * 5
					WHEN I1.Kit_lunit = 'MO' THEN I1.Kit_ltime * 20
					ELSE I1.Kit_ltime
				END
			ELSE
				CASE
					WHEN I1.Pur_lunit = 'DY' THEN I1.Pur_ltime
					WHEN I1.Pur_lunit = 'WK' THEN I1.Pur_ltime * 5
					WHEN I1.Pur_lunit = 'MO' THEN I1.Pur_ltime * 20
					ELSE I1.Pur_ltime
				END
		END,
		P.Level+1,
		I1.Status
		FROM BomExplode AS P INNER JOIN BOM_DET AS B2 ON P.Uniq_key = B2.BOMPARENT
		INNER JOIN Inventor I1 ON B2.UNIQ_KEY = I1.Uniq_key, Inventor I2
		WHERE I2.Uniq_key = P.Uniq_key and 
		(P.Part_sourc='PHANTOM' OR (P.Part_sourc='MAKE' and p.make_buy=0 and  p.phant_make=1))
		AND (b2.Eff_dt is null or DATEDIFF(day,b2.EFF_DT,ISNULL(@dDate,b2.EFF_DT))>=0)
		AND (b2.Term_dt is Null or DATEDIFF(day,ISNULL(@dDate,b2.TERM_DT),b2.term_dt)>0) 	
		AND Level < 100
		AND I1.Status = 'Active' 
)

--select COUNT(*) nitems from BomExplode B2 where (b2.part_sourc<>'MAKE' or (b2.part_sourc='MAKE' and b2.make_buy=1))
--- use conditional SUM() in case there are no make sub-assemblies using where BomExplode.part_sourc='MAKE' and BomExplode.make_buy=0 will remove all the items
--- from the result
--02/12/18 YS changed to count all parts , but phant_make and phantom. Parts that are phantom make and phantom are exploded and the coponents for those parts are counts.
---11/25/20 YS changed BomExplode.phant_make=1 to BomExplode.phant_make=0 and fix the count
select @bomparent as BomParent,t.nItems ,
sum(case when BomExplode.part_sourc='MAKE' and BomExplode.make_buy=0 and BomExplode.phant_make=0 then leadTime else 0 end) as SubLeadTime from BomExplode
CROSS APPLY (select COUNT(*) nitems from BomExplode B2 where (b2.part_sourc<>'PHANTOM' AND NOT (b2.part_sourc='MAKE' and b2.PHANT_MAKE=1))) T
--where BomExplode.part_sourc='MAKE' and BomExplode.make_buy=0
group by t.nItems


)
