﻿CREATE TABLE [dbo].[PODOCK] (
    [PONUM]      CHAR (15)       CONSTRAINT [DF__PODOCK__PONUM__21A1C21B] DEFAULT ('') NOT NULL,
    [dDockDate]  SMALLDATETIME   NULL,
    [UNIQLNNO]   CHAR (10)       CONSTRAINT [DF__PODOCK__UNIQLNNO__238A0A8D] DEFAULT ('') NOT NULL,
    [PORECPKNO]  CHAR (15)       CONSTRAINT [DF__PODOCK__PORECPKNO] DEFAULT ('') NOT NULL,
    [COMPDATE]   SMALLDATETIME   NULL,
    [RECVBY]     CHAR (8)        CONSTRAINT [DF__PODOCK__RECVBY__257252FF] DEFAULT ('') NOT NULL,
    [COMPBY]     CHAR (8)        CONSTRAINT [DF__PODOCK__COMPBY__26667738] DEFAULT ('') NOT NULL,
    [QTY_REC]    NUMERIC (12, 2) CONSTRAINT [DF__PODOCK__QTY_REC__275A9B71] DEFAULT ((0)) NOT NULL,
    [RECEIVERNO] CHAR (10)       CONSTRAINT [DF__PODOCK__RECEIVER__284EBFAA] DEFAULT ('') NOT NULL,
    [DOCK_UNIQ]  CHAR (10)       CONSTRAINT [DF__PODOCK__DOCK_UNI__2942E3E3] DEFAULT ('') NOT NULL,
    CONSTRAINT [PODOCK_PK] PRIMARY KEY CLUSTERED ([DOCK_UNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [COMPDATE]
    ON [dbo].[PODOCK]([COMPDATE] ASC);


GO
CREATE NONCLUSTERED INDEX [PONUM]
    ON [dbo].[PODOCK]([PONUM] ASC);


GO
CREATE NONCLUSTERED INDEX [RECEIVERNO]
    ON [dbo].[PODOCK]([RECEIVERNO] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQLNNO]
    ON [dbo].[PODOCK]([UNIQLNNO] ASC);

