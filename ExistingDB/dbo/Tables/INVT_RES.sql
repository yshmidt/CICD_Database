CREATE TABLE [dbo].[INVT_RES] (
    [W_KEY]           CHAR (10)        CONSTRAINT [DF__INVT_RES__W_KEY__0D5AD24C] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]        CHAR (10)        CONSTRAINT [DF__INVT_RES__UNIQ_K__0E4EF685] DEFAULT ('') NOT NULL,
    [DATETIME]        SMALLDATETIME    CONSTRAINT [DF_INVT_RES_DATETIME] DEFAULT (getdate()) NULL,
    [QTYALLOC]        NUMERIC (12, 2)  CONSTRAINT [DF__INVT_RES__QTYALL__0F431ABE] DEFAULT ((0)) NOT NULL,
    [WONO]            CHAR (10)        CONSTRAINT [DF__INVT_RES__WONO__10373EF7] DEFAULT ('') NOT NULL,
    [INVTRES_NO]      CHAR (10)        CONSTRAINT [DF__INVT_RES__INVTRE__112B6330] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [SONO]            CHAR (10)        CONSTRAINT [DF__INVT_RES__SONO__121F8769] DEFAULT ('') NOT NULL,
    [UNIQUELN]        CHAR (10)        CONSTRAINT [DF__INVT_RES__UNIQUE__1313ABA2] DEFAULT ('') NOT NULL,
    [LOTCODE]         NVARCHAR (25)    CONSTRAINT [DF__INVT_RES__LOTCOD__1407CFDB] DEFAULT ('') NOT NULL,
    [EXPDATE]         SMALLDATETIME    NULL,
    [REFERENCE]       CHAR (12)        CONSTRAINT [DF__INVT_RES__REFERE__14FBF414] DEFAULT ('') NOT NULL,
    [PONUM]           CHAR (15)        CONSTRAINT [DF__INVT_RES__PONUM__15F0184D] DEFAULT ('') NOT NULL,
    [SAVEINIT]        CHAR (8)         CONSTRAINT [DF__INVT_RES__SAVEIN__16E43C86] DEFAULT ('') NOT NULL,
    [REFINVTRES]      CHAR (10)        CONSTRAINT [DF__INVT_RES__REFINV__17D860BF] DEFAULT ('') NOT NULL,
    [FK_PRJUNIQUE]    CHAR (10)        CONSTRAINT [DF__INVT_RES__FK_PRJ__18CC84F8] DEFAULT ('') NOT NULL,
    [KaSeqnum]        CHAR (10)        CONSTRAINT [DF_INVT_RES_UNIQKALOCATE] DEFAULT ('') NOT NULL,
    [fk_userid]       UNIQUEIDENTIFIER NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)        CONSTRAINT [DF__INVT_RES__FUNCFC__17E67B13] DEFAULT ('') NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)        CONSTRAINT [DF__INVT_RES__PRFCUS__18DA9F4C] DEFAULT ('') NOT NULL,
    CONSTRAINT [INVT_RES_PK] PRIMARY KEY CLUSTERED ([INVTRES_NO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [REFINVTRES]
    ON [dbo].[INVT_RES]([REFINVTRES] ASC);


GO
CREATE NONCLUSTERED INDEX [SONO_ULWK]
    ON [dbo].[INVT_RES]([SONO] ASC, [UNIQUELN] ASC, [W_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [W_KEY]
    ON [dbo].[INVT_RES]([W_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [WKEYSOLOT]
    ON [dbo].[INVT_RES]([W_KEY] ASC, [UNIQUELN] ASC, [LOTCODE] ASC, [EXPDATE] ASC, [REFERENCE] ASC, [PONUM] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_INVT_RES]
    ON [dbo].[INVT_RES]([KaSeqnum] ASC);


GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <12/22/2010>
-- Description:	<After Insert Trigger for Invt_res >
-- Modified:
-- 08/29/14 VL found has to add 'RETURN' after 'ROLLBACK TRANSACTION' otherwise will get 'The transaction ended in the trigger.  The batch has been aborted. error
--10/09/14 YS remove invtmfhd table and replace with 2 new tables
-- 03/03/16 YS remove serialno from invt_res table
-- 03/09/16 YS added code to update kamain table where kaseqnum is provided
-- 07/19/16 Nitesh B added code to ROLLBACK transaction if any error occur
-- 01/25/17 VL added code to update functional and presentation currency key
-- 06/12/2017 Sachin B update kamain table SHORTQTY,allocatedQty for each inserted record in invt_res
-- 06/12/2017 Sachin B update InvtMfgr table RESERVED for each inserted record in invt_res
-- 07/31/17 Sachin B  update invtlot table LOTRESQTY for each inserted record in invt_res
--03/02/18 YS changed lotcode size to 25
-- 07/13/20 VL comment out the code that update sodetail.qtyfrominv field.  We don't reserve for sales order anymore
-- =============================================
CREATE TRIGGER [dbo].[Invt_res_insert] 
   ON  [dbo].[INVT_RES]
   AFTER  INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ErrorMessage NVARCHAR(4000),@ErrorSeverity INT,@ErrorState INT;

	
	/* validate
		1. check if any w_key are missing from invtmfgr table
		
	*/
	BEGIN TRY
	BEGIN TRANSACTION
	SELECT 1 from Invtmfgr inner join Inserted on invtmfgr.w_key=inserted.w_key  
					and invtmfgr.UNIQ_KEY=inserted.UNIQ_KEY
		IF NOT EXISTS (SELECT 1 from Invtmfgr inner join Inserted on invtmfgr.w_key=inserted.w_key  
					and invtmfgr.UNIQ_KEY=inserted.UNIQ_KEY)
		BEGIN
				RAISERROR ('Cannot w_key and uniq_key are not matching when searching Invtmfgr Table. This operation will be cancelled. Please report to manex and try again.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);
				-- 07/19/16 Nitesh B added code to ROLLBACK transaction if any error occur
				ROLLBACK transaction
				return

		END -- IF NOT EXISTS (select 1 from invtmfgr....
		-- check if enough qty to reserved
		IF EXISTS (select 1 from Invtmfgr inner join Inserted I on invtmfgr.w_key=i.w_key where Invtmfgr.qty_oh-invtmfgr.RESERVED-I.QTYALLOC <0)
		BEGIN
				RAISERROR ('No quantities available to reserve', -- Message text.
				   16, -- Severity.
					1 -- State.
				);
				-- 07/19/16 Nitesh B added code to ROLLBACK transaction if any error occur
				ROLLBACK transaction
				return

		END -- -- check if enough qty to reserved
	

		--UPDATE InvtMfgr SET RESERVED=RESERVED+i.QTYALLOC,Invtmfgr.is_deleted=0 from inserted I where i.W_KEY=invtmfgr.w_key
		-- 06/12/2017 Sachin B update InvtMfgr table RESERVED for each inserted record in invt_res		
		Update mf set mf.RESERVED = mf.RESERVED + i.QTYALLOC,mf.is_deleted=0
		from InvtMfgr mf
		JOIN (SELECT sum(QTYALLOC) QTYALLOC,W_KEY FROM inserted I GROUP BY W_KEY) i
		ON mf.W_KEY = i.W_KEY

		-- make sure that mpn is not deleted
		UPDATE InvtMPNLink SET Is_Deleted = 0 WHERE exists (select 1 from inserted I inner join Invtmfgr M on i.w_key=m.w_key where m.UniqMfgrHd = InvtMPNLink.UniqMfgrhd)
		
			-- 01/26/12 VL added to insert into UpdMatTpLog
		;with
		matltypeupdate
		as
		( 
		select mfgrmaster.MatlType,mfgrmaster.MfgrMasterId,l.uniq_key from MfgrMaster inner join InvtMPNLink L on mfgrmaster.MfgrMasterId=l.MfgrMasterId
		inner join  Invtmfgr M on l.uniqmfgrhd=m.UNIQMFGRHD 
		inner join	Inserted I on M.w_key=I.w_key	
		where not exists (select 1 from AVLMATLTP where AVLMATLTYPE= MfgrMaster.MatlType)		
		)			
		INSERT INTO UpdMatTpLog (UqMttpLog, Uniq_key, FromMatlType, ToMatlType, MtChgDt, MtChgInit) 
				select dbo.fn_GenerateUniqueNumber(), matltypeupdate.uniq_key, matltypeupdate.MatlType, 'Unk', GETDATE(), 'SYS' from matltypeupdate
		
		
		-- make sure material type is updated if required
		UPDATE MfgrMaster SET MatlType='Unk' 
		FROM InvtMPNLink L inner join Invtmfgr M on l.uniqmfgrhd=m.UNIQMFGRHD 
		inner join Inserted I on M.w_key=I.w_key
		WHERE L.MfgrMasterId= MfgrMaster.MfgrMasterId 
		AND not exists (select 1 from AVLMATLTP where AVLMATLTYPE= MfgrMaster.MatlType)

	
	   -- check if lotcode required for any parts and update the corresponding records in the InvtLot table
	   --03/02/18 YS changed lotcode size to 25
	   declare @tlot table (uniq_key char(10),w_key char(10),lotcode nvarchar(25),expdate smalldatetime null ,ponum char(15),reference char(12),qtyAlloc numeric(12,2))
	   insert into @tlot (uniq_key ,w_key,lotcode,expdate ,ponum ,reference ,qtyAlloc)
				 SELECT I.Uniq_key,I.w_key,I.lotcode,I.expdate,i.ponum,i.reference,i.qtyalloc
					from inserted I inner join Inventor P on i.UNIQ_KEY=P.UNIQ_KEY 
					inner join parttype t on p.PART_CLASS=t.part_class and p.PART_TYPE=t.PART_TYPE and LOTDETAIL=1

	   IF @@ROWCOUNT <> 0
	   BEGIN
		-- check if the lotcode information is missing
		if exists (select 1 from @tlot where lotcode=' ')
		BEGIN
	   		RAISERROR ('Missing LotCode information. This operation will be cancelled. Please report to manex and try again.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);
				-- 07/19/16 Nitesh B added code to ROLLBACK transaction if any error occur
				ROLLBACK transaction
				return
		 end -- check for the lotdetail=1
		-- check if lotcode records are not in the invtlot table
		IF not exists (select 1 from invtlot 
					inner join @tlot t on invtlot.W_KEY=t.w_key 
					and invtlot.LOTCODE=t.lotcode 
					and isnull(INVTLOT.EXPDATE,1)=isnull(t.expdate,1) 
					and invtlot.ponum=t.ponum 
					and invtlot.REFERENCE=t.reference
					WHERE invtlot.LOTQTY-invtlot.LOTRESQTY-t.qtyAlloc>=0 )
			BEGIN 
				RAISERROR ('Cannot locate record in the InvtLot table or not enough quantities to allocate. This operation will be cancelled. Please report to manex and try again.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);
				-- 07/19/16 Nitesh B added code to ROLLBACK transaction if any error occur
				ROLLBACK transaction
				return
			END 
		-- if all is ok update invtlot tabel
		-- 07/31/17 Sachin B  update invtlot table LOTRESQTY for each inserted record in invt_res
		UPDATE c
		SET c.LOTRESQTY= c.LOTRESQTY+t.qtyAlloc
		FROM invtlot c
		JOIN (SELECT sum(qtyAlloc) qtyAlloc,w_key,LOTCODE,EXPDATE,ponum,REFERENCE FROM @tlot I GROUP BY w_key,LOTCODE,EXPDATE,ponum,REFERENCE) t
		ON c.w_key = t.w_key and c.LOTCODE =t.lotcode and isnull(c.EXPDATE,1)=isnull(t.expdate,1) and c.ponum =t.ponum and c.REFERENCE =t.reference

	 END ---IF @@ROWCOUNT <> 0
	
	-- 07/13/20 VL comment out the code that update sodetail.qtyfrominv field.  We don't reserve for sales order anymore
	--UPDATE Sodetail set QtyFromInv=CASE WHEN QTYFROMINV + I.QTYALLOC  >= 0 THEN QTYFROMINV + I.QTYALLOC  ELSE 0 END FROM Inserted I where I.UNIQUELN<>'' and I.UNIQUELN=Sodetail.UNIQUELN
	
	--03/09/16 update kamain table
	--update Kamain set SHORTQTY=ShortQty-i.QTYALLOC, allocatedQty=allocatedQty+i.QTYALLOC  from inserted I where i.KaSeqnum<>' ' and i.kaseqnum=kamain.kaseqnum
	
	--06/12/2017 Sachin B update kamain table SHORTQTY,allocatedQty for each inserted record in invt_res	    
	Update k set k.SHORTQTY = k.SHORTQTY - i.QTYALLOC,k.allocatedQty = k.allocatedQty+i.QTYALLOC
	from KAMAIN k
	JOIN (SELECT sum(QTYALLOC) QTYALLOC,kaseqnum FROM inserted I GROUP BY KASEQNUM) i
	ON k.KASEQNUM = i.KASEQNUM

	-- {01/25/17 VL added to update functional and presentation currency key
	IF dbo.fn_IsFCInstalled() = 1
		BEGIN
		UPDATE Invt_res SET PRFCUSED_UNIQ = dbo.fn_GetPresentationCurrency(),
							FUNCFCUSED_UNIQ = dbo.fn_GetFunctionalCurrency()
				FROM inserted
				WHERE inserted.INVTRES_NO = Invt_res.INVTRES_NO
	END
	-- 01/25/17 VL End}

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
			   -- 07/19/16 Nitesh B added code to ROLLBACK transaction if any error occur
			   ROLLBACK transaction

	END CATCH	
	IF @@TRANCOUNT>0
		COMMIT
				
END