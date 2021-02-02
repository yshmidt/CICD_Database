-- =============================================  
-- Author: Shivshankar Patil   
-- Create date: <04/23/2020>  
-- Description: Get Part Number Details  
-- EXEC GetPartDetailsByUniqKey 'C5NK6V4706' 
-- Shivshankar P 08/05/2020 : Change Inner join to left join with Invtmfgr table 
-- =============================================  
CREATE PROCEDURE dbo.[GetPartDetailsByUniqKey]   
@uniqKey char(10) =' '  
--@mpn varchar(100)=' ',  
--@partMfgr varchar(100)=' '
  
AS   
 BEGIN  
   SET NOCOUNT ON;  
   IF(@uniqKey IS NOT NULL OR @uniqKey <> '')  
      BEGIN  
		SELECT DISTINCT invt.UNIQ_KEY AS Id, invt.Part_No AS PartNo, invt.Revision, invt.Part_Class, invt.Part_Type, RTRIM(invt.PART_CLASS) +'/' + RTRIM(invt.PART_TYPE) +'/' + RTRIM(invt.DESCRIPT) SubIdOne,
		   CASE WHEN invt.Stdcost = 0 AND invt.Matl_Cost <> 0 THEN CAST(invt.Matl_Cost AS nvarchar) ELSE CAST(invt.Stdcost AS nvarchar) END AS SubIdTwo,
		   CAST(invt.Targetprice AS nvarchar) AS SubIdThree,
		   invt.Matltype AS SubIdFour , invt.U_Of_Meas AS SubIdFive, invt.Pur_Uofm AS SubIdSix, invt.Taxable AS SubIdSeven, invt.Pur_Ltime AS SubIdEight,
		   invt.Minord AS SubIdNine, invt.Ordmult AS SubIdTen, invt.Pur_Lunit AS SubIdEleven, invt.Insp_Req AS SubIdTwelve, invt.Firstarticle AS F_Article,
		   invt.Package AS Package, m.mfgr_pt_no AS Type, m.PartMfgr AS PartMfgr, l.uniqmfgrhd AS UniqMfgrHd
		   FROM MfgrMaster m 
		   INNER JOIN InvtMPNLink l ON m.MfgrMasterId = l.MfgrMasterId
		   INNER JOIN Inventor invt ON l.uniq_key = invt.Uniq_Key
		   LEFT JOIN Invtmfgr imfgr on invt.Uniq_Key = imfgr.Uniq_Key -- Shivshankar P 08/05/2020 : Change Inner join to left join with Invtmfgr table 
		   WHERE l.uniq_key = @uniqKey 
		   AND l.is_deleted = 0 AND invt.Status = 'ACTIVE'   
      END  
END  