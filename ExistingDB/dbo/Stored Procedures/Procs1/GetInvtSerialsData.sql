-- ============================================================================================================  
-- Date   : 12/02/2019  
-- Author  : Rajendra K 
-- Description : Used for Validate  data  
-- GetInvtSerialsData '97F5ED20-7497-49CF-9DA4-8E2CAD8913B4'  
-- ============================================================================================================    
CREATE PROC GetInvtSerialsData
 @ImportId UNIQUEIDENTIFIER,
 @RowId UNIQUEIDENTIFIER = null
AS  
BEGIN  
   
  SET NOCOUNT ON   
  DECLARE @ModuleId INT
							     
  DECLARE @PartDetail TABLE (importId UNIQUEIDENTIFIER,RowId UNIQUEIDENTIFIER,CssClass VARCHAR(MAX),Validation VARCHAR(MAX), countQty NUMERIC(9,2),
							  part_sourc CHAR(10),part_no CHAR(25),revision CHAR(8),partmfgr CHAR(8),mfgr_pt_no CHAR(30),warehouse CHAR(6),location VARCHAR(200),
							  Lotcode CHAR(25) ,ExpDate DATE,Reference CHAR(12),Ponum CHAR(15),MTC CHAR(10),QtyPerPackage NUMERIC(9,2),
							  SERIALITEMS VARCHAR(MAX),W_KEY CHAR(10),UNIQMFGRHD CHAR(10),UNIQ_KEY CHAR(10),UNIQ_LOT CHAR(10),UNIQWH CHAR(10),SERIALYES BIT,useipkey BIT
							  ,QTY_OH NUMERIC(9,2),IsLotted BIT,INSTORE BIT, SenderId CHAR(10),SenderType CHAR(1))   

  SELECT @ModuleId = ModuleId FROM MnxModule WHERE ModuleDesc = 'MnxM_InventoryAdjustmentUpload' and FilePath = 'InventoryAdjustmentUpload'      
  INSERT INTO @PartDetail EXEC GetInvtAdjustValidData @importId,1;	

 ;WITH SerialDetail AS(
	SELECT PVT.*  
	FROM    
	(   
		SELECT f.fkImportId AS importId,iaf.FkRowId,iaf.SerialRowId,sub.class as CssClass,sub.Validation,fd.fieldName,iaf.adjusted 
		FROM ImportFieldDefinitions fd      
		   INNER JOIN ImportInvtAdjustSerialFields iaf ON fd.FieldDefId = iaf.FKFieldDefId 
		   INNER JOIN ImportInvtAdjustFields f ON f.RowId = iaf.FkRowId   
		   INNER JOIN   
		   (   
			    SELECT fkImportId,fd.FkRowId,SerialRowId,MAX(fd.status) as Class ,MIN(fd.Message) as Validation		
			    FROM ImportInvtAdjustSerialFields fd  
				INNER JOIN ImportInvtAdjustFields f ON fd.FkRowId = f.RowId
				INNER JOIN ImportFieldDefinitions ibf ON fd.FKFieldDefId = ibf.FieldDefId
			    WHERE fkImportId =CAST(@importId as CHAR(36))
				AND FieldName IN ('SERIALITEMS','Serialno')  
			    GROUP BY fkImportId,fd.FkRowId,SerialRowId 
		   ) Sub    
		 ON Sub.SerialRowId = iaf.SerialRowId
		 WHERE f.fkImportId =CAST(@importId as CHAR(36))
		) st    
	 PIVOT (MAX(adjusted) FOR fieldName IN ([SERIALITEMS],[Serialno])   
	) as PVT
  )

  SELECT s.*,CAST(CASE WHEN ISNULL(invtSer.SERIALUNIQ,'') = '' THEN 0 ELSE 1 END AS BIT) AS IsSerialExists
  FROM SerialDetail s 
  JOIN @PartDetail p ON s.FkRowId = p.RowId
  OUTER APPLY 
  (
		SELECT TOP 1 SERIALUNIQ 
		FROM INVTSER 
		WHERE SERIALNO =RIGHT(REPLICATE('0', 30) + LTRIM(s.Serialno), 30) AND UNIQ_KEY = p.UNIQ_KEY AND UNIQMFGRHD = p.UNIQMFGRHD
  ) invtSer
  ORDER BY s.Serialno  
END