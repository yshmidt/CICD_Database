﻿CREATE TABLE [dbo].[PORECMRBSerial] (
    [mrbSerialnoUnique] CHAR (10) CONSTRAINT [DF__PORECMRBSerial_mrbSerialnoUnique] DEFAULT ('') NOT NULL,
    [DMRUNIQUE]         CHAR (10) CONSTRAINT [DF__PORECMRBSerial_DMRUNIQUE] DEFAULT ('') NOT NULL,
    [POSERUNIQUE]       CHAR (10) CONSTRAINT [DF__PORECMRBSerial_POSERUNIQUE] DEFAULT ('') NOT NULL,
    [SERIALUNIQ]        CHAR (10) CONSTRAINT [DF__PORECMRBSerial_SERIALUNIQ] DEFAULT ('') NOT NULL,
    [ipkeyUnique]       CHAR (10) CONSTRAINT [DF__PORECMRBSerial_ipkeyUnique] DEFAULT ('') NOT NULL,
    CONSTRAINT [PORECMRBSerial_PK] PRIMARY KEY CLUSTERED ([mrbSerialnoUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [dmrunique]
    ON [dbo].[PORECMRBSerial]([DMRUNIQUE] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkey]
    ON [dbo].[PORECMRBSerial]([ipkeyUnique] ASC);


GO
CREATE NONCLUSTERED INDEX [poserunique]
    ON [dbo].[PORECMRBSerial]([POSERUNIQUE] ASC);


GO
CREATE NONCLUSTERED INDEX [serialuniq]
    ON [dbo].[PORECMRBSerial]([SERIALUNIQ] ASC);

