﻿CREATE TABLE [dbo].[TRIGMESSAGES] (
    [UNIQTRIG] CHAR (10) CONSTRAINT [DF__TRIGMESSA__UNIQT__12F47B68] DEFAULT ('') NOT NULL,
    [UNIQ_MSG] CHAR (10) CONSTRAINT [DF__TRIGMESSA__UNIQ___13E89FA1] DEFAULT ('') NOT NULL,
    [MSGNAME]  CHAR (25) CONSTRAINT [DF__TRIGMESSA__MSGNA__14DCC3DA] DEFAULT ('') NOT NULL,
    [MSG]      TEXT      CONSTRAINT [DF__TRIGMESSAGE__MSG__15D0E813] DEFAULT ('') NOT NULL,
    CONSTRAINT [TRIGMESSAGES_PK] PRIMARY KEY CLUSTERED ([UNIQ_MSG] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQTRIG]
    ON [dbo].[TRIGMESSAGES]([UNIQTRIG] ASC);

