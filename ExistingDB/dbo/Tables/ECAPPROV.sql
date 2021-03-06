﻿CREATE TABLE [dbo].[ECAPPROV] (
    [UNIQECNO]  CHAR (10)     CONSTRAINT [DF__ECAPPROV__UNIQEC__2DF1BF10] DEFAULT ('') NOT NULL,
    [UNIQAPPNO] CHAR (10)     CONSTRAINT [DF__ECAPPROV__UNIQAP__2EE5E349] DEFAULT ('') NOT NULL,
    [DEPT]      CHAR (25)     CONSTRAINT [DF__ECAPPROV__DEPT__2FDA0782] DEFAULT ('') NOT NULL,
    [INIT]      CHAR (8)      CONSTRAINT [DF__ECAPPROV__INIT__30CE2BBB] DEFAULT ('') NULL,
    [DATE]      SMALLDATETIME NULL,
    [COMMENT]   TEXT          CONSTRAINT [DF__ECAPPROV__COMMEN__31C24FF4] DEFAULT ('') NOT NULL,
    CONSTRAINT [ECAPPROV_PK] PRIMARY KEY CLUSTERED ([UNIQAPPNO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQECNO]
    ON [dbo].[ECAPPROV]([UNIQECNO] ASC);

