CREATE TABLE [dbo].[WFHeader] (
    [WFid]         CHAR (10)        NOT NULL,
    [CreatedBy]    UNIQUEIDENTIFIER NOT NULL,
    [CreationDate] SMALLDATETIME    NULL,
    [ModuleId]     INT              NOT NULL,
    [RemindValue]  NUMERIC (10, 2)  NULL,
    [RemindUnit]   CHAR (10)        NULL,
    CONSTRAINT [PK_WFHeader] PRIMARY KEY CLUSTERED ([WFid] ASC)
);

