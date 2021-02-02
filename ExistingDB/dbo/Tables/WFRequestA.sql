CREATE TABLE [dbo].[WFRequestA] (
    [WFRequestAId] CHAR (10)        NOT NULL,
    [WFRequestId]  CHAR (10)        NOT NULL,
    [ModuleId]     INT              NOT NULL,
    [RequestDate]  SMALLDATETIME    NOT NULL,
    [RequestorId]  UNIQUEIDENTIFIER NOT NULL,
    [WFComplete]   BIT              NOT NULL,
    [RecordId]     VARCHAR (MAX)    NOT NULL,
    CONSTRAINT [PK_WFRequestA] PRIMARY KEY CLUSTERED ([WFRequestAId] ASC)
);

