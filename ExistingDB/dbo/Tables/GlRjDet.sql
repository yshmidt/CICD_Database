﻿CREATE TABLE [dbo].[GlRjDet] (
    [gl_nbr]    CHAR (13)       CONSTRAINT [DF_GlRjDet_gl_nbr] DEFAULT ('') NOT NULL,
    [debit]     NUMERIC (14, 2) CONSTRAINT [DF_GlRjDet_debit] DEFAULT ((0.00)) NOT NULL,
    [credit]    NUMERIC (14, 2) CONSTRAINT [DF_GlRjDet_credit] DEFAULT ((0.00)) NOT NULL,
    [fkglrhdr]  CHAR (10)       CONSTRAINT [DF_Table_1_fkglhdr] DEFAULT ('') NOT NULL,
    [glrdetkey] CHAR (10)       CONSTRAINT [DF_GlRjDet_glrdetkey] DEFAULT ('') NOT NULL,
    [DEBITFC]   NUMERIC (14, 2) CONSTRAINT [DF__GlRjDet__DEBITFC__4598372A] DEFAULT ((0)) NOT NULL,
    [CREDITFC]  NUMERIC (14, 2) CONSTRAINT [DF__GlRjDet__CREDITF__468C5B63] DEFAULT ((0)) NOT NULL,
    [DEBITPR]   NUMERIC (14, 2) CONSTRAINT [DF__GlRjDet__DEBITPR__47807F9C] DEFAULT ((0)) NOT NULL,
    [CREDITPR]  NUMERIC (14, 2) CONSTRAINT [DF__GlRjDet__CREDITP__4874A3D5] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_GlRjDet] PRIMARY KEY CLUSTERED ([glrdetkey] ASC),
    CONSTRAINT [FK_GlRjDet_GlRjHd] FOREIGN KEY ([fkglrhdr]) REFERENCES [dbo].[GlRjHdr] ([glrhdrkey]) ON DELETE CASCADE
);

