
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/26/2012 
-- Description:	This procedure will check if adding new item to the BOm will endup in the infinit loop. 
-- probably need to check only for MAKE, PHANTOM or make/buy
 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
-- =============================================
CREATE PROCEDURE [dbo].[CheckBomIndented4newItem]
	-- Add the parameters for the stored procedure here
	@lcBomParent char(10)=' ' ,@lcUniq_key char(10)=' '	
	
	-- list of parameters:
	-- 1. @lcBomParent - top level BOM uniq_key 
	-- 2. @lcUniq_key - new part added to the top level
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @tBom table (bomParent char(10),UNIQ_KEY char(10),item_no numeric(4),UniqBomNo char(10))
	INSERT INTO @tBom SELECT BomParent,Uniq_key,Item_no,UniqBomNo FROM BOM_DET WHERE BOMPARENT=@lcBomParent UNION ALL SELECT @lcBomParent,@lcUniq_key,0,dbo.fn_GenerateUniqueNumber();
	 
    -- Insert statements for procedure here
	 WITH BomExplode as 
  (
  SELECT B.bomParent,B.UNIQ_KEY, B.item_no,c.Part_sourc ,
  	C.Phant_Make, C.Make_buy, 
	 --	09/30/16	 YS make top level 1 instead of 0. Paramit PG has problem with 0 when printing reports
	cast(1 as Integer) as Level ,
  '/'+CAST(bomparent as varchar(max)) as path,
	B.UNIQBOMNO 
	FROM @tBom B INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY 
	INNER JOIN INVENTOR M on B.BOMPARENT =M.UNIQ_KEY 
	WHERE B.BOMPARENT=@lcBomParent 
		
	UNION ALL
	
	SELECT  B2.BOMPARENT,B2.Uniq_key,B2.item_no, c2.Part_sourc ,
	C2.Phant_Make, C2.Make_buy,  
	P.Level+1,
	CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent as varchar(max)) as path ,
	B2.UNIQBOMNO   
	FROM BomExplode as P INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT 
	INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY 
	INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY 
	WHERE P.PART_SOURC='PHANTOM' or P.PART_SOURC='MAKE' 
  )
	SELECT E.*  
		from BomExplode E OPTION (MAXRECURSION 100)  ;

	
END