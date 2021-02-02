CREATE TABLE [dbo].[BOMChangeLog] (
    [UNIQBOMNOLogId] INT              IDENTITY (1, 1) NOT NULL,
    [UNIQBOMNO]      CHAR (10)        NULL,
    [ITEM_NO]        NUMERIC (4)      NULL,
    [BOMPARENT]      CHAR (10)        NULL,
    [UNIQ_KEY]       CHAR (10)        NULL,
    [DEPT_ID]        CHAR (4)         NULL,
    [QTY]            NUMERIC (9)      NULL,
    [ITEM_NOTE]      VARCHAR (MAX)    NULL,
    [OFFSET]         NUMERIC (4)      NULL,
    [TERM_DT]        SMALLDATETIME    NULL,
    [EFF_DT]         SMALLDATETIME    NULL,
    [USED_INKIT]     CHAR (1)         NULL,
    [ModifiedBy]     UNIQUEIDENTIFIER NULL,
    [ModifiedOn]     DATETIME         NULL,
    [ChangeInfo]     VARCHAR (MAX)    CONSTRAINT [DF__BOMChange__Chang__238E0340] DEFAULT (NULL) NULL,
    CONSTRAINT [PK__BOMChang__B3217C6C5FCA59B9] PRIMARY KEY CLUSTERED ([UNIQBOMNOLogId] ASC)
);

