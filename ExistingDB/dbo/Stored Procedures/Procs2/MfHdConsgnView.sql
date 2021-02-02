-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Modified: 10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 03/24/15   Added part_pkg column (was in the inventor table,will remove)
-- =============================================
CREATE proc [dbo].[MfHdConsgnView] @guniq_key as char(10)=null

as 
--10/09/14 YS removed invtmfhd table and replaced with 2 new tables
-- 03/24/15   Added part_pkg column (was in the inventor table,will remove)
SELECT L.uniqmfgrhd, L.uniq_key, M.partmfgr,
  M.mfgr_pt_no, M.marking, M.body, M.pitch,
  M.part_spec, M.uniqpkg, L.is_deleted,
  M.matltype, M.autolocation, M.sftystk,M.Part_pkg
 FROM 
     InvtMPNLink L INNER JOIN MfgrMaster M on l.mfgrMasterId=M.MfgrMasterId 
    INNER JOIN inventor 
   ON  L.uniq_key = Inventor.uniq_key
 WHERE  Inventor.int_uniq = @guniq_key 
   AND  Inventor.int_uniq <> SPACE(10) 
   AND  Inventor.part_sourc = 'CONSG'