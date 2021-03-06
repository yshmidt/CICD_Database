﻿CREATE TABLE [dbo].[FCSTDETLHIS] (
    [CFCSTUNIQKEY]   CHAR (10)     CONSTRAINT [DF__FCSTDETLH__CFCST__7AFC2AEF] DEFAULT ('') NOT NULL,
    [CDETLUK]        CHAR (10)     CONSTRAINT [DF__FCSTDETLH__CDETL__7BF04F28] DEFAULT ('') NOT NULL,
    [DFCSTWKEND]     SMALLDATETIME NULL,
    [NFCSTQTY]       NUMERIC (7)   CONSTRAINT [DF__FCSTDETLH__NFCST__7CE47361] DEFAULT ((0)) NOT NULL,
    [CFCSTPER]       CHAR (7)      CONSTRAINT [DF__FCSTDETLH__CFCST__7DD8979A] DEFAULT ('') NOT NULL,
    [NPLANQTY]       NUMERIC (7)   CONSTRAINT [DF__FCSTDETLH__NPLAN__7ECCBBD3] DEFAULT ((0)) NOT NULL,
    [CFCSTMAINHISUK] CHAR (10)     CONSTRAINT [DF__FCSTDETLH__CFCST__7FC0E00C] DEFAULT ('') NOT NULL,
    CONSTRAINT [FCSTDETLHIS_PK] PRIMARY KEY CLUSTERED ([CDETLUK] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FCSTUKEY]
    ON [dbo].[FCSTDETLHIS]([CFCSTUNIQKEY] ASC);

