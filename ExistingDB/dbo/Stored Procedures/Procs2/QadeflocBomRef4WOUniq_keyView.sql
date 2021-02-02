-- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- Modifed: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables  
-- 02/17/15 VL added to filter out inactive part by passing 10 parameter to fn_phantomSubSelect()  
-- 06/02/15 YS added uniqmfgrhd to the output and remove reference to invtmfgr table  
-- 06/24/15 VL added Antiavl.Bomparent = @lcUniq_key criteria
-- 06/06/2019 Sachin B Add Column MfgrWithMfgrPartno in the Select Statement  
-- =============================================  
CREATE PROC [dbo].[QadeflocBomRef4WOUniq_keyView] @lcWono AS char(10) = ' ', @lcLocation AS char(30) = ' '   
AS  
  
DECLARE @lcUniq_key char(10), @ldDue_date smalldatetime  
--06/02/15 YS trim location here instead of in SQL  
set @lcLocation=LTRIM(RTRIM(@lcLocation));  
  
SELECT @lcUniq_key = Uniq_key, @ldDue_date = Due_date   
 FROM WOENTRY  
 WHERE WONO = @lcWono;  
-- 02/17/15 VL added to filter out inactive part by passing 10 parameter to fn_phantomSubSelect()  
-- 06/02/15 YS added uniqmfgrhd to the output and remove reference to invtmfgr table  
WITH ZBom_det AS  
(  
SELECT Part_no, Revision, Part_class, Part_type, Uniq_key, UniqBomno  
 FROM [dbo].[fn_PhantomSubSelect] (@lcUniq_key, 1, 'T', @ldDue_date, 'F', 'T', 'F', 0,0,0)  
)   


SELECT Partmfgr, Part_class, Mfgr_Pt_no, ZBom_det.Uniq_key, Part_no, Revision, L.UniqMfgrHd,dbo.fn_GenerateUniqueNumber() AS UniqValue,
-- 06/06/2019 Sachin B Add Column MfgrWithMfgrPartno in the Select Statement  
CASE COALESCE(NULLIF(Mfgr_Pt_no,''), '')
WHEN '' THEN  LTRIM(RTRIM(Partmfgr)) 
ELSE LTRIM(RTRIM(Partmfgr)) + '/' + Mfgr_Pt_no
END AS MfgrWithMfgrPartno  
 --10/09/14 YS removed invtmfhd table and replaced with 2 new tables  
FROM Bom_ref 
INNER JOIN  ZBom_det ON  ZBom_det.UniqBomNo = Bom_ref.UniqBomNo  
INNER JOIN InvtMPNLink L ON zbom_det.Uniq_key=L.uniq_key  
INNER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId  
WHERE Bom_ref.Ref_des = @lcLocation  
 -- 06/24/15 VL added next line, so only check with Antiavl for Bomparent = @lcUniq_key  
AND NOT EXISTS (select 1 from Antiavl A where  A.Bomparent = @lcUniq_key and  A.Uniq_key=L.Uniq_key and A.PartMfgr=M.PartMfgr and A.MFGR_PT_NO=M.mfgr_pt_no)   
AND L.Is_Deleted = 0 and m.IS_DELETED=0  
ORDER BY Partmfgr