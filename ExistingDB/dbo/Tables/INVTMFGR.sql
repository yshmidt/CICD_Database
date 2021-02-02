CREATE TABLE [dbo].[INVTMFGR] (
    [UNIQ_KEY]           CHAR (10)       CONSTRAINT [DF__INVTMFGR__UNIQ_K__310E22DD] DEFAULT ('') NOT NULL,
    [QTY_OH]             NUMERIC (12, 2) CONSTRAINT [DF__INVTMFGR__QTY_OH__32024716] DEFAULT ((0)) NOT NULL,
    [RESERVED]           NUMERIC (12, 2) CONSTRAINT [DF__INVTMFGR__RESERV__32F66B4F] DEFAULT ((0)) NOT NULL,
    [NETABLE]            BIT             CONSTRAINT [DF__INVTMFGR__NETABL__34DEB3C1] DEFAULT ((0)) NOT NULL,
    [COUNT_DT]           SMALLDATETIME   NULL,
    [COUNT_TYPE]         CHAR (3)        CONSTRAINT [DF__INVTMFGR__COUNT___35D2D7FA] DEFAULT ('') NOT NULL,
    [RSTK_ORD]           NUMERIC (12, 2) CONSTRAINT [DF__INVTMFGR__RSTK_O__36C6FC33] DEFAULT ((0)) NOT NULL,
    [COUNT_INIT]         CHAR (8)        CONSTRAINT [DF__INVTMFGR__COUNT___37BB206C] DEFAULT ('') NULL,
    [LOCATION]           NVARCHAR (200)  CONSTRAINT [DF__INVTMFGR__LOCATI__39A368DE] DEFAULT ('') NOT NULL,
    [W_KEY]              CHAR (10)       CONSTRAINT [DF__INVTMFGR__W_KEY__3A978D17] DEFAULT ('') NOT NULL,
    [INSTORE]            BIT             CONSTRAINT [DF__INVTMFGR__INSTOR__3B8BB150] DEFAULT ((0)) NOT NULL,
    [REORDPOINT]         NUMERIC (8)     CONSTRAINT [DF__INVTMFGR__REORDP__3D73F9C2] DEFAULT ((0)) NOT NULL,
    [REORDERQTY]         NUMERIC (8)     CONSTRAINT [DF__INVTMFGR__REORDE__3E681DFB] DEFAULT ((0)) NOT NULL,
    [MARKING]            CHAR (10)       CONSTRAINT [DF__INVTMFGR__MARKIN__3F5C4234] DEFAULT ('') NOT NULL,
    [PKG]                CHAR (10)       CONSTRAINT [DF__INVTMFGR__PKG__4050666D] DEFAULT ('') NOT NULL,
    [BODY]               CHAR (8)        CONSTRAINT [DF__INVTMFGR__BODY__41448AA6] DEFAULT ('') NOT NULL,
    [WIDTH]              NUMERIC (6)     CONSTRAINT [DF__INVTMFGR__WIDTH__4238AEDF] DEFAULT ((0)) NOT NULL,
    [PITCH]              NUMERIC (6)     CONSTRAINT [DF__INVTMFGR__PITCH__432CD318] DEFAULT ((0)) NOT NULL,
    [SAFETYSTK]          NUMERIC (7)     CONSTRAINT [DF__INVTMFGR__SAFETY__4420F751] DEFAULT ((0)) NOT NULL,
    [COUNTFLAG]          CHAR (1)        CONSTRAINT [DF__INVTMFGR__COUNTF__45151B8A] DEFAULT ('') NOT NULL,
    [IS_DELETED]         BIT             CONSTRAINT [DF__INVTMFGR__IS_DEL__46093FC3] DEFAULT ((0)) NOT NULL,
    [IS_VALIDATED]       BIT             CONSTRAINT [DF__INVTMFGR__IS_VAL__46FD63FC] DEFAULT ((0)) NOT NULL,
    [UNIQMFGRHD]         CHAR (10)       CONSTRAINT [DF__INVTMFGR__UNIQMF__47F18835] DEFAULT ('') NOT NULL,
    [UNIQWH]             CHAR (10)       CONSTRAINT [DF__INVTMFGR__UNIQWH__48E5AC6E] DEFAULT ('') NOT NULL,
    [uniqsupno]          CHAR (10)       CONSTRAINT [DF_INVTMFGR_uniqsupno] DEFAULT ('') NOT NULL,
    [mrbType]            CHAR (1)        CONSTRAINT [DF_INVTMFGR_mrbType] DEFAULT ('') NOT NULL,
    [IsSynchronizedFlag] BIT             CONSTRAINT [DF__INVTMFGR__IsSync__5C5AD59A] DEFAULT ((0)) NULL,
    [isgroup]            BIT             CONSTRAINT [DF__INVTMFGR__isgrou__2A196E90] DEFAULT ((0)) NOT NULL,
    [IsLocal]            BIT             CONSTRAINT [DF__INVTMFGR__IsLoca__039634FA] DEFAULT ('0') NOT NULL,
    [SFBL]               BIT             CONSTRAINT [DF__INVTMFGR__SFBL__33A53ACF] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [INVTMFGR_PK] PRIMARY KEY CLUSTERED ([W_KEY] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [INVTMFGWH]
    ON [dbo].[INVTMFGR]([UNIQMFGRHD] ASC, [UNIQWH] ASC, [LOCATION] ASC, [INSTORE] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);


GO
CREATE NONCLUSTERED INDEX [rptInvtMfgrInstoreDeleteIndex]
    ON [dbo].[INVTMFGR]([INSTORE] ASC, [IS_DELETED] ASC)
    INCLUDE([UNIQ_KEY], [LOCATION], [UNIQMFGRHD], [UNIQWH], [uniqsupno]);


GO
CREATE NONCLUSTERED INDEX [IS_DELETED_Includes]
    ON [dbo].[INVTMFGR]([IS_DELETED] ASC)
    INCLUDE([UNIQ_KEY], [QTY_OH], [RESERVED], [NETABLE], [LOCATION], [W_KEY], [UNIQMFGRHD], [UNIQWH]);


GO
CREATE NONCLUSTERED INDEX [rptInvtmfgrIsDeleteIndex]
    ON [dbo].[INVTMFGR]([IS_DELETED] ASC)
    INCLUDE([UNIQ_KEY], [QTY_OH]);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[INVTMFGR]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_WKEY]
    ON [dbo].[INVTMFGR]([UNIQ_KEY] ASC, [W_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQMFGRHD]
    ON [dbo].[INVTMFGR]([UNIQMFGRHD] ASC);


GO
CREATE NONCLUSTERED INDEX [uniqsupno]
    ON [dbo].[INVTMFGR]([uniqsupno] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);


GO
CREATE NONCLUSTERED INDEX [uniqwhno]
    ON [dbo].[INVTMFGR]([UNIQWH] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);


GO
CREATE NONCLUSTERED INDEX [mrbtype]
    ON [dbo].[INVTMFGR]([mrbType] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/21/10
-- Description:	Delete trigger. Records are deleted in Manex from Invtmfgr table
--- only when record is deleted from Inventor table. Otherwise is_deleted is activated
--- in case record from Invtmfgr is erased, make sure to remove all records associated with this w_key from InvtLot table
-- =============================================
CREATE TRIGGER [dbo].[InvtMfgr_Update]
   ON  dbo.INVTMFGR
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	BEGIN TRANSACTION
	-- 12/09/10 modified trigger to check if location needs to be removed.
	DECLARE @zUpdated2Zero TABLE (nRecno int IDENTITY,W_key char(10),Qty_oh Numeric(12,2),UniqMfgrhd char(10),UniqWh char(10))
	DECLARE @lnCount as Int=0,@lnTotalRec as int=0,@lcUniqWh as char(10)=' ',@lcUniqMfgrhd as char(10)=' ',@lnQty_oh as Numeric(12,2)=0.00,@lcw_key char(10)=' ';
	-- check if any qty_oh reach zero
	-- 06/30/11 YS changed, so if user really needs to set is_deleted = 0 before update qty to > 0, the trigger can let the user change is_deleted
	--INSERT INTO  @zUpdated2Zero SELECT W_key,Qty_oh,UniqMfgrhd,UniqWh FROM INSERTED WHERE Qty_oh=0.00
	INSERT INTO @zUpdated2Zero 
			SELECT Inserted.W_key,Inserted.Qty_oh,Inserted.UniqMfgrhd,Inserted.Uniqwh 
			FROM Inserted,Deleted 
			WHERE Inserted.w_key=Deleted.w_key and Inserted.Qty_oh=0.00 and Deleted.Qty_oh<>0.00	
	
	IF @@ROWCOUNT<>0
	 --check if location can be removed
	BEGIN
		UPDATE InvtMfgr SET is_Deleted= 
					CASE WHEN dbo.fRemoveLocation(Z.UniqWh,Z.UniqMfgrHd)=1 THEN 1 
					ELSE InvtMfgr.Is_deleted END FROM @zUpdated2Zero Z WHERE z.W_key =Invtmfgr.w_key;
	END -- @@ROWCOUNT<>0 in @zUpdated2Zero
	
	-- check if no qty on hand
	-- if deleted more than one record from Invtmfgr, like when delete complete part number will trigger 
	-- delted from Invtmfgr where uniq_key=... this tirgger will generate an error.
	-- create table variable to keep all removed records
	
	-- 04/06/12 VL	Added @lcW_key to take the value returned from SQL, found a situation that cycle count issue around 5000 records
	--				and it hang.  Found if let the variable took the return value from a SQL solve the issue, also fixed in invt_isu_insert trigger	
	SELECT @lcW_key = W_key FROM INSERTED WHERE Qty_oh<>0.00 and IS_DELETED=1
	IF  @@ROWCOUNT<>0
	BEGIN	
		RAISERROR('System was trying to update deleted location with quantities other then zero. 
			Please contact ManEx with detailed information of the action prior to this message.',1,1)
		ROLLBACK TRANSACTION
		RETURN 
	END -- @@ROWCOUNT<>0
	
	COMMIT
END
GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/10/10
-- Description:	Delete trigger. Records are deleted in Manex from Invtmfgr table
--- only when record is deleted from Inventor table. Otherwise is_deleted is activated
--- in case record from Invtmfgr is erased, make sure to remove all records associated with this w_key from InvtLot table
--- Modified: 04/22/14 YS if no records to remove, remove an error just skip the code
-- =============================================
CREATE TRIGGER [dbo].[InvtMfgr_Delete]
   ON  dbo.INVTMFGR
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	BEGIN TRANSACTION
	-- check if no qty on hand
	-- if deleted more than one record from Invtmfgr, like when delete complete part number will trigger 
	-- delted from Invtmfgr where uniq_key=... this tirgger will generate an error.
	-- create table variable to keep all removed records
	DECLARE @zDeleted TABLE (nRecno int IDENTITY,W_key char(10),Qty_oh Numeric(12,2))
	DECLARE @lnCount as Int=0,@lnTotalRec as int=0
	INSERT INTO  @zDeleted SELECT W_key,Qty_oh FROM DELETED
	SET @lnTotalRec = @@ROWCOUNT
	 --- 04/22/14 YS if no records to remove, remove an error just skip the code
	IF @lnTotalRec<>0
	BEGIN	
	--	RAISERROR('Probelm during removing records from Invtmfgr table. 
	--		Please contact ManEx with detailed information of the action prior to this message.',1,1)
	--	ROLLBACK TRANSACTION
	--	RETURN
	--END	 --@@ROWCOUNT=0
		IF @lnTotalRec=1 -- only one record is removed
		BEGIN
			IF (SELECT Qty_oh FROM DELETED)<>0.00
			BEGIN	
			RAISERROR('System was trying to update deleted location with quantities other then zero. 
				Please contact ManEx with detailed information of the action prior to this message.',1,1)
			ROLLBACK TRANSACTION
			RETURN 
			END -- (SELECT IS_Deleted FROm INSERTED)<>(SELECT IS_Deleted ---
			DELETE FROM InvtLot WHERE W_KEY IN (SELECT W_key from Deleted)
		END -- @@ROWCOUNT=1
		IF @lnTotalRec>1 -- more than one record is removed
		BEGIN
			
			WHILE  @lnTotalRec<>0
			BEGIN
				SET @lnCount=@lnCount+1 
				IF (SELECT Qty_oh FROM @zDeleted where nRecno=@lnCount)<>0.00
				BEGIN	
					RAISERROR('System was trying to update deleted location with quantities other then zero. 
					Please contact ManEx with detailed information of the action prior to this message.',1,1)
					ROLLBACK TRANSACTION
					RETURN
					BREAK; 
				END -- (SELECT Qty_oh FROM @zDeleted where nRecno=@lnCount)<>0.00
				ELSE --(SELECT Qty_oh FROM @zDeleted where nRecno=@lnCount)<>0.00
					DELETE FROM InvtLot WHERE W_KEY IN (SELECT W_key FROM @zDeleted where nRecno=@lnCount)
				SET @lnTotalRec=@lnTotalRec-1	
			END -- WHILE  @lnTotalRec<>0		
		END --  @lnTotalRec>1
	END	 --@@ROWCOUNT<>0 in zdeleted	
	COMMIT
END