CREATE TABLE [dbo].[iTransferSerial] (
    [ixferSerUnique]  CHAR (10) CONSTRAINT [DF_iTransferSerial_ixferSerUnique] DEFAULT ('') NOT NULL,
    [invtxfer_n]      CHAR (10) CONSTRAINT [DF_iTransferSerial_invtxfer_n] DEFAULT ('') NOT NULL,
    [serialno]        CHAR (30) CONSTRAINT [DF_iTransferSerial_serialno] DEFAULT ('') NOT NULL,
    [serialuniq]      CHAR (10) CONSTRAINT [DF_iTransferSerial_serialuniq] DEFAULT ('') NOT NULL,
    [fromipkeyunique] CHAR (10) CONSTRAINT [DF_iTransferSerial_ipkeyunique] DEFAULT ('') NOT NULL,
    [toipkeyunique]   CHAR (10) CONSTRAINT [DF_iTransferSerial_toipkeyunique] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ixferSerUnique] PRIMARY KEY CLUSTERED ([ixferSerUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [invtxfer_n]
    ON [dbo].[iTransferSerial]([invtxfer_n] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkey]
    ON [dbo].[iTransferSerial]([fromipkeyunique] ASC);


GO
CREATE NONCLUSTERED INDEX [serialno]
    ON [dbo].[iTransferSerial]([serialno] ASC);


GO
CREATE NONCLUSTERED INDEX [serialuniq]
    ON [dbo].[iTransferSerial]([serialuniq] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/08/2014
-- Description:	Inventory Transfer Serialize parts with or w/o IPkey
-- Modified : 
   -- 06/01/2018 Rajendra K : Added code to update UniqLot for transferred SerialNumber 
   -- 06/02/18 YS no need to link with invtmfgr table towkey is good enough and need to treat null in the expiration date
   --  If both dates are null null= null will return .f.
-- =============================================
CREATE TRIGGER [dbo].[iTransferSerial_Insert]
   ON [dbo].[iTransferSerial]
   AFTER INSERT
AS 
BEGIN
	-- find serial numbers and assign new location and new ip key if different
	---!!! we might include validation if serial number exists andf current w_key and ipkey matching the one in the transaction
	BEGIN TRANSACTION
	BEGIN TRY

	Update InvtSer SET ID_KEY='W_KEY', ID_VALUE=T.TOWKEY,
		ipkeyunique=case when p.useipkey=1 then i.toipkeyunique else ' ' end 
		FROM Inserted I inner join  InvtTRns T on I.invtxfer_n=T.INVTXFER_N
		INNER JOIN Inventor P on t.UNIQ_KEY=p.UNIQ_KEY
		where i.serialuniq=invtser.serialuniq
	
	-- 06/01/2018 Rajendra K : Update UniqLot for SerialNumber 
	-- 06/02/18 YS no need to link with invtmfgr table towkey is good enough
	UPDATE InvtSer SET UNIQ_LOT = IL.UNIQ_LOT 
		   FROM Inserted I INNER JOIN  InvtTRns T ON  I.invtxfer_n=T.INVTXFER_N  
		   --INNER JOIN InvtMfgr IM ON T.TOWKEY = IM.W_KEY AND T.UNIQ_KEY = IM.UNIQ_KEY
		   INNER JOIN INVTLOT IL ON t.TOWKEY = IL.W_KEY
		  WHERE I.serialuniq = Invtser.serialuniq 
		  AND  Invtser.LOTCODE = IL.LOTCODE 
		   ---06/02/18 YS have treat null value for the date different than just equal.  If both dates are null null= null will return .f.
		   -- try the following 
		   /*
		   declare @expdate smalldatetime = null,@expdate1 smalldatetime=null
		   select @expdate,@expdate1
			select case when @expdate=@expdate1 then 'equal' else 'not equal'end
		   */
		   AND ISNULL(Invtser.EXPDATE,1)=ISNULL(il.expdate,1) 
		   AND Invtser.PONUM = IL.PONUM 
		   AND Invtser.REFERENCE = IL.REFERENCE
	END TRY	
	BEGIN CATCH
		IF @@TRANCOUNT <>0
			ROLLBACK TRAN ;
			RETURN
	END CATCH
	IF @@TRANCOUNT <>0
	COMMIT TRANSACTION
END