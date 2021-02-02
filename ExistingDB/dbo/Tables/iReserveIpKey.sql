CREATE TABLE [dbo].[iReserveIpKey] (
    [iResIpKeyUnique] CHAR (10)       CONSTRAINT [DF_iReserveIpKey_iResIpKeyUnique] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [invtres_no]      CHAR (10)       CONSTRAINT [DF_iReserveIpKey_invtres_no] DEFAULT ('') NOT NULL,
    [qtyAllocated]    NUMERIC (12, 2) CONSTRAINT [DF_iReserveIpKey_qtyAlloc] DEFAULT ((0)) NOT NULL,
    [qtyOver]         NUMERIC (12, 2) CONSTRAINT [DF_iReserveIpKey_qtyOver] DEFAULT ((0.00)) NOT NULL,
    [ipkeyunique]     CHAR (10)       CONSTRAINT [DF_iReserveIpKey_ipkeyunique] DEFAULT ('') NOT NULL,
    [KaSeqnum]        CHAR (10)       CONSTRAINT [DF_iReserveIpKey_UNIQKALOCIPKEY] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_iReserveIpKey] PRIMARY KEY CLUSTERED ([iResIpKeyUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [invtres_no]
    ON [dbo].[iReserveIpKey]([invtres_no] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkey]
    ON [dbo].[iReserveIpKey]([ipkeyunique] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_iReserveKit]
    ON [dbo].[iReserveIpKey]([KaSeqnum] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/03/2016
-- Description:	Insert trigger for iReserveIpKey
-- =============================================
CREATE TRIGGER [dbo].[iReserveIpKey_insert]
   ON  [dbo].[iReserveIpKey]
   AFTER  INSERT
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
			IF NOT EXISTS (select 1 from  Ipkey P inner join Inserted I on  i.ipkeyunique = p.ipkeyunique)
			BEGIN
				RAISERROR ('Cannot Locate any Records in IpKey Table for given SIDs to Allocate.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);

			END
			
			IF EXISTS (select i.ipkeyunique,p.pkgBalance,I.qtyAllocated from Inserted I inner join Ipkey P on  i.ipkeyunique = p.ipkeyunique 
				where (I.qtyAllocated >0 and p.pkgBalance<I.qtyAllocated or I.qtyAllocated<0 and p.qtyAllocatedTotal<abs(I.qtyAllocated) ))
			BEGIN
				RAISERROR ('Cannot allocate/de-allocate more than the balance in the package or allocated.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);

			END
			update ipkey set  qtyAllocatedTotal=qtyAllocatedTotal+i.qtyAllocated, qtyAllocatedOver=QtyAllocatedOver+i.qtyOver from inserted I where ipkey.ipkeyunique = i.ipkeyunique
			-- check if negative qty after the update
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