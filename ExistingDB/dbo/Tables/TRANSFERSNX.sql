﻿CREATE TABLE [dbo].[TRANSFERSNX] (
    [FK_XFR_UNIQ]   CHAR (10) DEFAULT ('') NOT NULL,
    [FK_SERIALUNIQ] CHAR (10) DEFAULT ('') NOT NULL,
    [SFXFRSNUNIQ]   CHAR (10) DEFAULT ('') NOT NULL,
    CONSTRAINT [TRANSFERSNX_PK] PRIMARY KEY CLUSTERED ([SFXFRSNUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SERIALUNIQ]
    ON [dbo].[TRANSFERSNX]([FK_SERIALUNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [XFR_UNIQ]
    ON [dbo].[TRANSFERSNX]([FK_XFR_UNIQ] ASC);

