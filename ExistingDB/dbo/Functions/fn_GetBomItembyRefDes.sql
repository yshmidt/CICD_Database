-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <07/08/2010>
-- Description:	<Get all BOM records including phantom parts>
 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
-- =============================================
CREATE FUNCTION [dbo].[fn_GetBomItembyRefDes]
(
	-- Add the parameters for the function here
	@cTopUniq_key char(10)=' ', @dDate smalldatetime, @cRef_des char(15) = ' '
	
	-- Parameters:
	-- @cTopUniq_key - the top BOM parent uniq_key
	-- @dDate - will use this date to calculate eff_dt and term_dt
	-- @cRef_des - the Ref_des that user entered that need to be checked, MRP calculation can ignore scrap
	
	-- Example from SO how to use it
	-- lcExpr=[']+KitmainView.Uniq_key+[', ']+lcRef_des + [']
	-- pnReturn=ThisForm.oDataTier.mCallTVFunction([fn_GetBomItembyRefDes(]+lcExpr+[)])
	-- SELECT * FROM SQLResult INTO CURSOR ZPartck
	
	-- Example how to call it in SQL 
	-- SELECT * FROM [dbo].[fn_GetBomItembyRefDes] ('_1CR0TVFHM', 'M1');

)
RETURNS TABLE 
AS
RETURN
(

WITH BomExplode as 
 (
 
 SELECT CASE WHEN Part_Sourc <> 'CONSG' THEN Part_no ELSE CustPartno END AS DispPart_no, 
		CASE WHEN Part_Sourc <> 'CONSG' THEN Revision ELSE CustRev END AS DispRevision, 
		Part_no, Revision, CustPartno, CustRev, Part_class, Part_type, Prod_id, Scrap, SetupScrap, 
		Part_sourc, Descript, U_of_meas, Pur_uofm, Phant_make, SerialYes, MatlType, Bd.Uniq_key, Bd.UniqBomno, 
		 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
		CAST(1 as Integer) as Level 
		FROM Inventor I1, Bom_det Bd
		WHERE Bd.Bomparent = @cTopUniq_key
		AND I1.Uniq_key = Bd.Uniq_key
		AND 1 = CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,ISNULL(@dDate,EFF_DT))>=0)
				AND (Term_dt is Null or DATEDIFF(day,ISNULL(@dDate,TERM_DT),term_dt)>0)  THEN 1 ELSE 0 END
		AND I1.Status = 'Active'
			
UNION ALL

SELECT CASE WHEN I1.Part_Sourc <> 'CONSG' THEN I1.Part_no ELSE I1.CustPartno END AS DispPart_no, 
		CASE WHEN I1.Part_Sourc <> 'CONSG' THEN I1.Revision ELSE I1.CustRev END AS DispRevision, 
		I1.Part_no, I1.Revision, I1.CustPartno, I1.CustRev, I1.Part_class, I1.Part_type, I1.Prod_id, I1.Scrap, I1.SetupScrap, 
		I1.Part_sourc, I1.Descript, I1.U_of_meas, I1.Pur_uofm, I1.Phant_make, I1.SerialYes, I1.MatlType, Bd.Uniq_key, Bd.UniqBomno,
		P.Level+1
		FROM BomExplode P, Bom_det Bd, Inventor I1
		WHERE P.Uniq_key = Bd.Bomparent
		AND Bd.Uniq_key = I1.Uniq_key
		AND 1 = CASE WHEN (Eff_dt is null or DATEDIFF(day,EFF_DT,ISNULL(@dDate,EFF_DT))>=0)
				AND (Term_dt is Null or DATEDIFF(day,ISNULL(@dDate,TERM_DT),term_dt)>0)  THEN 1 ELSE 0 END
		AND I1.Status = 'Active'
		AND Level < 100
			
 )

SELECT BomExplode.*
	FROM BomExplode, Bom_ref Br
	WHERE BomExplode.Uniqbomno = Br.Uniqbomno
	AND RTRIM(LTRIM(Ref_des)) = RTRIM(LTRIM(@cRef_des))
);



