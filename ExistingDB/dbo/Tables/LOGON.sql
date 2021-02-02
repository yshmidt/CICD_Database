﻿CREATE TABLE [dbo].[LOGON] (
    [UserId]    CHAR (8)      CONSTRAINT [DF_LOGON_SS_NBR] DEFAULT ('') NOT NULL,
    [NAME]      CHAR (20)     CONSTRAINT [DF_LOGON_NAME] DEFAULT ('') NOT NULL,
    [MODULEON]  CHAR (10)     CONSTRAINT [DF_LOGON_MODULEON] DEFAULT ('') NOT NULL,
    [DATE_ON]   SMALLDATETIME NULL,
    [DATE_OFF]  SMALLDATETIME NULL,
    [DESCR]     CHAR (30)     CONSTRAINT [DF_LOGON_DESC] DEFAULT ('') NOT NULL,
    [UNIQUENUM] CHAR (10)     NOT NULL,
    CONSTRAINT [PK_LOGON] PRIMARY KEY CLUSTERED ([UNIQUENUM] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BYUSER]
    ON [dbo].[LOGON]([UserId] ASC);

