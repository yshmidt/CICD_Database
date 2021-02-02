-- =============================================        
-- Author:  SachinB      
-- Create date: 07/27/2020        
-- Description: This SP is Used in BOM Import Module for getting Consign Parts for the internal Parts
-- GetInternalPartsConsignData '4964e3b0-ee77-4112-ba12-397a5f61a40e','9480A424-F0D0-EA11-B55B-408D5C0435C0','R04NS93T4B'
-- =============================================        
CREATE PROCEDURE GetInternalPartsConsignData

-- Add the parameters for the stored procedure here        
 @importId UNIQUEIDENTIFIER,        
 @rowId UNIQUEIDENTIFIER,
 @uniqKey char(10)        
AS        
BEGIN   
             
 SET NOCOUNT ON;

 DECLARE @matchTbl TABLE (uniq_key VARCHAR(10),selected BIT,partno VARCHAR(50),rev VARCHAR(8),descript VARCHAR(200),STATUS VARCHAR(10),score INT,          
        C BIT,M INT,D BIT,partClass VARCHAR(8),partType VARCHAR(8),u_of_m VARCHAR(8), standardCost DECIMAL(18,4),color VARCHAR(20),vldtn VARCHAR(20),
		match VARCHAR(500),custNo CHAR(10),CustPartNo CHAR(33),PartSource VARCHAR(10))

 DECLARE @custMatch int,@skipBlankRev bit = 1, @moduleId int

 Declare @CustNo Char(10)

 SELECT @CustNo = custNo FROM importBOMHeader WHERE importId = @importId

 SELECT @moduleId = ModuleId FROM mnxModule WHERE ModuleDesc = 'MnxM_EngProdBOMImport'
      
 DECLARE @sTable mnxSettings     
    
 INSERT INTO @sTable                
 EXEC [settingsGetValues] @moduleId,0,1   

 SELECT @custMatch=COALESCE(settingValue,80) FROM @sTable WHERE settingName='ImpCustPartMatch' 
 SELECT @skipBlankRev=COALESCE(settingValue,1) FROM @sTable WHERE settingName='ImpSkipBlankRev'  

 DECLARE  @tPartsOrig importBom        
 INSERT INTO @tPartsOrig EXEC [dbo].[sp_getImportBOMItems] @importId,0,null,1,@rowId 

/* Customer Part Matches */         
 INSERT INTO @matchTbl(uniq_key,selected,partno,rev,descript,status,score,C,M,D,partClass,partType,u_of_m,standardCost,custNo,CustPartNo,PartSource)          
 SELECT inv.UNIQ_KEY AS UNIQ_KEY,CAST(CASE WHEN tp.rowId IN(SELECT rowId FROM @matchTbl)THEN 0 ELSE 1 END AS bit)selected,        
   inv.PART_NO, inv.REVISION, inv.DESCRIPT, inv.STATUS,@custMatch AS Score,        
   CAST(1 AS bit) AS C, 0 AS M,CAST(0 AS bit) AS D,        
   inv.PART_CLASS,inv.PART_TYPE,inv.U_OF_MEAS,i2.STDCOST,                  
   inv.CUSTNO,        
   CASE COALESCE(NULLIF(inv.CUSTREV,''), '')        
   WHEN '' THEN  LTRIM(RTRIM(inv.CUSTPARTNO))         
   ELSE LTRIM(RTRIM(inv.CUSTPARTNO)) + '/' + inv.CUSTREV         
   END AS CustPartNoWithRev,    
   inv.PART_SOURC              
 FROM INVENTOR inv       
 INNER JOIN @tPartsOrig tp ON tp.custPartNo = inv.CUSTPARTNO         
 INNER JOIN INVENTOR i2 ON i2.UNIQ_KEY = inv.INT_UNIQ              
 WHERE 1=CASE WHEN @skipBlankRev = 0 OR tp.crev<>'' THEN CASE WHEN tp.crev = inv.CUSTREV THEN 1 ELSE 0 END ELSE 1 END AND tp.custPartNo<>''         
 AND @custMatch>0 
 
 --select * from @matchTbl 

 SELECT c.CUSTNAME, inv.CUSTNO,        
   CASE COALESCE(NULLIF(inv.CUSTREV,''), '')        
   WHEN '' THEN  LTRIM(RTRIM(inv.CUSTPARTNO))         
   ELSE LTRIM(RTRIM(inv.CUSTPARTNO)) + '/' + inv.CUSTREV         
   END AS CustPartNoWithRev,inv.DESCRIPT,inv.STATUS,
   CASE WHEN m.uniq_key IS NULL THEN CAST(0 AS BIT)
        ELSE  CAST(1 AS BIT) END AS C,inv.UNIQ_KEY
 FROM INVENTOR inv
 INNER JOIN CUSTOMER c ON inv.CUSTNO =c.CUSTNO
 LEFT JOIN @matchTbl m ON inv.UNIQ_KEY = m.uniq_key AND m.custNo =@CustNo
 WHERE INT_UNIQ =@uniqKey


END