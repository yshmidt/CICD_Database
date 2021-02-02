-- =============================================      
-- Author: Sachin B      
-- Create date: 04/24/2018      
-- Description: this procedure will be called from the SF module and WO Bom Info     
-- 10/16/2017 Sachin B Remove unused Parameter @StartRecord,@EndRecord,@SortExpression,@Filter      
-- 12/18/2018 Sachin B Modified SP for the Getting the Phantom part info also Add logic from [BomIndented] SP     
-- 05/27/2019 Sachin B Fix the Issue if kit is not pulled and any make part is part of assembly component then don't get that assembly comp in bom info tab  
-- 12/09/2020 Sachin B Remove the AND imfgr.INSTORE =0 condition
-- 12/11/2020 Sachin B Calculate AvailableQty only from the approved manufacture
-- GetWoBomInfo '0000102175',''    
-- =============================================      
CREATE PROCEDURE [dbo].[GetWoBomInfo]        
  -- 10/16/2017 Sachin B Remove unused Parameter @StartRecord,@EndRecord,@SortExpression,@Filter        
  @wono CHAR(10),      
  @deptId CHAR(10) = null,    
  @lcDate smalldatetime = null,    
  @ShowIndentation bit=1,    
  @IncludeMakeBuy bit=1       
AS      
BEGIN      
      
SET NOCOUNT ON;       
      
DECLARE @bomParent CHAR(10),@bldQty NUMERIC(7,0)     
SELECT  @bomParent = UNIQ_KEY,@bldQty =BLDQTY from WOENTRY where WONO =@wono      
      
 ;With TempTotalAvailableQTY AS
 (      
	   SELECT bom.UNIQ_KEY, 
	    
	   ISNULL(SUM(ISNULL(imfgr.QTY_OH, 0))-SUM(ISNULL(imfgr.RESERVED, 0)),0) as AvailableQty       
	   FROM INVENTOR i      
	   INNER JOIN BOM_DET bom ON bom.UNIQ_KEY = i.UNIQ_KEY and bom.BOMPARENT =@bomParent      
	   INNER JOIN WOENTRY wo ON wo.UNIQ_KEY = bom.BOMPARENT and wo.WONO =@wono      
	   INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY      
	   INNER JOIN INVTMFGR imfgr ON imfgr.UniqMfgrHd =mpn.UniqMfgrHd         
	   INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId       
	   INNER JOIN Warehous w  ON w.UNIQWH = imfgr.UNIQWH  
	   WHERE  bom.BOMPARENT= @bomParent       
	   AND Warehouse <> 'WIP'      
	   AND Warehouse <> 'WO-WIP'      
	   AND Warehouse <> 'MRB'      
	   AND Netable = 1      
	   AND imfgr.IS_DELETED =0  
	   -- 12/09/2020 Sachin B Remove the AND imfgr.INSTORE =0 condition    
	   --AND imfgr.INSTORE =0      
	   AND (@deptId IS NULL OR @deptId='' OR DEPT_ID=@deptId)
	    -- 12/11/2020 Sachin B Calculate AvailableQty only from the approved manufacture   
	   AND i.UNIQ_KEY NOT IN  
	   (  
		  SELECT UNIQ_KEY   
		  FROM ANTIAVL A   
		  WHERE A.BOMPARENT =@bomParent AND A.UNIQ_KEY = i.UNIQ_KEY 
		  AND A.PARTMFGR =mfMaster.Partmfgr AND A.MFGR_PT_NO =mfMaster.mfgr_pt_no   
	   )     
	   GROUP BY bom.UNIQ_KEY      
  )     
     
 -- 12/18/2018 Sachin B Modified SP for the Getting the Phantom part info also Add logic from [BomIndented] SP       
,tempData AS(      
   SELECT B.bomParent,M.BOMCUSTNO,B.UNIQ_KEY, B.item_no,C.PART_NO,C.Revision,c.Part_sourc ,      
   CAST(CASE WHEN C.part_sourc='CONSG' THEN C.Custpartno ELSE C.Part_no END AS VARCHAR(MAX)) AS ViewPartNo,      
   CASE WHEN C.part_sourc='CONSG' THEN C.Custrev ELSE C.Revision END AS ViewRevision,      
  C.Part_class, C.Part_type, C.Descript,      
  c.MATLTYPE,      
  B.Dept_id, B.Item_note, B.Offset, B.Term_dt, B.Eff_dt, B.Used_inKit,C.Custno, C.Inv_note, C.U_of_meas, C.Scrap, C.Setupscrap,M.USESETSCRP,M.STDBLDQTY,        
  C.Phant_Make, C.StdCost, C.Make_buy, C.[Status],       
  cast(1.00 AS NUMERIC(10,2)) AS TopQty,      
  B.qty  AS Qty,       
    cast(1 AS INTEGER) AS LEVEL ,      
   '/'+CAST(bomparent AS VARCHAR(MAX)) AS PATH,      
  CAST(dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY Item_no) AS VARCHAR(MAX))),4,'0') AS VARCHAR(MAX)) AS Sort,      
  B.UNIQBOMNO,c.BUYER_TYPE AS Buyer ,        
  c.stdcostpr,c.funcFcUsed_uniq,c.PrFcUsed_uniq     
  ,C.useipkey, C.serialyes       
  FROM BOM_DET B     
  INNER JOIN INVENTOR C ON B.UNIQ_KEY =C.UNIQ_KEY       
  INNER JOIN INVENTOR M ON B.BOMPARENT =M.UNIQ_KEY       
  WHERE B.BOMPARENT=@bomParent       
  AND (@lcDate IS NULL OR ((Eff_dt IS NULL OR DATEDIFF(day,EFF_DT,@lcDate)>=0) AND (Term_dt IS NULL OR DATEDIFF(day,TERM_DT,@lcDate)<0)))    
  AND (@deptId IS NULL OR @deptId='' OR B.DEPT_ID=@deptId)     
 UNION ALL      
  SELECT  B2.BOMPARENT, M2.BOMCUSTNO ,B2.Uniq_key,B2.item_no  ,C2.PART_NO,C2.Revision,c2.Part_sourc ,      
  CAST(CASE WHEN @ShowIndentation=1 THEN SPACE((P.level+1)*4) ELSE SPACE(0) END +CASE WHEN C2.part_sourc='CONSG' THEN C2.Custpartno ELSE C2.Part_no  END as varchar(max)) AS ViewPartNo,      
  CASE WHEN C2.part_sourc='CONSG' THEN C2.Custrev ELSE C2.Revision END AS ViewRevision,      
  C2.Part_class, C2.Part_type, C2.Descript,      
  c2.MATLTYPE,      
  B2.Dept_id, B2.Item_note, B2.Offset, B2.Term_dt, B2.Eff_dt, B2.Used_inKit,C2.Custno,       
  C2.Inv_note, C2.U_of_meas, C2.Scrap, C2.Setupscrap,M2.USESETSCRP,M2.STDBLDQTY,      
  C2.Phant_Make, C2.StdCost, C2.Make_buy, C2.Status,       
  CAST(P.Qty*P.TopQty AS NUMERIC(10,2)) AS TopQty,B2.QTY, P.Level+1,      
  CAST(RTRIM(LTRIM(P.Path))+'/'+B2.bomparent AS varchar(max)) AS path ,      
  CAST(RTRIM(p.Sort)+'-'+ dbo.padl(RTRIM(CAST(ROW_NUMBER() OVER(ORDER BY b2.Item_no) AS VARCHAR(4))),4,'0') AS VARCHAR(MAX)) AS Sort,      
  B2.UNIQBOMNO,c2.BUYER_TYPE AS Buyer,         
  c2.stdcostpr,c2.funcFcUsed_uniq,c2.PrFcUsed_uniq,    
  C2.useipkey, C2.serialyes    
  FROM tempData AS P     
  INNER JOIN BOM_DET as B2 ON P.UNIQ_KEY =B2.BOMPARENT       
  INNER JOIN INVENTOR C2 ON B2.UNIQ_KEY =C2.UNIQ_KEY       
  INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY    
  -- 05/27/2019 Sachin B Fix the Issue if kit is not pulled and any make part is part of assembly component then don't get that assembly comp in bom info tab     
  WHERE (P.PART_SOURC='PHANTOM') -- OR  OR (P.PART_SOURC='MAKE' and P.MAKE_BUY=0) ( @IncludeMakeBuy=1 and P.PART_SOURC='MAKE')     
  AND (@lcDate IS NULL OR ((b2.Eff_dt IS NULL OR DATEDIFF(day,b2.EFF_DT,@lcDate)>=0) AND (b2.Term_dt IS NULL OR DATEDIFF(day,b2.TERM_DT,@lcDate)<0)))     
  AND (@deptId IS NULL OR @deptId='' OR B2.DEPT_ID=@deptId)     
)     
    
--select * from tempData    
    
 SELECT E.MATLTYPE, E.useipkey, E.serialyes, E.UNIQ_KEY AS UniqKey,      
 E.part_no AS PartNo, E.REVISION,E.PART_SOURC AS PartSource,(@bldQty*E.QTY) AS Shortage,      
 CASE COALESCE(NULLIF(E.REVISION,''), '')      
  WHEN '' THEN  LTRIM(RTRIM(E.PART_NO))       
  ELSE LTRIM(RTRIM(E.PART_NO)) + '/' + E.REVISION       
  END AS PartNoWithRev,      
  @wono wono,    
  E.dept_id as DeptId,E.qty AS Each,0.0 AS QtyIssued, 0.0 AS QtyAlloc,      
  LTRIM(RTRIM(E.PART_CLASS)) + '/' + LTRIM(RTRIM(E.PART_TYPE)) + '/' + LTRIM(RTRIM(E.DESCRIPT)) AS [Description],    
  (@bldQty*E.QTY) AS RequiredQty,    
  ISNULL(p.LOTDETAIL,CAST (0 AS BIT)) AS IsLotted,ISNULL(allQty.AvailableQty,0) AS AvailableQty        
 FROM tempData E       
   LEFT JOIN PARTTYPE p ON p.PART_TYPE = E.PART_TYPE AND p.PART_CLASS =E.PART_CLASS     
   LEFT OUTER JOIN INVENTOR CustI ON E.UNIQ_KEY =CustI.INT_UNIQ AND E.BOMCUSTNO=CustI.CUSTNO     
   LEFT OUTER JOIN TempTotalAvailableQTY allQty ON allQty.UNIQ_KEY = E.UNIQ_KEY        
 ORDER BY sort OPTION (MAXRECURSION 100);      
      
END