﻿CREATE TABLE [dbo].[PRICSREP] (
    [CID]        CHAR (10)      CONSTRAINT [DF__PRICSREP__CID__49459F21] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]   CHAR (10)      CONSTRAINT [DF__PRICSREP__UNIQ_K__4A39C35A] DEFAULT ('') NOT NULL,
    [CUSTNO]     CHAR (10)      CONSTRAINT [DF__PRICSREP__CUSTNO__4B2DE793] DEFAULT ('') NOT NULL,
    [COMMISSION] NUMERIC (9, 4) CONSTRAINT [DF__PRICSREP__COMMIS__4C220BCC] DEFAULT ((0)) NOT NULL,
    [pricsrepuk] CHAR (10)      CONSTRAINT [DF_PRICSREP_pricsrep] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_PRICSREP] PRIMARY KEY CLUSTERED ([pricsrepuk] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQSREP]
    ON [dbo].[PRICSREP]([CID] ASC, [UNIQ_KEY] ASC, [CUSTNO] ASC);

