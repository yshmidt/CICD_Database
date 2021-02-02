CREATE TABLE [dbo].[GlRjHdr] (
    [recref]          CHAR (10)     CONSTRAINT [DF_GlRjHdr_recref] DEFAULT ('') NOT NULL,
    [start_dt]        SMALLDATETIME NULL,
    [end_dt]          SMALLDATETIME NULL,
    [reason]          VARCHAR (200) CONSTRAINT [DF_GlRjHdr_reason] DEFAULT ('') NOT NULL,
    [recdescr]        CHAR (30)     CONSTRAINT [DF_GlRjHdr_recdescr] DEFAULT ('') NOT NULL,
    [lastgen_dt]      SMALLDATETIME NULL,
    [lastperiod]      NUMERIC (2)   CONSTRAINT [DF_GlRjHdr_lastperiod] DEFAULT ((0)) NOT NULL,
    [last_fy]         CHAR (4)      CONSTRAINT [DF_GlRjHdr_last_fy] DEFAULT ('') NOT NULL,
    [is_reverse]      BIT           CONSTRAINT [DF_GlRjHdr_is_reverse] DEFAULT ((0)) NOT NULL,
    [freq]            CHAR (12)     CONSTRAINT [DF_GlRjHdr_freq] DEFAULT ('') NOT NULL,
    [glrhdrkey]       CHAR (10)     CONSTRAINT [DF_GlRjHdr_glrhdrkey] DEFAULT ('') NOT NULL,
    [saveinit]        CHAR (8)      CONSTRAINT [DF_GlRjHdr_saveinit] DEFAULT ('') NOT NULL,
    [savedate]        SMALLDATETIME CONSTRAINT [DF_GlRjHdr_savedate] DEFAULT (getdate()) NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)     CONSTRAINT [DF__GlRjHdr__FCUSED___41C7A646] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)     CONSTRAINT [DF__GlRjHdr__FCHIST___42BBCA7F] DEFAULT ('') NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)     CONSTRAINT [DF__GlRjHdr__PRFCUSE__43AFEEB8] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)     CONSTRAINT [DF__GlRjHdr__FUNCFCU__44A412F1] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_GlRjHdr] PRIMARY KEY CLUSTERED ([glrhdrkey] ASC)
);


GO
CREATE NONCLUSTERED INDEX [End_dt]
    ON [dbo].[GlRjHdr]([recref] ASC);

