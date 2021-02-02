﻿CREATE TABLE [dbo].[PKINPGNM] (
    [TYPE]       CHAR (1)    CONSTRAINT [DF__PKINPGNM__TYPE__61F1515A] DEFAULT ('') NOT NULL,
    [PAGENO]     NUMERIC (1) CONSTRAINT [DF__PKINPGNM__PAGENO__62E57593] DEFAULT ((0)) NOT NULL,
    [PAGEDESC]   CHAR (25)   CONSTRAINT [DF__PKINPGNM__PAGEDE__63D999CC] DEFAULT ('') NOT NULL,
    [PKINPGNMUK] CHAR (10)   CONSTRAINT [DF__PKINPGNM__PKINPG__64CDBE05] DEFAULT ('') NOT NULL,
    CONSTRAINT [PKINPGNM_PK] PRIMARY KEY CLUSTERED ([PKINPGNMUK] ASC)
);


GO
CREATE NONCLUSTERED INDEX [TYPEPAGENO]
    ON [dbo].[PKINPGNM]([TYPE] ASC, [PAGENO] ASC);

