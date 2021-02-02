-- =============================================  
-- Author:  Yelena Shmidt   
-- Create date: <10/28/2010>  
-- Description: <PoRecLotView for PO receiving module>  
-- Modified: 05/15/14 YS added sourcedev column to porecdtl = 'D' when updated from desktop  
--Shivshankar :29/03/17 Modified to get record when LOTCODE,EXPDATE,REFERENCE and PONUM same   
--Shivshankar :29/03/17 Added paramater to get Lot against the Loc_Uniq 'MRB' , WIP'  'WO-WIP'  
--Shivshankar :26/06/17 Get reserved Qty  
--Shivshankar :14/08/17 Get Lot code which not in   
--Shivshankar P : 12/08/17 Get all the serial number which are received against the multiple Schedule against line Item  
-- Nitesh B : 1/14/2018 Added mfgr join
--[dbo].[PoRecLotView] '0000001031','XFNBT3ECC4'  
-- =============================================  
CREATE PROCEDURE [dbo].[PoRecLotView]  
 -- Add the parameters for the stored procedure here  
 @lcReceiverno char(10)=' ',    
 @fkUniqRecdtl char(10)=' '   
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
  SELECT polt.lotcode, polt.expdate, polt.lotqty,  
          polt.reference, polt.loc_uniq, polt.lot_uniq,  
          polt.receiverno, polt.lotqty-0 AS old_lotqty,  
         polt.rejlotqty, polt.rejlotqty-0 AS oldrejlotqty,inlt.W_KEY,  
         polt.lotqty-polt.lotqty AS retlotqty,polt.sourceDev,  
         inlt.LOTRESQTY     --Shivshankar :26/06/17 Get reserved Qty  
    FROM poreclot polt 
	INNER JOIN receiverHeader on polt.RECEIVERNO = receiverHeader.receiverno --Shivshankar P : 12/08/17 Get all the serial number which are received against the multiple Schedule against line Item  
    LEFT JOIN INVTLOT inlt on polt.LOTCODE = inlt.LOTCODE AND          --Shivshankar :29/03/17 Modified to get record when LOTCODE,EXPDATE,REFERENCE and PONUM same  
    polt.EXPDATE=inlt.EXPDATE AND polt.REFERENCE=inlt.REFERENCE AND  inlt.PONUM = receiverHeader.ponum  
    Inner JOIN INVTMFGR mfgr on mfgr.W_KEY = inlt.W_KEY    --Shivshankar :29/03/17 Added paramater to get Lot against the Loc_Uniq 'MRB' , WIP'  'WO-WIP'  
    Inner JOIN WAREHOUS  on WAREHOUS.UNIQWH = mfgr.UNIQWH and WAREHOUSE <> 'MRB'   and WAREHOUSE <> 'WIP'  and WAREHOUSE <> 'WO-WIP'   
	INNER JOIN porecdtl ON porecdtl.uniqrecdtl = @fkUniqRecdtl AND mfgr.UNIQMFGRHD = porecdtl.uniqmfgrhd -- Nitesh B : 1/14/2018 Added mfgr join
    WHERE  polt.receiverno = @lcReceiverno AND polt.LOC_UNIQ  IN (SELECT LOC_UNIQ FROM PORECLOC where FK_UNIQRECDTL =@fkUniqRecdtl)  
    ORDER BY polt.loc_uniq  
  
END  