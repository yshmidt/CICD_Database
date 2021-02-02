CREATE TABLE [dbo].[iReserveSerial] (
    [iResSerUnique] CHAR (10) CONSTRAINT [DF_iReserveSerial_iResSerUnique] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [invtres_no]    CHAR (10) CONSTRAINT [DF_iReserveSerial_invtres_no] DEFAULT ('') NOT NULL,
    [serialuniq]    CHAR (10) CONSTRAINT [DF_iReserveSerial_SerialUniq] DEFAULT ('') NOT NULL,
    [ipkeyunique]   CHAR (10) CONSTRAINT [DF_iReserveSerial_ipkeyunique] DEFAULT ('') NOT NULL,
    [kaseqnum]      CHAR (10) CONSTRAINT [DF_iReserveSerial_kaseqnum] DEFAULT ('') NOT NULL,
    [isDeallocate]  BIT       CONSTRAINT [DF_iReserveSerial_isDeallocate] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [iReserveSerial_PK] PRIMARY KEY CLUSTERED ([iResSerUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [invtres_no]
    ON [dbo].[iReserveSerial]([invtres_no] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkey]
    ON [dbo].[iReserveSerial]([ipkeyunique] ASC);


GO
CREATE NONCLUSTERED INDEX [serialuniq]
    ON [dbo].[iReserveSerial]([serialuniq] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_iReserveSerialKit]
    ON [dbo].[iReserveSerial]([kaseqnum] ASC);


GO

-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/08/16
-- Description:	Insert trigger for serial numbers reserved
-- 12/12/16 Sachin b if useIpkey need to insert a record into iReserveIpKey
-- 06/12/17 Rajendra K - insert record into iReserveIpKey only if Ipkeyuniq is available
-- =============================================
CREATE TRIGGER [dbo].[ireserveSerial_insert]
   ON [dbo].[iReserveSerial]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    -- Insert statements for trigger here
	-- update ipkey table and if any qtyOver populate qtyAllocatedOver in the ipkey table
	-- Insert statements for trigger here
	BEGIN TRY
		BEGIN TRANSACTION
		IF NOT EXISTS (select 1 from  InvtSer S inner join Inserted I on  s.SERIALUNIQ = i.serialuniq)
			BEGIN
				RAISERROR ('Cannot Locate any Records in InvtSer Table to allocate .', -- Message text.
				   16, -- Severity.
					1 -- State.
				);

			END
			
						
			;with
			updateser
			as
			( 
			select serialuniq,r.KaSeqnum,r.wono,r.FK_PRJUNIQUE,r.sono,r.UNIQUELN,r.QTYALLOC  from inserted i inner join invt_res R on i.invtres_no=r.INVTRES_NO
			inner join inventor p on r.UNIQ_KEY=p.UNIQ_KEY where p.serialyes=1
			)
			UPDATE InvtSer SET isReserved=case when updateser.QTYALLOC>0 THEN 1 else 0 end ,
								ReservedFlag=CASE WHEN updateser.qtyalloc>0 and updateser.KaSeqnum<>' ' THEN 'KaSeqnum'
												WHEN updateser.qtyalloc>0 and updateser.wono<>' ' THEN 'WONO'
												WHEN updateser.qtyalloc>0 and updateser.Fk_PrjUnique<>' ' THEN 'PRJUNIQUE' 
												WHEN updateser.qtyalloc>0 and updateser.Sono<>'' THEN 'SONO' 
												ELSE ' ' END,
								RESERVEDNO = CASE WHEN updateser.qtyalloc>0 and updateser.KaSeqnum<>' ' THEN updateser.KaSeqnum
												WHEN updateser.qtyalloc>0 and updateser.wono<>' ' THEN updateser.WONO
												WHEN updateser.qtyalloc>0 and updateser.Fk_PrjUnique<>' ' THEN updateser.FK_PRJUNIQUE 
												WHEN updateser.qtyalloc>0 and updateser.Sono<>'' THEN updateser.SONO 
												ELSE ' ' END
			FROM updateser where updateser.serialuniq=Invtser.SERIALUNIQ;

			--IF NOT EXISTS(SELECT  1 FROM Inserted WHERE ipkeyunique = '' OR ipkeyunique = NULL)
			IF EXISTS(select 1 from Inserted i Inner join Invt_res r on I.invtres_no=r.INVTRES_NO inner join inventor m on r.uniq_key=m.uniq_key
				where M.UseIpkey=1 and i.ipkeyunique IS NOT NULL and i.ipkeyunique <>'')  --06/12/17 : Rajendra k - Insert record into iReserveIpKey only if Ipkeyuniq is available
			BEGIN
				-- 12/12/16 Sachin b if useIpkey need to insert a record into iReserveIpKey
			  INSERT INTO  [dbo].[iReserveIpKey]
				([iResIpKeyUnique]
				,[invtres_no]
				,[qtyAllocated]
				,[ipkeyunique]
				,[kaseqnum]
				 ) 
				SELECT dbo.fn_GenerateUniqueNumber() as [iResIpKeyUnique],
						i.INVTRES_NO,
						case when r.QTYALLOC>=0
						THEN COUNT(I.serialuniq) 
						ELSE
						-COUNT(I.serialuniq) END as [qtyAllocated],
						I.ipkeyunique,
						i.kaseqnum
				FROM Inserted I 
				INNER JOIN Invt_res r on I.invtres_no=r.INVTRES_NO
				GROUP BY I.invtres_no,I.ipkeyunique,r.QTYALLOC,i.kaseqnum	
			END

  END TRY
  BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK
			SELECT @ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE();
			RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );

  END CATCH
  IF @@TRANCOUNT>0
		COMMIT	
END
