﻿CREATE TABLE [dbo].[INSPEXCEPT] (
    [INSPEXCEPTION] CHAR (20) CONSTRAINT [DF__INSPEXCEP__INSPE__4D2051A6] DEFAULT ('') NOT NULL,
    [EXCEPTUNIQUE]  CHAR (10) CONSTRAINT [DF__INSPEXCEP__EXCEP__4E1475DF] DEFAULT ('') NOT NULL,
    CONSTRAINT [INSPEXCEPT_PK] PRIMARY KEY CLUSTERED ([EXCEPTUNIQUE] ASC)
);

