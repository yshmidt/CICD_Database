﻿CREATE TABLE [dbo].[APPMTS] (
    [SUPINFO]    CHAR (20)       CONSTRAINT [DF__APPMTS__SUPINFO__41B8C09B] DEFAULT ('') NOT NULL,
    [INVNO]      CHAR (10)       CONSTRAINT [DF__APPMTS__INVNO__42ACE4D4] DEFAULT ('') NOT NULL,
    [PONUM]      CHAR (15)       CONSTRAINT [DF__APPMTS__PONUM__43A1090D] DEFAULT ('') NOT NULL,
    [PMT_DATE]   SMALLDATETIME   NULL,
    [PMT_TYPE]   CHAR (13)       CONSTRAINT [DF__APPMTS__PMT_TYPE__44952D46] DEFAULT ('') NOT NULL,
    [PMT_ADVICE] CHAR (10)       CONSTRAINT [DF__APPMTS__PMT_ADVI__4589517F] DEFAULT ('') NOT NULL,
    [PMT_AMOUNT] NUMERIC (12, 2) CONSTRAINT [DF__APPMTS__PMT_AMOU__467D75B8] DEFAULT ((0)) NOT NULL,
    [DISC_TAKEN] NUMERIC (12, 2) CONSTRAINT [DF__APPMTS__DISC_TAK__477199F1] DEFAULT ((0)) NOT NULL,
    [GL_NBR]     CHAR (13)       CONSTRAINT [DF__APPMTS__GL_NBR__4865BE2A] DEFAULT ('') NOT NULL,
    [PMT_NOTE]   TEXT            CONSTRAINT [DF__APPMTS__PMT_NOTE__4959E263] DEFAULT ('') NOT NULL,
    [IS_REL_GL]  BIT             CONSTRAINT [DF__APPMTS__IS_REL_G__4A4E069C] DEFAULT ((0)) NOT NULL,
    [APPMTSUNIQ] CHAR (10)       CONSTRAINT [DF__APPMTS__APPMTSUN__4B422AD5] DEFAULT ('') NOT NULL,
    CONSTRAINT [APPMTS_PK] PRIMARY KEY CLUSTERED ([APPMTSUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PMT_DATE]
    ON [dbo].[APPMTS]([PMT_DATE] ASC);

