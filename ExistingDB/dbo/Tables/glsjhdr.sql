CREATE TABLE [dbo].[glsjhdr] (
    [stdref]          CHAR (10)     CONSTRAINT [DF_glsjhdr_stdref] DEFAULT ('') NOT NULL,
    [reason]          VARCHAR (MAX) CONSTRAINT [DF_glsjhdr_reason] DEFAULT ('') NOT NULL,
    [stddescr]        CHAR (30)     CONSTRAINT [DF_glsjhdr_stddescr] DEFAULT ('') NOT NULL,
    [sjtype]          CHAR (10)     CONSTRAINT [DF_glsjhdr_sjtype] DEFAULT ('') NOT NULL,
    [last_post]       NUMERIC (2)   CONSTRAINT [DF_glsjhdr_last_post] DEFAULT ((0)) NOT NULL,
    [post_fy]         CHAR (4)      CONSTRAINT [DF_glsjhdr_post_fy] DEFAULT ('') NOT NULL,
    [glstndhkey]      CHAR (10)     CONSTRAINT [DF_glsjhdr_glstndhkey] DEFAULT ('') NOT NULL,
    [saveinit]        CHAR (8)      CONSTRAINT [DF_glsjhdr_saveinit] DEFAULT ('') NOT NULL,
    [savedate]        SMALLDATETIME CONSTRAINT [DF_glsjhdr_savedate] DEFAULT (getdate()) NOT NULL,
    [FCUSED_UNIQ]     CHAR (10)     CONSTRAINT [DF__glsjhdr__FCUSED___4968C80E] DEFAULT ('') NOT NULL,
    [FCHIST_KEY]      CHAR (10)     CONSTRAINT [DF__glsjhdr__FCHIST___4A5CEC47] DEFAULT ('') NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)     CONSTRAINT [DF__glsjhdr__PRFCUSE__4B511080] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)     CONSTRAINT [DF__glsjhdr__FUNCFCU__4C4534B9] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_glsjhdr] PRIMARY KEY CLUSTERED ([glstndhkey] ASC)
);

