﻿CREATE TABLE [dbo].[UDFPROG] (
    [BUTTNCAPTO] CHAR (20) CONSTRAINT [DF__UDFPROG1__BUTTNC__2FE5BFD1] DEFAULT ('') NOT NULL,
    [BUTTNCAPTU] CHAR (20) CONSTRAINT [DF__UDFPROG1__BUTTNC__30D9E40A] DEFAULT ('') NOT NULL,
    [PROGNAME]   CHAR (50) CONSTRAINT [DF__UDFPROG1__PROGNA__31CE0843] DEFAULT ('') NOT NULL,
    [FORMNAME]   CHAR (20) CONSTRAINT [DF__UDFPROG1__FORMNA__32C22C7C] DEFAULT ('') NOT NULL,
    [UNIQUENUM]  INT       IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [UDFPROG_PK] PRIMARY KEY CLUSTERED ([UNIQUENUM] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FORMNAME]
    ON [dbo].[UDFPROG]([FORMNAME] ASC);

