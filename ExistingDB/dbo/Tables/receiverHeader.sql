CREATE TABLE [dbo].[receiverHeader] (
    [receiverno]       CHAR (10)        CONSTRAINT [DF_receiverHeader_receiverno] DEFAULT ('') NOT NULL,
    [recPklNo]         VARCHAR (50)     CONSTRAINT [DF_receiverHeader_recPklNo] DEFAULT ('') NOT NULL,
    [dockDate]         SMALLDATETIME    NULL,
    [senderType]       CHAR (1)         CONSTRAINT [DF_receiverHeader_senderType] DEFAULT ('') NOT NULL,
    [senderId]         VARCHAR (10)     CONSTRAINT [DF_receiverHeader_senderId] DEFAULT ('') NOT NULL,
    [recStatus]        VARCHAR (20)     CONSTRAINT [DF_receiverHeader_recStatus] DEFAULT ('') NOT NULL,
    [recvBy]           UNIQUEIDENTIFIER NULL,
    [completeBy]       UNIQUEIDENTIFIER NULL,
    [completeDate]     SMALLDATETIME    NULL,
    [carrier]          NVARCHAR (15)    CONSTRAINT [DF_receiverHeader_carrier] DEFAULT ('') NOT NULL,
    [waybill]          NVARCHAR (50)    CONSTRAINT [DF_receiverHeader_waybill] DEFAULT ('') NOT NULL,
    [receiverHdrId]    CHAR (10)        CONSTRAINT [DF_receiverHeader_receiverHdrId] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [ponum]            NCHAR (15)       CONSTRAINT [DF_receiverHeader_ponum] DEFAULT ('') NOT NULL,
    [inspectionSource] CHAR (1)         CONSTRAINT [DF_receiverHeader_inspectionSource] DEFAULT ('P') NOT NULL,
    [reason]           NVARCHAR (60)    NULL,
    CONSTRAINT [PK_receiverHeader] PRIMARY KEY CLUSTERED ([receiverHdrId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_receiverno]
    ON [dbo].[receiverHeader]([receiverno] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_recplno]
    ON [dbo].[receiverHeader]([recPklNo] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_receiversendert]
    ON [dbo].[receiverHeader]([senderType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_receiversendi]
    ON [dbo].[receiverHeader]([senderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_receiverHeaderPO]
    ON [dbo].[receiverHeader]([ponum] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_receiverHeaderSource]
    ON [dbo].[receiverHeader]([inspectionSource] ASC);

