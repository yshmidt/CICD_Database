CREATE TABLE [dbo].[mnxFileCabinet] (
    [FileId]       BIGINT           IDENTITY (1, 1) NOT NULL,
    [FileName]     VARCHAR (200)    CONSTRAINT [DF_mnxFileCabinet_FileName] DEFAULT ('') NOT NULL,
    [Path]         VARCHAR (MAX)    CONSTRAINT [DF_mnxFileCabinet_Path] DEFAULT ('') NOT NULL,
    [FileType]     INT              CONSTRAINT [DF_mnxFileCabinet_FileType] DEFAULT ((5)) NOT NULL,
    [UploadDate]   SMALLDATETIME    NULL,
    [UploadBy]     UNIQUEIDENTIFIER NULL,
    [Tags]         VARCHAR (MAX)    CONSTRAINT [DF_mnxFileCabinet_Tags] DEFAULT ('') NOT NULL,
    [InternalOnly] BIT              CONSTRAINT [DF_mnxFileCabinet_InternalOnly] DEFAULT ((0)) NOT NULL,
    [IsDeleted]    BIT              CONSTRAINT [DF_mnxFileCabinet_IsDeleted] DEFAULT ((0)) NOT NULL,
    [moduleid]     INT              CONSTRAINT [DF_mnxFileCabinet_moduleid] DEFAULT ((0)) NOT NULL,
    [sequence]     INT              CONSTRAINT [DF_mnxFileCabinet_sequence] DEFAULT ((0)) NOT NULL,
    [DeleteDate]   SMALLDATETIME    NULL,
    CONSTRAINT [PK_mnxFileCabinet] PRIMARY KEY CLUSTERED ([FileId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Filetype]
    ON [dbo].[mnxFileCabinet]([FileType] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_mdouleid]
    ON [dbo].[mnxFileCabinet]([moduleid] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_sequence]
    ON [dbo].[mnxFileCabinet]([sequence] ASC);

