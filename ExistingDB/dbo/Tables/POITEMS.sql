CREATE TABLE [dbo].[POITEMS] (
    [PONUM]         CHAR (15)       CONSTRAINT [DF__POITEMS__PONUM__2C1F508E] DEFAULT ('') NOT NULL,
    [UNIQLNNO]      CHAR (10)       CONSTRAINT [DF__POITEMS__UNIQLNN__2D1374C7] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]      CHAR (10)       CONSTRAINT [DF__POITEMS__UNIQ_KE__2E079900] DEFAULT ('') NOT NULL,
    [ITEMNO]        CHAR (3)        CONSTRAINT [DF__POITEMS__ITEMNO__2EFBBD39] DEFAULT ('') NOT NULL,
    [COSTEACH]      NUMERIC (15, 7) CONSTRAINT [DF__POITEMS__COSTEAC__2FEFE172] DEFAULT ((0)) NOT NULL,
    [ORD_QTY]       NUMERIC (10, 2) CONSTRAINT [DF__POITEMS__ORD_QTY__30E405AB] DEFAULT ((0)) NOT NULL,
    [RECV_QTY]      NUMERIC (10, 2) CONSTRAINT [DF__POITEMS__RECV_QT__31D829E4] DEFAULT ((0)) NOT NULL,
    [REJ_QTY]       NUMERIC (10, 2) CONSTRAINT [DF__POITEMS__REJ_QTY__32CC4E1D] DEFAULT ((0)) NOT NULL,
    [ACPT_QTY]      NUMERIC (10, 2) CONSTRAINT [DF__POITEMS__ACPT_QT__33C07256] DEFAULT ((0)) NOT NULL,
    [NOTE1]         TEXT            CONSTRAINT [DF__POITEMS__NOTE1__34B4968F] DEFAULT ('') NOT NULL,
    [IS_TAX]        BIT             CONSTRAINT [DF__POITEMS__IS_TAX__35A8BAC8] DEFAULT ((0)) NOT NULL,
    [TAX_PCT]       NUMERIC (8, 4)  CONSTRAINT [DF__POITEMS__TAX_PCT__369CDF01] DEFAULT ((0)) NOT NULL,
    [IS_CONTR]      BIT             CONSTRAINT [DF__POITEMS__IS_CONT__3791033A] DEFAULT ((0)) NOT NULL,
    [OVERAGE]       NUMERIC (5, 2)  CONSTRAINT [DF__POITEMS__OVERAGE__38852773] DEFAULT ((0)) NOT NULL,
    [POITTYPE]      CHAR (9)        CONSTRAINT [DF__POITEMS__POITTYP__39794BAC] DEFAULT ('') NOT NULL,
    [L_PRINT]       BIT             CONSTRAINT [DF__POITEMS__L_PRINT__3A6D6FE5] DEFAULT ((0)) NOT NULL,
    [NO_PKG]        NUMERIC (9, 2)  CONSTRAINT [DF__POITEMS__NO_PKG__3B61941E] DEFAULT ((0)) NOT NULL,
    [PART_NO]       NVARCHAR (35)   CONSTRAINT [DF__POITEMS__PART_NO__3C55B857] DEFAULT ('') NOT NULL,
    [REVISION]      NVARCHAR (8)    CONSTRAINT [DF__POITEMS__REVISIO__3D49DC90] DEFAULT ('') NOT NULL,
    [DESCRIPT]      CHAR (45)       CONSTRAINT [DF__POITEMS__DESCRIP__3E3E00C9] DEFAULT ('') NOT NULL,
    [PARTMFGR]      CHAR (8)        CONSTRAINT [DF__POITEMS__PARTMFG__3F322502] DEFAULT ('') NOT NULL,
    [MFGR_PT_NO]    CHAR (30)       CONSTRAINT [DF__POITEMS__MFGR_PT__4026493B] DEFAULT ('') NOT NULL,
    [PACKAGE]       CHAR (15)       CONSTRAINT [DF__POITEMS__PACKAGE__411A6D74] DEFAULT ('') NOT NULL,
    [PART_CLASS]    CHAR (8)        CONSTRAINT [DF__POITEMS__PART_CL__420E91AD] DEFAULT ('') NOT NULL,
    [PART_TYPE]     CHAR (8)        CONSTRAINT [DF__POITEMS__PART_TY__4302B5E6] DEFAULT ('') NOT NULL,
    [U_OF_MEAS]     CHAR (4)        CONSTRAINT [DF__POITEMS__U_OF_ME__43F6DA1F] DEFAULT ('') NOT NULL,
    [PUR_UOFM]      CHAR (4)        CONSTRAINT [DF__POITEMS__PUR_UOF__44EAFE58] DEFAULT ('') NOT NULL,
    [S_ORD_QTY]     NUMERIC (10, 2) CONSTRAINT [DF__POITEMS__S_ORD_Q__45DF2291] DEFAULT ((0)) NOT NULL,
    [ISFIRM]        BIT             CONSTRAINT [DF__POITEMS__ISFIRM__46D346CA] DEFAULT ((0)) NOT NULL,
    [UNIQMFGRHD]    CHAR (10)       CONSTRAINT [DF__POITEMS__UNIQMFG__47C76B03] DEFAULT ('') NOT NULL,
    [FIRSTARTICLE]  BIT             CONSTRAINT [DF__POITEMS__FIRSTAR__48BB8F3C] DEFAULT ((0)) NOT NULL,
    [INSPEXCEPT]    BIT             CONSTRAINT [DF__POITEMS__INSPEXC__49AFB375] DEFAULT ((0)) NOT NULL,
    [INSPEXCEPTION] CHAR (20)       CONSTRAINT [DF__POITEMS__INSPEXC__4AA3D7AE] DEFAULT ('') NOT NULL,
    [INSPEXCINIT]   CHAR (8)        CONSTRAINT [DF__POITEMS__INSPEXC__4B97FBE7] DEFAULT ('') NOT NULL,
    [INSPEXCDT]     SMALLDATETIME   NULL,
    [INSPEXCNOTE]   TEXT            CONSTRAINT [DF__POITEMS__INSPEXC__4C8C2020] DEFAULT ('') NOT NULL,
    [INSPEXCDOC]    CHAR (200)      CONSTRAINT [DF__POITEMS__INSPEXC__4D804459] DEFAULT ('') NOT NULL,
    [LCANCEL]       BIT             CONSTRAINT [DF__POITEMS__LCANCEL__4E746892] DEFAULT ((0)) NOT NULL,
    [UNIQMFSP]      CHAR (10)       CONSTRAINT [DF__POITEMS__UNIQMFS__4F688CCB] DEFAULT ('') NOT NULL,
    [INSPECTIONOTE] TEXT            CONSTRAINT [DF__POITEMS__INSPECT__505CB104] DEFAULT ('') NOT NULL,
    [lRemvRcv]      BIT             CONSTRAINT [DF_POITEMS_lRemvRcv] DEFAULT ((0)) NOT NULL,
    [costEachFC]    NUMERIC (15, 7) CONSTRAINT [DF_POITEMS_costEachFC] DEFAULT ((0.00)) NOT NULL,
    [costEachPR]    NUMERIC (15, 7) CONSTRAINT [DF_POITEMS_costEachPR] DEFAULT ((0.00)) NOT NULL,
    [inLastMrp]     BIT             CONSTRAINT [DF_POITEMS_inLastMrp] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [POITEMS_PK] PRIMARY KEY CLUSTERED ([UNIQLNNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ITEMNO]
    ON [dbo].[POITEMS]([ITEMNO] ASC);


GO
CREATE NONCLUSTERED INDEX [MROPART]
    ON [dbo].[POITEMS]([PART_NO] ASC, [REVISION] ASC);


GO
CREATE NONCLUSTERED INDEX [POITEM]
    ON [dbo].[POITEMS]([PONUM] ASC, [ITEMNO] ASC);


GO
CREATE NONCLUSTERED INDEX [PONUM]
    ON [dbo].[POITEMS]([PONUM] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[POITEMS]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQMFGRHD]
    ON [dbo].[POITEMS]([UNIQMFGRHD] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQMFSP]
    ON [dbo].[POITEMS]([UNIQMFSP] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: <09/10/10>
-- Description:	<trigger for poitems>
-- 10/02/14 cannot assign to a single variable when bulk update
-- use exists when checking for records instead of select and @@rowcount 
-- =============================================
CREATE TRIGGER [dbo].[PoItems_Insert_Update_Delete]
   ON  [dbo].[POITEMS]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- 10/02/14 cannot assign to a single variable . use if exists
	--DECLARE @lcPonum as char(15)
    BEGIN TRANSACTION
    -- check if deleted records exists
   -- SELECT @lcPonum=Ponum from Deleted
   IF EXISTS (select 1 from deleted)
   -- IF @@ROWCOUNT<>0
	BEGIN	
       -- check if inserted exists
		--10/02/14 YS use if exists . when updating many records sql hangs
		--SELECT Ponum FROM Inserted
		if not exists (select 1 from inserted) 
		--IF @@ROWCOUNT=0
		BEGIN	-- @@ROWCOUNT=0
			--deleted only
			-- check if item is service item
			-- check if receipt for service items was reconciled
			--10/02/14 use if exists
			--SELECT Porecdtl.Receiverno,Porecloc.Loc_uniq 
			--	FROM Porecloc,Porecdtl 
			--WHERE Porecloc.Fk_UniqRecDtl=Porecdtl.UniqRecDtl
			--AND Porecloc.Sinv_uniq<>' '
			--AND Porecdtl.UniqLnno IN (SELECT UniqLnno FROM DELETED WHERE Deleted.lRemvRcv=1 and Deleted.PoitType='Services')  
			--IF @@ROWCOUNT <>0
			if exists (SELECT 1
				FROM Porecloc,Porecdtl ,deleted
			WHERE Porecloc.Fk_UniqRecDtl=Porecdtl.UniqRecDtl
			AND Porecloc.Sinv_uniq<>' '
			AND Porecdtl.UniqLnno=Deleted.uniqlnno 
			and Deleted.lRemvRcv=1 and Deleted.PoitType='Services' ) 
			BEGIN
				RAISERROR('You are trying to remove Service type item, which was reconciled. Aborting Save transaction.',1,1)
				ROLLBACK TRANSACTION
				RETURN
			END	--	@@ROWCOUNT <>0 in porecdtl,porecloc reconciled
			-- record was not reconciled
			--10/02/14 YS  check if exists first
			if exists (select 1 from deleted where Deleted.PoitType='Services' and Deleted.lRemvRcv=1)
				DELETE FROM PoRecdtl WHERE Porecdtl.UniqLnno IN (SELECT UniqLnNo FROM Deleted WHERE Deleted.PoitType='Services' and Deleted.lRemvRcv=1)   
			--update lRemvRcv with 0
			UPDATE Poitems SET lRemvRcv=0 where UniqLnno IN (SELECT UniqLnNo FROM Deleted )
			
		END	-- if not exists (select 1 from inserted)  Inserted. Deleted only
		ELSE ----if not exists (select 1 from inserted) 
		BEGIN 
			-- updated record
			-- check for reconciled service items
			-- 10/02/14 YS check if exists instead of select and @@rowcount
			--SELECT Porecdtl.Receiverno,Porecloc.Loc_uniq 
			--		FROM Porecloc,Porecdtl 
			--	WHERE Porecloc.Fk_UniqRecDtl=Porecdtl.UniqRecDtl
			--	AND Porecloc.Sinv_uniq<>' '
			--	AND Porecdtl.UniqLnno IN (SELECT UniqLnno FROM INSERTED WHERE Inserted.lRemvRcv=1 and Inserted.PoitType='Services')   
			--IF @@ROWCOUNT <>0
			if exists (SELECT 1
				FROM Porecloc,Porecdtl ,inserted
			WHERE Porecloc.Fk_UniqRecDtl=Porecdtl.UniqRecDtl
			AND Porecloc.Sinv_uniq<>' '
			AND Porecdtl.UniqLnno=inserted.uniqlnno 
			and inserted.lRemvRcv=1 and inserted.PoitType='Services' ) 
			BEGIN
				RAISERROR('You are trying to remove Service type item, which was reconciled. Aborting Save transaction.',1,1)
				ROLLBACK TRANSACTION
				RETURN
			END	--	@@ROWCOUNT <>0 in porecdtl,porecloc reconciled
			
			
			-- delete from porecdtl if "Service" Item and lRemvRcv=1
			--10/02/14 YS  check if exists first
			if exists (select 1 from Inserted where Inserted.PoitType='Services' and Inserted.lRemvRcv=1)
				DELETE FROM PoRecdtl WHERE Porecdtl.UniqLnno IN (SELECT UniqLnNo FROM Inserted WHERE Inserted.lRemvRcv=1 and Inserted.PoitType='Services')   
			--update lRemvRcv with 0
			UPDATE Poitems SET lRemvRcv=0 where UniqLnno IN (SELECT UniqLnNo FROM Inserted )
		END ----ELSE @@ROWCOUNT=0 in Inserted. Deleted only
		
	END --  @@ROWCOUNT<>0 in deleted
	--ELSE --  @@ROWCOUNT<>0 in deleted
	--BEGIN	
	--	-- no deleted
	--	-- check for inserted
	--	SELECT Ponum FROM Inserted
	--	IF @@ROWCOUNT=0 -- Inserted only
	--	BEGIN
		
	--	END --  @@ROWCOUNT=0 -- Inserted only
			
	--END --  else @@ROWCOUNT<>0 in deleted
		
	
	
	COMMIT

END