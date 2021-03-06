﻿CREATE TABLE [dbo].[FCSTMAINHIS] (
    [CFCSTUNIQKEY]   CHAR (10)      CONSTRAINT [DF__FCSTMAINH__CFCST__27CED166] DEFAULT ('') NOT NULL,
    [CUNIQ_KEY]      CHAR (10)      CONSTRAINT [DF__FCSTMAINH__CUNIQ__28C2F59F] DEFAULT ('') NOT NULL,
    [CPRIORFCSTKEY]  CHAR (10)      CONSTRAINT [DF__FCSTMAINH__CPRIO__29B719D8] DEFAULT ('') NOT NULL,
    [CCUSTNO]        CHAR (10)      CONSTRAINT [DF__FCSTMAINH__CCUST__2AAB3E11] DEFAULT ('') NOT NULL,
    [LACTIVE]        BIT            CONSTRAINT [DF__FCSTMAINH__LACTI__2B9F624A] DEFAULT ((0)) NOT NULL,
    [LDELETED]       BIT            CONSTRAINT [DF__FCSTMAINH__LDELE__2C938683] DEFAULT ((0)) NOT NULL,
    [cREASON]        CHAR (10)      CONSTRAINT [DF_FCSTMAINHIS_MREASON] DEFAULT ('') NOT NULL,
    [DFCSTDT]        SMALLDATETIME  NULL,
    [CUSERINIT]      CHAR (8)       CONSTRAINT [DF__FCSTMAINH__CUSER__2E7BCEF5] DEFAULT ('') NULL,
    [DENTRYDT]       SMALLDATETIME  NULL,
    [CAPPVID]        CHAR (4)       CONSTRAINT [DF__FCSTMAINH__CAPPV__2F6FF32E] DEFAULT ('') NOT NULL,
    [DAPPVD]         SMALLDATETIME  NULL,
    [NPRICE]         NUMERIC (9, 2) CONSTRAINT [DF__FCSTMAINH__NPRIC__30641767] DEFAULT ((0)) NOT NULL,
    [CCOPYFROM]      CHAR (10)      CONSTRAINT [DF__FCSTMAINH__CCOPY__31583BA0] DEFAULT ('') NOT NULL,
    [CFCSTMAINHISUK] CHAR (10)      CONSTRAINT [DF__FCSTMAINH__CFCST__324C5FD9] DEFAULT ('') NOT NULL,
    [TMRPLASTDT]     SMALLDATETIME  NULL,
    [CW_KEY]         CHAR (10)      CONSTRAINT [DF__FCSTMAINH__CW_KE__33408412] DEFAULT ('') NOT NULL,
    [UNIQMFGRHD]     CHAR (10)      CONSTRAINT [DF_FCSTMAINHIS_UNIQMFGRHD] DEFAULT ('') NOT NULL,
    CONSTRAINT [FCSTMAINHIS_PK] PRIMARY KEY CLUSTERED ([CFCSTMAINHISUK] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ACTIVE]
    ON [dbo].[FCSTMAINHIS]([LACTIVE] ASC);


GO
CREATE NONCLUSTERED INDEX [CUSTNO]
    ON [dbo].[FCSTMAINHIS]([CCUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [FCSTUKEY]
    ON [dbo].[FCSTMAINHIS]([CFCSTUNIQKEY] ASC);


GO
CREATE NONCLUSTERED INDEX [PFCSTUKEY]
    ON [dbo].[FCSTMAINHIS]([CPRIORFCSTKEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UKEY]
    ON [dbo].[FCSTMAINHIS]([CUNIQ_KEY] ASC);

