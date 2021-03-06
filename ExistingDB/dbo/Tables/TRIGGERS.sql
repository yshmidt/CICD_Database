﻿CREATE TABLE [dbo].[TRIGGERS] (
    [UNIQTRIG]          CHAR (10)     CONSTRAINT [DF__TRIGGERS__UNIQTR__709F6364] DEFAULT ('') NOT NULL,
    [SECTION]           CHAR (10)     CONSTRAINT [DF__TRIGGERS__SECTIO__7193879D] DEFAULT ('') NOT NULL,
    [TRNAME]            CHAR (25)     CONSTRAINT [DF__TRIGGERS__TRNAME__7287ABD6] DEFAULT ('') NOT NULL,
    [DESCRIPT]          CHAR (75)     CONSTRAINT [DF__TRIGGERS__DESCRI__737BD00F] DEFAULT ('') NOT NULL,
    [ISBATCH]           NUMERIC (1)   CONSTRAINT [DF__TRIGGERS__ISBATC__746FF448] DEFAULT ((0)) NOT NULL,
    [BATCHNBR]          NUMERIC (1)   CONSTRAINT [DF__TRIGGERS__BATCHN__75641881] DEFAULT ((0)) NOT NULL,
    [TRIGTYPE]          CHAR (10)     CONSTRAINT [DF__TRIGGERS__TRIGTY__76583CBA] DEFAULT ('') NOT NULL,
    [FREQUENCY]         CHAR (10)     CONSTRAINT [DF__TRIGGERS__FREQUE__774C60F3] DEFAULT ('') NOT NULL,
    [DAY]               NUMERIC (2)   CONSTRAINT [DF__TRIGGERS__DAY__7840852C] DEFAULT ((0)) NOT NULL,
    [TIME]              INT           CONSTRAINT [DF__TRIGGERS__TIME__7934A965] DEFAULT ((0)) NOT NULL,
    [TIME2]             INT           CONSTRAINT [DF__TRIGGERS__TIME2__7A28CD9E] DEFAULT ((0)) NOT NULL,
    [TIME3]             INT           CONSTRAINT [DF__TRIGGERS__TIME3__7B1CF1D7] DEFAULT ((0)) NOT NULL,
    [TIME4]             INT           CONSTRAINT [DF__TRIGGERS__TIME4__7C111610] DEFAULT ((0)) NOT NULL,
    [DATE]              SMALLDATETIME NULL,
    [FIELD1]            CHAR (15)     CONSTRAINT [DF__TRIGGERS__FIELD1__7D053A49] DEFAULT ('') NOT NULL,
    [TABLEREF1]         CHAR (30)     CONSTRAINT [DF__TRIGGERS__TABLER__7DF95E82] DEFAULT ('') NOT NULL,
    [OPR1]              CHAR (2)      CONSTRAINT [DF__TRIGGERS__OPR1__7EED82BB] DEFAULT ('') NOT NULL,
    [TXTOPR1]           CHAR (15)     CONSTRAINT [DF__TRIGGERS__TXTOPR__7FE1A6F4] DEFAULT ('') NOT NULL,
    [TXTVALUE1]         CHAR (25)     CONSTRAINT [DF__TRIGGERS__TXTVAL__00D5CB2D] DEFAULT ('') NOT NULL,
    [NUMVALUE1]         NUMERIC (6)   CONSTRAINT [DF__TRIGGERS__NUMVAL__01C9EF66] DEFAULT ((0)) NOT NULL,
    [UNIT1]             CHAR (6)      CONSTRAINT [DF__TRIGGERS__UNIT1__02BE139F] DEFAULT ('') NOT NULL,
    [FIELD2]            CHAR (15)     CONSTRAINT [DF__TRIGGERS__FIELD2__03B237D8] DEFAULT ('') NOT NULL,
    [TABLEREF2]         CHAR (30)     CONSTRAINT [DF__TRIGGERS__TABLER__04A65C11] DEFAULT ('') NOT NULL,
    [OPR2]              CHAR (2)      CONSTRAINT [DF__TRIGGERS__OPR2__059A804A] DEFAULT ('') NOT NULL,
    [TXTOPR2]           CHAR (15)     CONSTRAINT [DF__TRIGGERS__TXTOPR__068EA483] DEFAULT ('') NOT NULL,
    [TXTVALUE2]         CHAR (25)     CONSTRAINT [DF__TRIGGERS__TXTVAL__0782C8BC] DEFAULT ('') NOT NULL,
    [NUMVALUE2]         NUMERIC (6)   CONSTRAINT [DF__TRIGGERS__NUMVAL__0876ECF5] DEFAULT ((0)) NOT NULL,
    [UNIT2]             CHAR (6)      CONSTRAINT [DF__TRIGGERS__UNIT2__096B112E] DEFAULT ('') NOT NULL,
    [LASTTEST]          SMALLDATETIME NULL,
    [CLOSED]            BIT           CONSTRAINT [DF__TRIGGERS__CLOSED__0A5F3567] DEFAULT ((0)) NOT NULL,
    [USERDEF]           BIT           CONSTRAINT [DF__TRIGGERS__USERDE__0B5359A0] DEFAULT ((0)) NOT NULL,
    [SQLTEXT]           TEXT          CONSTRAINT [DF__TRIGGERS__SQLTEX__0C477DD9] DEFAULT ('') NOT NULL,
    [USERREF]           CHAR (30)     CONSTRAINT [DF__TRIGGERS__USERRE__0D3BA212] DEFAULT ('') NOT NULL,
    [LASTDATE]          SMALLDATETIME NULL,
    [TRIGSTATUS]        NUMERIC (1)   CONSTRAINT [DF__TRIGGERS__TRIGST__0E2FC64B] DEFAULT ((0)) NOT NULL,
    [DAYSOFWEEK]        CHAR (20)     CONSTRAINT [DF__TRIGGERS__DAYSOF__0F23EA84] DEFAULT ('') NOT NULL,
    [LINCLALLSQLFIELDS] BIT           CONSTRAINT [DF__TRIGGERS__LINCLA__10180EBD] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [TRIGGERS_PK] PRIMARY KEY CLUSTERED ([UNIQTRIG] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SECTION]
    ON [dbo].[TRIGGERS]([SECTION] ASC);


GO
CREATE NONCLUSTERED INDEX [TRNAME]
    ON [dbo].[TRIGGERS]([TRNAME] ASC);

