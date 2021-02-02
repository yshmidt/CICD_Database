﻿CREATE TABLE [dbo].[TRIGDETL] (
    [UNIQEMAIL]  CHAR (10) CONSTRAINT [DF__TRIGDETL__UNIQEM__6AE68A0E] DEFAULT ('') NOT NULL,
    [UNIQTRIGDT] CHAR (10) CONSTRAINT [DF__TRIGDETL__UNIQTR__6BDAAE47] DEFAULT ('') NOT NULL,
    [UNIQTRIG]   CHAR (10) CONSTRAINT [DF__TRIGDETL__UNIQTR__6CCED280] DEFAULT ('') NOT NULL,
    [UNIQ_MSG]   CHAR (10) CONSTRAINT [DF__TRIGDETL__UNIQ_M__6DC2F6B9] DEFAULT ('') NOT NULL,
    CONSTRAINT [TRIGDETL_PK] PRIMARY KEY CLUSTERED ([UNIQTRIGDT] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQEMAIL]
    ON [dbo].[TRIGDETL]([UNIQEMAIL] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQTRIG]
    ON [dbo].[TRIGDETL]([UNIQTRIG] ASC);
