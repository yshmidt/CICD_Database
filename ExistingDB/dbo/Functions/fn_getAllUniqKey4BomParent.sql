-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/23/2012
-- Description:	Function to find and Indent all the levels for the given bomparent
--- returning only UniqKey of the items founded. It is minimal result of those returned by BOMINDENETED
--- use in the MRP form when user whant to see actions for a specific BOM parent
--- old code was in the Invt form  mExplodeBom method
 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
 -- 06/13/17 YS added bomparent and effectivity abd termination date. Use this information [MrpFullActionView] when specific bomparent provided to see if the
 -- part is still active for the action
 ---06/15/18 YS propogate obsolete and effectiv date to the components from the top level if top level is not null. 
 --- if component is not null  check the dates before overwrite
-- =============================================
CREATE FUNCTION [dbo].[fn_getAllUniqKey4BomParent]
(	
	-- Add the parameters for the function here
	@lcBomParent char(10)=' '
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	
	WITH BomExplode as 
	(
		SELECT B.bomParent,B.UNIQ_KEY,C.Part_sourc,B.TERM_DT,B.EFF_DT,
		  --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
		 cast(1 as Integer) as Level  
	FROM BOM_DET B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
	WHERE B.BOMPARENT=@lcBomParent 
	
	UNION ALL
	---06/15/18 YS check the term date and update with the parent term date if comp term date is null or later than parent term date
	---06/15/18 YS check the eff date and update with the parent eff date if comp eff date is null or earlier than parent eff date
	SELECT  B2.BOMPARENT, B2.Uniq_key,C2.Part_sourc,
	case when p.TERM_DT is not null and b2.TERM_DT is null then p.TERM_DT
	when p.TERM_DT is not null and DATEDIFF(day,p.TERM_DT,b2.TERM_DT)>0 then p.TERM_DT
	else b2.TERM_DT END as TERM_DT,
	CASE WHEN p.EFF_DT is not null and b2.EFF_DT is null then p.EFF_DT
	when p.EFF_DT is not null and datediff(day,p.eff_dt,b2.eff_dt)<0 then p.EFF_DT
	else B2.EFF_DT end as EFF_DT,
	P.Level+1
	FROM BomExplode as P INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT 
	INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY 
	WHERE P.PART_SOURC='PHANTOM' or P.PART_SOURC='MAKE' 
 )
	SELECT @lcBomParent as Uniq_key,@lcBomParent as bomparent,1 as level, cast(NULL as date) as term_dt, cast(null as date) as eff_dt
		UNION ALL	
	SELECT DISTINCT Uniq_key,bomparent,level,term_dt,eff_dt FROM BomExplode	
	
)