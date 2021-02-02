-- =============================================        
-- Author:Rajendra K        
-- Create date: 03/07/2017        
-- Description: Get SerialNumber details based on unique key/MFGRMasterId and ware house key         
-- Modification        
   -- 03/23/2017 Rajendra K : Added W_KEY in Where clause        
   -- 05/23/2017 Rajendra K : Added condition ISer.ID_VALUE = IMF.W_KEY        
   -- 05/23/2017 Rajendra K : Added condition IM.is_deleted = 0        
   -- 06/08/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros) by existing function 'fremoveLeadingZeros'        
   -- 06/21/2017 Rajendra K : Removed condition ISer.ISRESERVED = 0 to get reserved SerialNumbers        
   -- 06/21/2017 Rajendra K : Added to get reserved serialNumbers        
   -- 08/02/2017 Rajenrda K : Added order by clause by SerialNo        
   -- 08/11/2017 Rajendra K : Modified join condition for LotDetails        
   -- 08/11/2017 Rajendra K : Added condition to get valid records from InvtMfgr table        
   -- 08/30/2017 Rajendra K : Added new parameter ,select statement union with existing select and condition in existing select statement to get reserved serial number records from invtres         
   --and ireserveserial table         
   -- 08/21/2017 Rajendra K : Added condition tp get records with Ipkeyuniq if Lotdetails not exists        
   -- 09/01/2017 Rajendra K : Added condition IR.W_KEY = ISR.ID_VALUE AND ISR.ID_KEY = 'W_KEY' in first select statement        
   -- 09/13/2017 Rajendra K : Apply WO Reservation default settings        
   -- 10/04/2017 Rajendra K : Setting Name changed in where clause for #temoWOSettings to get ICM default settings        
   -- 09/01/2017 Rajendra K : Added condition ISR.ISRESERVED = 1 in first section of UNION query to get only reserved serial numbners from INVTSER        
   -- 10/09/2017 Rajendra K : Added parameter @kaSeqNumber to get reserved serial number records         
   -- 10/31/2017 Rajendra K : Changed size of SerialNo        
   -- 10/31/2017 Rajendra K : Changed paramaters as per naming standards        
   -- 11/13/2017 Rajendra K : Added parameter IsChecked in Select List        
   -- 11/24/2017 Rajendra K : Replaced UNIQ_KEY with WONO to get BOMParent        
   -- 12/06/2017 Rajendra K : Added column SerialNo(Without removing leading zero's) in select list and changed order by condition for sorting        
   -- 12/13/2017 Rajendra K : Added input parameter @location and applied in join condition         
   -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR        
   -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations  
   -- 06/20/2020 Rajendra K : Added kaseqnum in condition to avoid serial no duplication
   -- EXEC GetSerialNumbersData '_1EP0Q018H','09FQ1VQWE5','_1EP0Q15GX','MRFJTIXOAI','_0DM120YNN','0000000515','UIKKVDYDFB'        
-- =============================================        
        
CREATE PROCEDURE [dbo].[GetSerialNumbersData]        
(        
 @uniqKey AS CHAR(10)='',        
 @ipKeyUnique CHAR(10)='',        
 @uniqMfgrhd CHAR(10)='',        
 @uniqLot VARCHAR(10)='',        
 @uniqWHKey VARCHAR(10)='',        
 @woNO CHAR(10)='', -- 08/30/2017 : Rajendra K Added parameter to get reserved serial number records from invtres and ireserveserial table        
 @kaSeqNumber CHAR(10)='', -- 10/09/2017 Rajendra K : Added parameter to get reserved serial number records for KaSaqNumber        
 @location NVARCHAR(200)='' -- 12/13/2017 Rajendra K : Added input parameter @location and applied in join condition         
 -- 08/06/2019 Rajendra K : Changed location datatype from VARCHAR to NVARCHAR        
)        
AS        
BEGIN        
 SET NOCOUNT ON;        
 --09/13/2017 Rajendra K : Added WO Reservation  default settings logic        
    --Declare variables        
    DECLARE @mfgrDefault NVARCHAR(MAX),@nonNettable BIT,@bomParent CHAR(10)        
        
 SELECT SettingName        
     ,LTRIM(WM.SettingValue) SettingValue        
 INTO  #tempWOSettings        
 FROM MnxSettingsManagement MS INNER JOIN WmSettingsManagement WM ON MS.settingId = WM.settingId          
 WHERE SettingName IN('manufacturersDefault','allowUseOfNonNettableWarehouseLocation') -- 10/04/2017 Rajendra K : Setting Name changed in where clause        
        
    --Assign values to variables to hold values for WO Reservation  default settings        
 SET @mfgrDefault = ISNULL((SELECT SettingValue FROM #tempWOSettings WHERE SettingName = 'manufacturersDefault'),'All MFGRS')  -- 10/04/2017 Rajendra K : Setting Name changed in where clause        
 SET @nonNettable= ISNULL((SELECT CONVERT(BIT, SettingValue) FROM #tempWOSettings WHERE SettingName = 'allowUseOfNonNettableWarehouseLocation'),0) -- 10/04/2017 Rajendra K : Setting Name changed in where clause        
 SET @bomParent = (SELECT UNIQ_KEY FROM WOENTRY WHERE WONO = @woNO) -- 11/24/2017 Rajendra K : Replaced UNIQ_KEY with WONO          
        
  -- 10/09/2017 Rajendra K : Added temp table #TempSer to get SID specific reserved serial numbers        
  CREATE TABLE #tempSerialNumber        
  (        
   SerialUniq CHAR(10)        
  )        
        
  -- 10/09/2017 Rajendra K : Get SID specific reserved serial numbers        
  IF(@ipKeyUnique IS NOT NULL AND @ipKeyUnique <> '')        
  BEGIN        
      INSERT INTO #tempSerialNumber        
      SELECT SerialUniq          
      FROM iReserveSerial IR         
      WHERE IR.Ipkeyunique = @ipKeyUnique        
      GROUP BY SerialUniq HAVING COUNT(1)%2 <> 0        
  END        
        
 SELECT DISTINCT IRS.Serialuniq        
    ,CAST(dbo.fremoveLeadingZeros(ISR.SerialNo) AS VARCHAR(20)) AS SerialNo -- 10/31/2017 Rajendra K : Changed size of SerialNo        
    ,ISR.SerialNo AS Serial -- 12/06/2017 Rajendra K : Added column SerialNo(Without removing leading zero's) in select list for sorting        
    ,ISR.UNIQ_KEY        
    ,ISR.UNIQMFGRHD        
    ,ISR.UNIQ_LOT        
    ,IRS.IpKeyUnique        
    ,IR.W_KEY        
    ,ISR.ISRESERVED        
    ,ISR.ISRESERVED AS IsChecked -- 11/13/2017 Rajendra K : Added parameter IsChecked        
    FROM iReserveSerial IRS     
    INNER JOIN INVT_RES IR ON IRS.INVTRES_NO = IR.invtres_no  AND IR.UNIQ_KEY = @uniqKey AND IR.WONO = @woNO         
          INNER JOIN kamain K ON IR.KaSeqnum = K.KASEQNUM        
          INNER JOIN  INVTMFGR IM ON IR.W_KEY = IM.W_KEY AND im.UNIQWH = @uniqWHKey        
          AND IM.Location = @location -- 12/13/2017 Rajendra K : Added input parameter @location and applied in join condition         
          INNER JOIN INVTSER ISR ON IRS.serialuniq = ISR.SERIALUNIQ AND IR.W_KEY = ISR.ID_VALUE AND ISR.ID_KEY = 'W_KEY' 
		  -- 06/20/2020 Rajendra K : Added kaseqnum in condition to avoid serial no duplication
		  AND ISR.RESERVEDNO = @kaSeqNumber     
          AND ISNULL(ISR.UNIQ_LOT,1) = ISNULL(@uniqLot,1)        
    WHERE IRS.ipkeyunique = @ipKeyUnique AND IM.UNIQMFGRHD = @uniqMfgrhd        
          -- 09/01/2017 Rajendra K  : Added condition IR.W_KEY = ISR.ID_VALUE AND ISR.ID_KEY = 'W_KEY'        
          AND ISR.ISRESERVED = 1 -- 09/01/2017 Rajendra K : Get only reserved serial numbners from INVTSER        
          AND (@kaSeqNumber IS NULL OR @kaSeqNumber = '' OR IR.KaSeqnum = @kaSeqNumber) -- 10/09/2017 : Rajendra K Added condition to get reserved serial number records for KaSaqNumber        
          AND (@ipKeyUnique IS NULL OR @ipKeyUnique = '' OR IRS.Serialuniq IN(SELECT Serialuniq FROM #tempSerialNumber))        
           -- 10/09/2017 Rajendra K : Get SID specific reserved serial numbers        
        
 UNION         
 SELECT DISTINCT          
   ISer.SerialUniq        
  ,CAST(dbo.fremoveLeadingZeros(ISer.SerialNo) AS VARCHAR(MAX)) AS SerialNo --06/08/2017 Rajendra K  : Replaced using PATINDEX(To remove leading zeros)         
                  --by existing function 'fremoveLeadingZeros'        
                  -- 10/31/2017 Rajendra K : Changed size of SerialNo        
        ,SerialNo AS Serial -- 12/06/2017 Rajendra K : Added column SerialNo(Without removing leading zero's) in select list for sorting        
  ,ISer.UNIQ_KEY        
  ,ISer.UNIQMFGRHD        
  ,ISer.UNIQ_LOT        
  ,ISer.IpKeyUnique        
  ,IMF.W_KEY -- W_Key needed to insert W_Key value in InvtR_Res table when only SerailNumber are available for PartNumber and Manufacturers        
  ,ISer.ISRESERVED -- 06/21/2017 Rajendra K : Added to get reserved serialNumbers        
  ,ISer.ISRESERVED AS IsChecked -- 11/13/2017 Rajendra K : Added parameter IsChecked        
   FROM Inventor I INNER JOIN InvtMpnLink IM ON I.UNIQ_KEY = IM.uniq_key        
        INNER JOIN Invtmfgr IMF ON IM.uniqmfgrhd = IMF.Uniqmfgrhd        
     INNER JOIN MfgrMaster MM ON IM.MfgrMasterId = MM.MfgrMasterId -- 09/13/2017 Rajendra K : Apply WO Reservation default settings        
     AND IMF.Location = @location -- 12/13/2017 Rajendra K : Added input parameter @location and applied in join condition         
     AND IMF.QTY_OH > 0  AND (@nonNettable = 1 OR IMF.NETABLE = 1) -- 09/13/2017 Rajendra K : Apply WO Reservation default settings        
     --AND IMF.InStore = 0    -- 12/06/2019 Rajendra K : Removed the Instore condition to show instore locations      
      AND IMF.IS_DELETED = 0 -- 08/11/2017 Rajendra K : Added this condition to get valid records from InvtMfgr table        
     INNER JOIN invtser ISer ON I.UNIQ_KEY = ISer.UNIQ_KEY AND Iser.ISRESERVED <> 1 -- 08/30/2017 Rajendra K : Added condition to get reserved serial number records from invtres and ireserveserial table        
     AND ISer.ID_VALUE = IMF.W_KEY -- 08/11/2017 Rajendra K : Join column ID_Value(W_Key) from InvtSer table with W_Key column from Invtmfgr to get matching records with SerialUniq from InvtSer        
     -- Modified join condition for LotDetails        
     LEFT OUTER JOIN IPKEY IP ON ISer.ipkeyunique = IP.IPKEYUNIQUE -- 08/21/2017 Rajendra K  : Get records with Ipkeyuniq if Lotdetails not exists        
          OR( ISer.LOTCODE = IP.LOTCODE         
          AND ISer.EXPDATE = IP.EXPDATE        
          AND ISer.PONUM = IP.PONUM        
          AND ISer.REFERENCE = IP.REFERENCE)        
     LEFT JOIN INVTLOT IL ON ISer.LOTCODE = IL.LOTCODE         
          AND ISer.EXPDATE = IL.EXPDATE        
          AND ISer.PONUM = IL.PONUM        
          AND ISer.REFERENCE = IL.REFERENCE        
   WHERE         
   (@uniqKey is null OR @uniqKey = '' OR ISer.UNIQ_KEY = @uniqKey )        
   AND (@uniqMfgrhd is null OR @uniqMfgrhd = '' OR IM.uniqmfgrhd= @uniqMfgrhd)        
   --06/21/2017 Rajendra K : Removed condition ISer.ISRESERVED = 0 to get reserved SerialNumbers         
   AND (@ipKeyUnique is null OR @ipKeyUnique = '' OR ISer.IPKEYUNIQUE= @ipKeyUnique)        
   AND (@ipKeyUnique is null OR @ipKeyUnique = '' OR IP.IPKEYUNIQUE= @ipKeyUnique)        
   AND (@uniqLot is null OR @uniqLot = '' OR ISer.UNIQ_LOT = @uniqLot)        
   AND ID_KEY ='W_KEY' --Get records from InvtSer with only Id_Key = W_Key        
   AND IM.is_deleted = 0 --To Exclude Deleted Manufacturer        
   AND (@uniqWHKey IS NULL OR @uniqWHKey = '' OR IMF.UNIQWH = @uniqWHKey)        
   -- 09/13/2017 Rajendra K : Apply WO Reservation default settings        
     AND (@mfgrDefault = 'All MFGRS'         
     OR (NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A         
        WHERE A.BOMPARENT = @bomParent AND A.UNIQ_KEY = @uniqKey AND A.PARTMFGR = MM.PARTMFGR and A.MFGR_PT_NO = MM.MFGR_PT_NO)))        
   ORDER BY Serial -- 08/02/2017 Rajenrda K Added order by clause by SerialNo        
   -- 12/06/2017 Rajendra K : Changed order by condition(Without removing leading zero's) in select list for sorting        
END 