CREATE TABLE [dbo].[BOM_DET] (
    [UNIQBOMNO]          CHAR (10)        CONSTRAINT [DF__BOM_DET__UNIQBOM__07E124C1] DEFAULT ('') NOT NULL,
    [ITEM_NO]            NUMERIC (4)      CONSTRAINT [DF__BOM_DET__ITEM_NO__08D548FA] DEFAULT ((0)) NOT NULL,
    [BOMPARENT]          CHAR (10)        CONSTRAINT [DF__BOM_DET__BOMPARE__09C96D33] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]           CHAR (10)        CONSTRAINT [DF__BOM_DET__UNIQ_KE__0ABD916C] DEFAULT ('') NOT NULL,
    [DEPT_ID]            CHAR (4)         CONSTRAINT [DF__BOM_DET__DEPT_ID__0BB1B5A5] DEFAULT ('') NOT NULL,
    [QTY]                NUMERIC (9, 2)   CONSTRAINT [DF__BOM_DET__QTY__0CA5D9DE] DEFAULT ((0)) NOT NULL,
    [ITEM_NOTE]          VARCHAR (MAX)    NULL,
    [OFFSET]             NUMERIC (4)      CONSTRAINT [DF__BOM_DET__OFFSET__0E8E2250] DEFAULT ((0)) NOT NULL,
    [TERM_DT]            SMALLDATETIME    NULL,
    [EFF_DT]             SMALLDATETIME    NULL,
    [USED_INKIT]         CHAR (1)         CONSTRAINT [DF__BOM_DET__USED_IN__0F824689] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT              CONSTRAINT [DF_BOM_DET_IsSynchronizationFlag] DEFAULT ((0)) NOT NULL,
    [ModifiedBy]         UNIQUEIDENTIFIER CONSTRAINT [DF__BOM_DET__Modifie__558F7328] DEFAULT (NULL) NULL,
    CONSTRAINT [BOM_DET_PK] PRIMARY KEY CLUSTERED ([UNIQBOMNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BOMPARENT]
    ON [dbo].[BOM_DET]([BOMPARENT] ASC);


GO
CREATE NONCLUSTERED INDEX [BOMUNIQDEP]
    ON [dbo].[BOM_DET]([BOMPARENT] ASC, [UNIQ_KEY] ASC, [DEPT_ID] ASC);


GO
CREATE NONCLUSTERED INDEX [COMPONENT]
    ON [dbo].[BOM_DET]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [DATESINCL]
    ON [dbo].[BOM_DET]([TERM_DT] ASC, [EFF_DT] ASC)
    INCLUDE([UNIQ_KEY]);


GO

-- =============================================
-- Author:Sachin shevale
-- Create date: <09/14/2015>
-- Description:	<Delete trigger for sync the records>
-- 09-29-2015 sachin s -remove the above code already delted
-- 08/08/18 Shripati U Insert Data in BOMChangeLog Table
-- 10/25/2018 Shrikant Added Column ChangeInfo for bom maintain bom change log info
-- =============================================
CREATE TRIGGER [dbo].[Bom_Det_Delete] 
   ON  [dbo].[BOM_DET]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for trigger here
	BEGIN TRANSACTION	
		
	-- 08/08/18 Shripati U Insert Data in BOMChangeLog Table
	-- 10/25/2018 Shrikant Added Column ChangeInfo for bom maintain bom change log info
	INSERT into BOMChangeLog (UNIQBOMNO, ITEM_NO, BOMPARENT, UNIQ_KEY, DEPT_ID, QTY, ITEM_NOTE, OFFSET, TERM_DT, EFF_DT, USED_INKIT,ModifiedBy, ModifiedOn,ChangeInfo) 
	SELECT UNIQBOMNO, ITEM_NO, BOMPARENT, UNIQ_KEY, DEPT_ID, QTY, ITEM_NOTE, OFFSET, TERM_DT, EFF_DT, USED_INKIT, ModifiedBy, GETDATE(),'Item Deleted'
	FROM Deleted 

	 --DELETE FROM BOM_DET WHERE UNIQBOMNO in (SELECT UNIQBOMNO FROM Deleted)
	 --09-29-2015 sachin s -remove the above code already delted
	INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'BOM_DET'
           ,'UNIQBOMNO'
           ,Deleted.UNIQBOMNO from Deleted
	COMMIT
END
GO
-- =============================================
-- Author : Rajendra K
-- Create date : 11/07/2017
-- Description : Insert trigger for BOM_DET table
-- 08/08/18 Shripati U Insert Data on the BOMChangeLog table
-- 10/25/2018 Shrikant Added Column ChangeInfo for bom maintain bom change log info
-- =============================================
CREATE TRIGGER [dbo].[BOM_DET_INSERT]
   ON  [dbo].[BOM_DET]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;	
	    -- interfering with SELECT statements.
		-- SET ITAR 1 for BOM_PARENT if inserted components have ITAR value 1
		UPDATE INVENTOR SET ITAR = 1 FROM INVENTOR INNER JOIN
		(SELECT BOMPARENT FROM INVENTOR I INNER JOIN Inserted Insd ON I.UNIQ_KEY = Insd.UNIQ_KEY WHERE I.ITAR = 1
		)INS ON INVENTOR.UNIQ_KEY = INS.BOMPARENT

		--08/08/18 Shripati U Insert Data on the BOMChangeLog table
		-- 10/25/2018 Shrikant Added Column ChangeInfo for bom maintain bom change log info
		INSERT into BOMChangeLog (UNIQBOMNO, ITEM_NO ,BOMPARENT, UNIQ_KEY, DEPT_ID, QTY, ITEM_NOTE, OFFSET, TERM_DT, EFF_DT, USED_INKIT,
			ModifiedBy, ModifiedOn, ChangeInfo) 
	    SELECT UNIQBOMNO, ITEM_NO, BOMPARENT, UNIQ_KEY, DEPT_ID, QTY, ITEM_NOTE, OFFSET, TERM_DT, EFF_DT, USED_INKIT, ModifiedBy, GETDATE(),'Item Added'  
		FROM Inserted 
	 
END
GO

-- =============================================  
-- Author:  Sachin Shevale  
-- Create date: 09/14/2014  
-- Description: Update trigger for BOM_DET table  
-- 08/08/18 Shripati U Insert Data in the BOMChangeLog table  
-- 10/25/2018 Shrikant Added Column ChangeInfo for bom maintain bom change log info  
-- 12/07/2018 Shrikant change JOIN type from INNER to LEFT   
-- 12/07/2018 Shrikant added condition for quantity null   
-- 12/07/2018 Shrikant Change EFF date condition   
-- 12/17/2018 Shrikant add Quantity, EFF and Obsolute date condition (All 3 Updated Quantity,EFF, TERM_DT)
-- 12/17/2018 Shrikant add Quantity, EFF, Obsolute date condition (Quantity same but EFF_DT and TERM_DT modified)
-- 12/07/2018 Shrikant added condition for quantity null and eff updated (Termination date same but effective date and quantity Modified)  
-- 12/07/2018 Shrikant added condition for quantity null and eff updated (effective date same but Termination date and quantity Modified)  
-- 12/17/2018 Shrikant Add TERM date condition (only termination date updated) 
-- 12/07/2018 Shrikant Change EFF date condition (only EFF_DT date updated) 
-- =============================================  
CREATE TRIGGER [dbo].[BOM_DET_UPDATE]  
   ON  [dbo].[BOM_DET]  
   AFTER UPDATE  
AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 UPDATE BOM_DET SET   
    -- Insert statements for trigger here  
  IsSynchronizedFlag=   
      CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0  
         WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1  
      ELSE 0 END       
     FROM inserted I INNER JOIN deleted D on i.UNIQBOMNO=d.UNIQBOMNO  
     where I.UNIQBOMNO =BOM_DET.UNIQBOMNO    
   --09-24-2015 Delete the records from SynchronizationMultiLocationLog table if exists with same UNIQ_KEY so all location pick again  
 IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)  
 BEGIN  
  DELETE FROM SynchronizationMultiLocationLog   
  where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UNIQBOMNO=SynchronizationMultiLocationLog.Uniquenum);  
 END   
  
 -- 08/08/18 Shripati U Insert Data in the BOMChangeLog table  
 -- 10/25/2018 Shrikant Added Column ChangeInfo for bom maintain bom change log info   
 ;WITH BomoldData AS(  
  SELECT TOP 1 b.*   
  FROM Inserted i  
  INNER JOIN BOMChangeLog b on i.UNIQBOMNO =b.UNIQBOMNO   
  ORDER BY b.ModifiedOn DESC  
 )   
     
 INSERT INTO BOMChangeLog(UNIQBOMNO, ITEM_NO, BOMPARENT, UNIQ_KEY, DEPT_ID, QTY, ITEM_NOTE, OFFSET, TERM_DT, EFF_DT, USED_INKIT, ModifiedBy,    
  ModifiedOn, ChangeInfo)     
 SELECT top 1 i.UNIQBOMNO, i.ITEM_NO, i.BOMPARENT,  i.UNIQ_KEY, i.DEPT_ID, i.QTY, i.ITEM_NOTE, i.OFFSET, i.TERM_DT, i.EFF_DT, i.USED_INKIT    
 , i.ModifiedBy,GETDATE(),    
 CASE   
   -- 12/17/2018 Shrikant add Quantity, EFF and Obsolute date condition (All 3 Updated Quantity,EFF, TERM_DT)
    WHEN i.QTY<>ISNULL((b.QTY),0)   
     AND ((i.EFF_DT<>b.EFF_DT) OR (i.EFF_DT IS NULL AND b.EFF_DT IS NOT NULL) OR (i.EFF_DT IS NOT NULL AND b.EFF_DT IS NULL ))  
     AND ((i.TERM_DT<>b.TERM_DT) OR (i.TERM_DT IS NULL AND b.TERM_DT IS NOT NULL) OR (i.TERM_DT IS NOT NULL AND b.TERM_DT IS NULL ))  
    THEN  'Item Updated, Quantity Updated from '+CAST(b.QTY AS NVARCHAR(9))+' to '+CAST(i.QTY AS NVARCHAR(9))+', Effective Date Updated and Obsolute Date Updated'
  
  -- 12/17/2018 Shrikant add Quantity, EFF, Obsolute date condition (Quantity same but EFF_DT and TERM_DT modified)
    WHEN i.QTY = b.QTY  
     AND ((i.EFF_DT<>b.EFF_DT) OR (i.EFF_DT IS NULL AND b.EFF_DT IS NOT NULL) OR (i.EFF_DT IS NOT NULL AND b.EFF_DT IS NULL ))  
     AND ((i.TERM_DT<>b.TERM_DT) OR (i.TERM_DT IS NULL AND b.TERM_DT IS NOT NULL) OR (i.TERM_DT IS NOT NULL AND b.TERM_DT IS NULL ))  
    THEN 'Item Updated, Effective Date Updated and Obsolute Date Updated'  

 -- 12/07/2018 Shrikant added condition for quantity null and eff updated (Termination date same but effective date and quantity Modified)  
    WHEN i.QTY<>ISNULL((b.QTY),0)   
     -- 12/07/2018 Shrikant Change EFF date condition   
     AND ((i.EFF_DT<>b.EFF_DT) OR (i.EFF_DT IS NULL AND b.EFF_DT IS NOT NULL) OR (i.EFF_DT IS NOT NULL AND b.EFF_DT IS NULL ))  
    THEN 'Item Updated, Quantity Updated from '+CAST(b.QTY AS NVARCHAR(9))+' to '+CAST(i.QTY AS NVARCHAR(9))+', and Effective Date Updated'  
  
   -- 12/07/2018 Shrikant added condition for quantity null and eff updated (effective date same but Termination date and quantity Modified)  
    WHEN i.QTY<>ISNULL((b.QTY),0)    
     AND ((i.TERM_DT<>b.TERM_DT) OR (i.TERM_DT IS NULL AND b.TERM_DT IS NOT NULL) OR (i.TERM_DT IS NOT NULL AND b.TERM_DT IS NULL ))  
    THEN 'Item Updated, Quantity Updated from '+CAST(b.QTY AS NVARCHAR(9))+' to '+CAST(i.QTY AS NVARCHAR(9))+', and Obsolute Date Updated'  
  
  -- 12/17/2018 Shrikant Add TERM date condition (only termination date updated) 
    WHEN ((i.TERM_DT<>b.TERM_DT) OR  (i.TERM_DT IS NULL AND b.TERM_DT IS NOT NULL) OR (i.TERM_DT IS NOT NULL AND b.TERM_DT IS NULL))  
    THEN 'Item Updated, Obsolute Date Updated'  

    -- 12/07/2018 Shrikant Change EFF date condition (only EFF_DT date updated) 
    WHEN ((i.EFF_DT<>b.EFF_DT) OR  (i.EFF_DT IS NULL AND b.EFF_DT IS NOT NULL) OR (i.EFF_DT IS NOT NULL AND b.EFF_DT IS NULL))  
    THEN 'Item Updated, Effective Date Updated'  

	--(only Quantity updated) 
    WHEN i.QTY<>ISNULL((b.QTY),0)   
    THEN 'Item Updated, Quantity Updated from '+CAST(b.QTY AS NVARCHAR(9))+' to '+CAST(i.QTY AS NVARCHAR(9))+''  
  
    ELSE 'Item Updated'  
    END AS ChangeInfo  
 FROM Inserted i  
 -- 12/07/2018 Shrikant change JOIN type from INNER to LEFT   
 LEFT JOIN BomoldData b on i.UNIQBOMNO =b.UNIQBOMNO  
 ORDER BY ModifiedOn DESC  
     
END  