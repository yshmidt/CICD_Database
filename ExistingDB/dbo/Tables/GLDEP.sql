﻿CREATE TABLE [dbo].[GLDEP] (
    [UNIQDEP]   CHAR (10) CONSTRAINT [DF__GLDEP__UNIQDEP__5378497A] DEFAULT ('') NOT NULL,
    [GLDIVNO]   CHAR (2)  CONSTRAINT [DF__GLDEP__GLDIVNO__546C6DB3] DEFAULT ('') NOT NULL,
    [GLDEPNO]   CHAR (2)  CONSTRAINT [DF__GLDEP__GLDEPNO__556091EC] DEFAULT ('') NOT NULL,
    [GLDEPNAME] CHAR (25) CONSTRAINT [DF__GLDEP__GLDEPNAME__5654B625] DEFAULT ('') NOT NULL,
    CONSTRAINT [GLDEP_PK] PRIMARY KEY CLUSTERED ([UNIQDEP] ASC)
);


GO
CREATE NONCLUSTERED INDEX [DIVDEP]
    ON [dbo].[GLDEP]([GLDIVNO] ASC, [GLDEPNO] ASC);

