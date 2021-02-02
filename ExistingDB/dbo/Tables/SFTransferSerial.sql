CREATE TABLE [dbo].[SFTransferSerial] (
    [sfTransSerUnique] CHAR (10) CONSTRAINT [DF_SFTransferSerial_sfTransSerUnique] DEFAULT ('') NOT NULL,
    [SerialUniq]       CHAR (10) CONSTRAINT [DF_SFTransferSerial_SerialUniq] DEFAULT ('') NOT NULL,
    [xfer_uniq]        CHAR (10) CONSTRAINT [DF_SFTransferSerial_xfer_uniq] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_SFTransferSerial] PRIMARY KEY CLUSTERED ([sfTransSerUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [serialuniq]
    ON [dbo].[SFTransferSerial]([SerialUniq] ASC);


GO
CREATE NONCLUSTERED INDEX [xfer_uniq]
    ON [dbo].[SFTransferSerial]([xfer_uniq] ASC);

