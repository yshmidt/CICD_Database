﻿CREATE TABLE [dbo].[INVTHDEF] (
    [UNIQ_FIELD] CHAR (10) CONSTRAINT [DF__INVTHDEF__UNIQ_F__0623C4D8] DEFAULT ('') NOT NULL,
    [TYPE]       CHAR (1)  CONSTRAINT [DF__INVTHDEF__TYPE__0717E911] DEFAULT ('') NOT NULL,
    [REASON]     CHAR (25) CONSTRAINT [DF__INVTHDEF__REASON__080C0D4A] DEFAULT ('') NOT NULL,
    CONSTRAINT [INVTHDEF_PK] PRIMARY KEY CLUSTERED ([UNIQ_FIELD] ASC)
);


GO
CREATE NONCLUSTERED INDEX [REASON]
    ON [dbo].[INVTHDEF]([REASON] ASC);
