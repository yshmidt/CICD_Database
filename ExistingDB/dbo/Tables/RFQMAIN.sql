﻿CREATE TABLE [dbo].[RFQMAIN] (
    [RFQUNIQ]    CHAR (10)     CONSTRAINT [DF__RFQMAIN__RFQUNIQ__3746EA77] DEFAULT ('') NOT NULL,
    [RFQNO]      CHAR (10)     CONSTRAINT [DF__RFQMAIN__RFQNO__383B0EB0] DEFAULT ('') NOT NULL,
    [SUPID]      CHAR (10)     CONSTRAINT [DF__RFQMAIN__SUPID__392F32E9] DEFAULT ('') NOT NULL,
    [CONTACT]    CHAR (20)     CONSTRAINT [DF__RFQMAIN__CONTACT__3A235722] DEFAULT ('') NOT NULL,
    [DUEDATE]    SMALLDATETIME NULL,
    [RFQNOTE]    TEXT          CONSTRAINT [DF__RFQMAIN__RFQNOTE__3B177B5B] DEFAULT ('') NOT NULL,
    [RFQSTATUS]  CHAR (10)     CONSTRAINT [DF__RFQMAIN__RFQSTAT__3C0B9F94] DEFAULT ('') NOT NULL,
    [DATEISSUED] SMALLDATETIME NULL,
    [UPDATEDT]   SMALLDATETIME NULL,
    CONSTRAINT [RFQMAIN_PK] PRIMARY KEY CLUSTERED ([RFQUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SUPID]
    ON [dbo].[RFQMAIN]([SUPID] ASC);

