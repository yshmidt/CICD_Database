-- =============================================  
-- Author:  Sachin B  
-- Create date: 10/27/2016  
-- Description: this procedure will be called from the SF module AND get part detail by SerialNo   
-- Sachin B 12/01/2016 Remove warehouse AND conditions AND also get information for the issued serial no  
-- Sachin B 12/14/2016 get lotCode,Expdate,ponum,reference,ipKeyunique from InvtSer table AND check isnull  
-- Sachin B 12/09/2016 get UNIQMFGRHD in Select  
-- Sachin B 09/23/2017 Sachin B Change Code for get serial number detail ON search inf same component is present in more than one WC
-- Sachin B 12/05/2017 Add Join with the KAMAIN table for the get @IsReserve flag
-- Sachin B 12/05/2017 Add Condition and AND k.WONO=@Wono 
-- Unissued Serial no [dbo].[GetPartDetailBySerialNo] '000000000000000000000000000004',0,'0000055410',''  
-- For Issued Serial no [dbo].[GetPartDetailBySerialNo] '000000000000000000545411000495',0,'0000000552','_1LR0NAL9Q'   
-- =============================================  
CREATE PROCEDURE [dbo].[GetPartDetailBySerialNo]   
 -- Add the parameters for the stored procedure here  
 @SerialNo char(30) ='',  
 @IsIssued bit,  
 @Wono char(10),  
 @UniqKey char(10)  
AS  
BEGIN  
  
-- SET NOCOUNT ON added to prevent extra result sets from  
-- interfering with SELECT statements.  
  
SET NOCOUNT ON;  
  
IF(@IsIssued = 0)  
 BEGIN  
     DECLARE @IsReserve BIT  
	 -- Sachin B 12/05/2017 Add Join with the KAMAIN table for the get @IsReserve flag
     SET @IsReserve =(SELECT COUNT(*) FROM INVTSER ser INNER JOIN KAMAIN k ON k.KASEQNUM =ser.RESERVEDNO AND k.WONO =@Wono WHERE SERIALNO =@SerialNo AND ISRESERVED=1 AND RESERVEDFLAG ='KaSeqnum')  
         
      -- Sachin B 12/01/2016 Remove warehouse AND conditions AND also get information for the issued serial no  
	  -- Sachin B 12/14/2016 get lotCode,Expdate,ponum,reference,ipKeyunique from InvtSer table AND check isnull  
	  -- Sachin B 12/09/2016 get UNIQMFGRHD in Select  
	  -- Sachin B 09/23/2017 Sachin B Change Code for get serial number detail ON search inf same component is present in more than one WC   
	IF(@IsReserve =0)  
	   BEGIN  
		SELECT DISTINCT i.UNIQ_KEY,ser.ID_VALUE AS W_Key,ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,ISNULL(ser.LOTCODE,'') AS LOTCODE,ser.EXPDATE,ISNULL(ser.REFERENCE,'') AS REFERENCE,  
		ser.IPKEYUNIQUE,ISNULL(ser.PONUM,'') AS PONUM,ser.SERIALUNIQ,ser.SERIALNO,k.KASEQNUM  
		FROM INVTSER ser    
		INNER JOIN inventor i ON ser.UNIQ_KEY = i.UNIQ_KEY  
		-- Sachin B 12/05/2017 Add Condition and AND k.WONO=@Wono 
		INNER JOIN KAMAIN k ON i.UNIQ_KEY =k.UNIQ_KEY AND k.allocatedQty =0 AND k.WONO=@Wono  
		LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =ser.ID_VALUE AND ISNULL(lot.EXPDATE,1) = ISNULL(ser.EXPDATE,1) AND lot.LOTCODE = ser.LOTCODE AND lot.REFERENCE = ser.REFERENCE  
		WHERE ser.SERIALNO = @SerialNo AND ser.ID_KEY ='W_Key'   
	   END  
	  ELSE  
	   BEGIN  
		SELECT DISTINCT i.UNIQ_KEY,ser.ID_VALUE AS W_Key,ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,ISNULL(ser.LOTCODE,'') AS LOTCODE,ser.EXPDATE,ISNULL(ser.REFERENCE,'') AS REFERENCE,  
		ser.IPKEYUNIQUE,ISNULL(ser.PONUM,'') AS PONUM,ser.SERIALUNIQ,ser.SERIALNO,ser.RESERVEDNO AS KaSeqnum  
		FROM INVTSER ser     
		INNER JOIN inventor i ON ser.UNIQ_KEY = i.UNIQ_KEY   
		LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =ser.ID_VALUE AND ISNULL(lot.EXPDATE,1) = ISNULL(ser.EXPDATE,1) AND lot.LOTCODE = ser.LOTCODE AND lot.REFERENCE = ser.REFERENCE  
		WHERE ser.SERIALNO = @SerialNo AND ser.ID_KEY ='W_Key'     
	   END         
 END  

ELSE  
 BEGIN  
     -- Sachin B 12/01/2016 Remove warehouse AND conditions AND also get information for the issued serial no  
  -- Sachin B 12/14/2016 get lotCode,Expdate,ponum,reference,ipKeyunique from InvtSer table AND check isnull  
  -- Sachin B 12/09/2016 get UNIQMFGRHD in Select  
  SELECT DISTINCT i.UNIQ_KEY,imfgr.W_KEY,ISNULL(lot.UNIQ_LOT,'') AS UNIQ_LOT,ISNULL(ser.LOTCODE,'') AS LOTCODE,ser.EXPDATE,ISNULL(ser.REFERENCE,'') AS REFERENCE,  
  ser.IPKEYUNIQUE,ISNULL(lot.PONUM,'') AS PONUM,ser.SERIALUNIQ,ser.SERIALNO,imfgr.UNIQMFGRHD  
  FROM inventor i  
  INNER JOIN INVTSER ser ON ser.UNIQ_KEY = i.UNIQ_KEY --AND ser.ID_VALUE =imfgr.W_KEY  
  INNER JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY  
  INNER JOIN MfgrMaster mfMaster  ON mfMaster.MfgrMasterId = mpn.MfgrMasterId    
  INNER JOIN INVTMFGR imfgr ON imfgr.UNIQ_KEY =i.UNIQ_KEY AND ser.uniqmfgrhd = imfgr.UNIQMFGRHD  
  INNER JOIN WAREHOUS w ON imfgr.UNIQWH = w.UNIQWH       
  LEFT OUTER JOIN IPKEY ip ON ip.W_KEY =imfgr.W_KEY AND imfgr.UNIQ_KEY = i.UNIQ_KEY AND ip.IPKEYUNIQUE =ser.ipkeyunique  
  LEFT OUTER JOIN INVTLOT lot ON lot.W_KEY =imfgr.W_KEY AND ISNULL(lot.EXPDATE,1) = ISNULL(ser.EXPDATE,1) AND lot.LOTCODE = ser.LOTCODE AND lot.REFERENCE = ser.REFERENCE  
  WHERE ser.SERIALNO = @SerialNo  AND ser.ID_KEY ='WONO' AND ser.ID_VALUE = @Wono AND ser.UNIQ_KEY = @UniqKey  
 END  

END