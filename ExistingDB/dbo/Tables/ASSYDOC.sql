﻿CREATE TABLE [dbo].[ASSYDOC] (
    [UNIQ_KEY] CHAR (10)     CONSTRAINT [DF__ASSYDOC__UNIQ_KE__1EF99443] DEFAULT ('') NOT NULL,
    [DOCREVNO] CHAR (4)      CONSTRAINT [DF__ASSYDOC__DOCREVN__1FEDB87C] DEFAULT ('') NOT NULL,
    [DOCNO]    CHAR (25)     CONSTRAINT [DF__ASSYDOC__DOCNO__20E1DCB5] DEFAULT ('') NOT NULL,
    [DOCDESCR] CHAR (45)     CONSTRAINT [DF__ASSYDOC__DOCDESC__21D600EE] DEFAULT ('') NOT NULL,
    [DOCDATE]  SMALLDATETIME NULL,
    [DOCNOTE]  TEXT          CONSTRAINT [DF__ASSYDOC__DOCNOTE__22CA2527] DEFAULT ('') NOT NULL,
    [DOC_UNIQ] CHAR (10)     CONSTRAINT [DF__ASSYDOC__DOC_UNI__23BE4960] DEFAULT ('') NOT NULL,
    [DOCEXEC]  CHAR (200)    CONSTRAINT [DF__ASSYDOC__DOCEXEC__24B26D99] DEFAULT ('') NOT NULL,
    [DOCPDF]   CHAR (200)    CONSTRAINT [DF__ASSYDOC__DOCPDF__25A691D2] DEFAULT ('') NOT NULL,
    CONSTRAINT [ASSYDOC_PK] PRIMARY KEY CLUSTERED ([DOC_UNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[ASSYDOC]([UNIQ_KEY] ASC);

