CREATE TABLE [dbo].[importPartClassTypeInfo] (
    [ImportTemplateId] UNIQUEIDENTIFIER NOT NULL,
    [FkImportId]       UNIQUEIDENTIFIER NOT NULL,
    [part_class]       NVARCHAR (MAX)   NOT NULL,
    [classDescription] NVARCHAR (MAX)   NOT NULL,
    [useIpkey]         BIT              NOT NULL,
    [classUnique]      NVARCHAR (MAX)   NOT NULL,
    [uniqwh]           NVARCHAR (MAX)   NOT NULL,
    [aspnetBuyer]      UNIQUEIDENTIFIER NULL,
    [AllowAutokit]     BIT              NOT NULL,
    [Status]           NVARCHAR (50)    NULL,
    [Message]          NVARCHAR (MAX)   NOT NULL,
    CONSTRAINT [PK__importPa__AEC13D2C9F190BEF] PRIMARY KEY CLUSTERED ([ImportTemplateId] ASC)
);

