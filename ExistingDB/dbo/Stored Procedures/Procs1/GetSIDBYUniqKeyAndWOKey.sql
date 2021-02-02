-- =============================================
-- Author:		Rajendra K	
-- Create date: <02/15/2016>
-- Description:	Get SID by uniqKey and WO Key
-- Modification
   -- 08/11/2017 Rajendra K : Added condition to get valid records from InvtMfgr table
   -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records 
   -- 10/31/2017 Rajendra K : Added where condition
   -- 10/31/2017 Rajendra K :Removed table 'INVTMPNLINK' from join condition 
   -- 10/31/2017 Rajendra K : Change left join to inner join for tables INVENTOR and INVTMFGR
   -- 10/31/2017 Rajendra K : Parameter name renamed as per naming conventions
-- =============================================
CREATE PROCEDURE [dbo].[GetSIDBYUniqKeyAndWOKey]
(
 @uniqKey AS char(10),
 @woKey AS char(10)
)
AS
BEGIN
		SET NOCOUNT ON;
		SELECT DISTINCT 
			    IP.IPKEYUNIQUE AS SID
			   ,I.UNIQ_KEY
			   ,IP.W_KEY
			   ,IL.LOTCODE
			   ,ISNULL(IL.LOTQTY,IM.QTY_OH)  AS LotQty
			   ,ISNULL(IL.LOTRESQTY,IR.QTYALLOC) AS LotResQty
			   ,(ISNULL(IL.LOTRESQTY,IR.QTYALLOC) + (CASE WHEN I.USEIPKEY = 1 THEN IRes.qtyAllocated ELSE 0 END)) AS Overage
	   FROM IPKEY IP LEFT JOIN INVTLOT IL ON  IP.LOTCODE = IL.LOTCODE  AND IL.W_KEY = IL.W_KEY
			    INNER JOIN INVENTOR I ON I.UNIQ_KEY = IP.UNIQ_KEY -- 10/31/2017 Rajendra K : Change left join to inner join
			    --10/31/2017 Rajendra K :Removed table 'INVTMPNLINK' from join condition 
			    INNER JOIN INVTMFGR IM ON IP.W_KEY = IM.W_KEY -- 10/31/2017 Rajendra K : Change left join to inner join
				--AND IM.QTY_OH > 0  -- 10/25/2017 Rajendra K : Removed condition INVTMF.QTY_OH > 0 to display all MFGR records 
				AND IM.NETABLE = 1 AND IM.InStore = 0 AND IM.IS_DELETED = 0 -- 08/11/2017 - Rajendra K : Added this condition to get valid records from InvtMfgr table
			    LEFT JOIN INVT_RES IR ON IP.LOTCODE = IR.LOTCODE  AND IP.W_KEY = IR.W_KEY AND IR.UNIQ_KEY = I.UNIQ_KEY
			    LEFT JOIN iRESERVEIPKEY IRes ON IP.IPKEYUNIQUE = IRes.ipkeyunique	
	  WHERE (@uniqKey IS NULL OR @uniqKey = '' OR I.UNIQ_KEY = @uniqKey) -- 10/31/2017 Rajendra K : Added where condition	       			                                              
END	
