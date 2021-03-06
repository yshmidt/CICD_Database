﻿CREATE TABLE [dbo].[KITDEF] (
    [ALLMFTR]               BIT       CONSTRAINT [DF__KITDEF__ALLMFTR__3EBD23B6] DEFAULT ((0)) NOT NULL,
    [LKITIGNORESCRAP]       BIT       CONSTRAINT [DF__KITDEF__LKITIGNO__3FB147EF] DEFAULT ((0)) NOT NULL,
    [LCOSTROLLIGNORESCRAP]  BIT       CONSTRAINT [DF__KITDEF__LCOSTROL__40A56C28] DEFAULT ((0)) NOT NULL,
    [LKITALLOWNONNETTABLE]  BIT       CONSTRAINT [DF__KITDEF__LKITALLO__41999061] DEFAULT ((0)) NOT NULL,
    [Lsuppressnotusedinkit] BIT       CONSTRAINT [DF_KITDEF_Lsuppressnotusedinkit] DEFAULT ((0)) NOT NULL,
    [UNIQUEREC]             CHAR (10) CONSTRAINT [DF__KITDEF__UNIQUERE__428DB49A] DEFAULT ('') NOT NULL,
    CONSTRAINT [KITDEF_PK] PRIMARY KEY CLUSTERED ([UNIQUEREC] ASC)
);

