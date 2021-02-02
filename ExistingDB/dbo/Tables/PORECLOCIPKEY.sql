CREATE TABLE [dbo].[PORECLOCIPKEY] (
    [IPKEYLOCUNIQUE] CHAR (10)       CONSTRAINT [DF_PORECLOCIPKEY_IPKEYLOCUNIQUE] DEFAULT ('') NOT NULL,
    [IPKEYUNIQUE]    CHAR (10)       CONSTRAINT [DF_PORECLOCIPKEY_FK_IPKEYUNIQUE] DEFAULT ('') NOT NULL,
    [LOC_UNIQ]       CHAR (10)       CONSTRAINT [DF_PORECLOCIPKEY_FK_LOC_UNIQ] DEFAULT ('') NOT NULL,
    [qtyPerPackage]  NUMERIC (12, 2) CONSTRAINT [DF_PORECLOCIPKEY_NQPP] DEFAULT ((0)) NOT NULL,
    [accptQty]       NUMERIC (12, 2) CONSTRAINT [DF_PORECLOCIPKEY_IPKLOCACCPTQTY] DEFAULT ((0)) NOT NULL,
    [rejQty]         NUMERIC (12, 2) CONSTRAINT [DF_PORECLOCIPKEY_IPKLOCREJQTY] DEFAULT ((0)) NOT NULL,
    [allocQty]       NUMERIC (12, 2) CONSTRAINT [DF_PORECLOCIPKEY_IPKLOCQALLOC] DEFAULT ((0)) NOT NULL,
    [issuedQty]      NUMERIC (12, 2) CONSTRAINT [DF_PORECLOCIPKEY_IPKLOCQISSUE] DEFAULT ((0)) NOT NULL,
    [lot_uniq]       CHAR (10)       CONSTRAINT [DF_PORECLOCIPKEY_lot_uniq] DEFAULT ('') NOT NULL,
    CONSTRAINT [PORECLOCIPKEY_PK] PRIMARY KEY CLUSTERED ([IPKEYLOCUNIQUE] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IPKEYUNIQ]
    ON [dbo].[PORECLOCIPKEY]([IPKEYUNIQUE] ASC);


GO
CREATE NONCLUSTERED INDEX [LOC_UNIQ]
    ON [dbo].[PORECLOCIPKEY]([LOC_UNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [lot_uniq]
    ON [dbo].[PORECLOCIPKEY]([lot_uniq] ASC);


GO
-- =========================================================================================================
-- Author:		Shivshankar P
-- Create date: 20/03/2017
-- Description:	Delete Trigger for PORECLOCIPKEY table
-- =========================================================================================================
CREATE TRIGGER [dbo].[PORECLOCIPKEY_DELETE]
       ON [dbo].[PORECLOCIPKEY]
AFTER DELETE
AS
BEGIN
       SET NOCOUNT ON;
	    BEGIN
			BEGIN TRANSACTION
			BEGIN TRY

               DELETE from IPKEY where IPKEYUNIQUE in (select IPKEYUNIQUE from DELETED)

	        	END TRY	
				BEGIN CATCH
					IF @@TRANCOUNT <>0
						ROLLBACK TRAN ;
				END CATCH	
			
				IF @@TRANCOUNT>0
				COMMIT TRANSACTION
			END 				 		
	END
GO
-- ====================================================================================  
-- Author:  Nitesh B  
-- Create date: 07/13/2016  
-- Description: Generate the SID    
-- 05/31/2017 Shivshankar P : Remove for inserting Empty in 'originalIpkeyUnique'  
-- Nitesh B  05/31/2017 : Added INVTMFGR.INSTORE = 0 AND INVTMFGR.NETABLE = 1 condition
-- Nitesh B  01/28/2019 : Added CASE WHEN (t.lotCode <>'') THEN t.poNum ELSE '' END condition
-- Shivshankar P  06/24/2020 : Remove INVTMFGR.NETABLE = 1 condition to generate MTC when we receive in Netable location
-- ====================================================================================  
CREATE TRIGGER [dbo].[PoRecLocIpKey_INSERT]  
   ON  [dbo].[PORECLOCIPKEY]  
   AFTER INSERT  
AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 -- Insert statements for trigger here  
  BEGIN   
   DECLARE @accptQty numeric(10,2),@qtyWithUOMConversion numeric(10,2);  
   DECLARE @ErrorMsg VARCHAR(MAX);  
   SELECT  @accptQty=accptQty from inserted  
   DECLARE @temp table (uniqKey char(10),uniqmfgrhd char(10),lotCode char(15) default '',poNum char(15),reference char(12),expDate smalldatetime,  
    recordId char(10),W_KEY char(10),fkUserId uniqueidentifier,TRANSTYPE char(1) default 'P',SUOM char(4),PUOM char(4))  
  
   Insert Into @temp(uniqKey,uniqmfgrhd,recordId,poNum,fkUserId,W_KEY,lotCode,reference,expDate,SUOM,PUOM)  
                    SELECT receiverDetail.Uniq_key,porecdtl.uniqmfgrhd,porecdtl.uniqrecdtl,receiverHeader.ponum,porecdtl.Edituserid, INVTMFGR.W_KEY,  
         Isnull(PORECLOT.LOTCODE,''),Isnull(PORECLOT.REFERENCE,''),PORECLOT.EXPDATE,porecdtl.U_of_meas,porecdtl.pur_uofm  
         FROM inserted  
         inner join PORECLOC on inserted.LOC_UNIQ = PORECLOC.LOC_UNIQ  
         inner join porecdtl on PORECLOC.FK_UNIQRECDTL = porecdtl.uniqrecdtl  
         inner join receiverDetail on porecdtl.receiverdetId = receiverDetail.receiverDetId  
         inner join receiverHeader on receiverDetail.receiverHdrId = receiverHeader.receiverHdrId  
         left join INVTMFGR on receiverDetail.Uniq_key = INVTMFGR.UNIQ_KEY  AND INVTMFGR.INSTORE = 0 --AND INVTMFGR.NETABLE = 1
		 -- Shivshankar P  06/24/2020 : Remove INVTMFGR.NETABLE = 1 condition to generate MTC when we receive in Netable location
		 -- Nitesh B  05/31/2017 : Added INVTMFGR.INSTORE = 0 AND INVTMFGR.NETABLE = 1 condition
         left join PORECLOT on PORECLOC.LOC_UNIQ = PORECLOT.LOC_UNIQ and PORECLOT.LOT_UNIQ = inserted.lot_uniq  
   Where INVTMFGR.UNIQWH=PORECLOC.UNIQWH and INVTMFGR.LOCATION=PORECLOC.LOCATION and INVTMFGR.UNIQMFGRHD = porecdtl.uniqmfgrhd;  
   BEGIN TRANSACTION  
    BEGIN TRY  
     -- Nitesh B: set the qty based UOM Conversion  
     select @qtyWithUOMConversion = dbo.fn_ConverQtyUOM(t1.PUOM, t1.SUOM,@accptQty) FROM @temp t1  
     Insert Into IPKEY(IPKEYUNIQUE,originalIpkeyUnique,fk_userid,LOTCODE,PONUM,originalPkgQty,pkgBalance,QtyAllocatedOver,qtyAllocatedTotal,  
     recordCreated,RecordId,REFERENCE,TRANSTYPE,UNIQ_KEY,UNIQMFGRHD,UNIQMFSP,W_KEY,EXPDATE)  
     SELECT inserted.IPKEYUNIQUE,''  --dbo.fn_GenerateUniqueNumber()  -- 05/31/2017 Shivshankar P : Remove for inserting Empty in 'originalIpkeyUnique'  
     ,t.fkUserId,t.lotCode,
	 CASE WHEN (t.lotCode <>'') THEN t.poNum ELSE '' END, -- Nitesh B  01/28/2019 : Added CASE WHEN (t.lotCode <>'') THEN t.poNum ELSE '' END condition
	 @qtyWithUOMConversion,@qtyWithUOMConversion,0,0,GETDATE(),t.recordId,t.reference,  
     t.TRANSTYPE,t.uniqKey,t.uniqmfgrhd,'',t.W_KEY,t.expDate  
     FROM inserted,@temp t  
    END TRY  
    BEGIN CATCH  
     IF @@TRANCOUNT > 0  
     SELECT @ErrorMsg = ERROR_MESSAGE();  
     RAISERROR (@ErrorMsg,16,1);  
     ROLLBACK TRANSACTION;  
     RETURN  
    END CATCH  
 IF @@TRANCOUNT > 0  
  COMMIT TRANSACTION  
  ENd  
END  
  