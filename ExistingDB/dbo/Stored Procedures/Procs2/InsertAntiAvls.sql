 -- ============================================================================================================  
-- Date   : 09/03/2019  
-- Author  : Rajendra K 
-- Description : Used for get Components upload data  
-- InsertAntiAvls 'B5013418-C4A4-4BC2-BF8D-4651A51B9E45'    
-- ============================================================================================================    
CREATE PROC InsertAntiAvls
 @ImportId UNIQUEIDENTIFIER  
AS  
BEGIN  
 SET NOCOUNT ON; 
	DECLARE  @Bomparent CHAR(10);
	DECLARE @MfgrDetails TABLE (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CompRowId	UNIQUEIDENTIFIER,AvlRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),
			Validation VARCHAR(100),partMfg	VARCHAR(100), mpn VARCHAR(100),Warehouse VARCHAR(100),Location VARCHAR(100),ResQty	VARCHAR(100),UNIQ_KEY VARCHAR(100),
			partno	VARCHAR(100),rev VARCHAR(100),custPartNo VARCHAR(100),crev VARCHAR(100),IsLotted BIT,WorkCenter VARCHAR(MAX))
	
	DECLARE @Bom Table (importId UNIQUEIDENTIFIER,AssemblyRowId UNIQUEIDENTIFIER,CssClass VARCHAR(100),Validation VARCHAR(100),assyDesc VARCHAR(100)
			,assyNum VARCHAR(100),assypartclass VARCHAR(100),assyparttype VARCHAR(100),assyRev VARCHAR(100),custno VARCHAR(100),UNIQ_KEY VARCHAR(10));  

	DECLARE @AntiAvls Table (UNIQ_KEY CHAR(10),partmfgr CHAR(8),mfgr_pt_no CHAR(30))
	
	INSERT INTO @MfgrDetails EXEC GetManufactureUploadData @importId;
	-- SELECT * FROM @MfgrDetails
	INSERT INTO @Bom EXEC GetAssemblyRecords @importId
	SELECT TOP 1 @Bomparent= UNIQ_KEY FROM @Bom
	IF (@Bomparent <>'')
	BEGIN
		BEGIN TRY    
		BEGIN TRANSACTION  

			INSERT INTO @AntiAvls 
			SELECT DISTINCT i.UNIQ_KEY,TRIM(PartMfgr) partmfgr,TRIM(mfgr_pt_no) mpn  	  
			FROM INVENTOR i 
			         INNER JOIN @MfgrDetails md ON md.UNIQ_KEY = i.UNIQ_KEY
					 INNER JOIN  InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY    
					 INNER JOIN  MfgrMaster mfM  ON mfM.MfgrMasterId = mpn.MfgrMasterId  AND mfM.IS_DELETED = 0  
					 INNER JOIN  INVTMFGR im ON im.UNIQ_KEY =i.UNIQ_KEY AND im.UNIQMFGRHD = mpn.uniqmfgrhd AND 	im.IS_DELETED = 0
					 INNER JOIN  WAREHOUS wa ON im.UNIQWH = wa.UNIQWH 
			WHERE (mfM.PartMfgr != md.partMfg AND mfM.mfgr_pt_no != md.mpn) OR (md.ResQty = '' OR md.ResQty = 0)
			ORDER BY i.UNIQ_KEY,PartMfgr,mpn

			-- Insert into antiavl table 
			INSERT INTO ANTIAVL (Bomparent ,uniq_key ,partmfgr ,mfgr_pt_no ,uniqanti) 
			SELECT @Bomparent,UNIQ_KEY,partmfgr,mfgr_pt_no,dbo.fn_GenerateUniqueNumber()  
			FROM @AntiAvls
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
		END CATCH
	END	
END