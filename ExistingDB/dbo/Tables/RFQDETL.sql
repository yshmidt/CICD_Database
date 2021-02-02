﻿CREATE TABLE [dbo].[RFQDETL] (
    [RFQUNIQ]    CHAR (10)   CONSTRAINT [DF__RFQDETL__RFQUNIQ__2157A958] DEFAULT ('') NOT NULL,
    [RFQDTLUNIQ] CHAR (10)   CONSTRAINT [DF__RFQDETL__RFQDTLU__224BCD91] DEFAULT ('') NOT NULL,
    [ITEMNO]     NUMERIC (4) CONSTRAINT [DF__RFQDETL__ITEMNO__233FF1CA] DEFAULT ((0)) NOT NULL,
    [PARTMFGR]   CHAR (8)    CONSTRAINT [DF__RFQDETL__PARTMFG__24341603] DEFAULT ('') NOT NULL,
    [MFGR_PT_NO] CHAR (30)   CONSTRAINT [DF__RFQDETL__MFGR_PT__25283A3C] DEFAULT ('') NOT NULL,
    [PART_CLASS] CHAR (8)    CONSTRAINT [DF__RFQDETL__PART_CL__261C5E75] DEFAULT ('') NOT NULL,
    [PART_TYPE]  CHAR (8)    CONSTRAINT [DF__RFQDETL__PART_TY__271082AE] DEFAULT ('') NOT NULL,
    [DESCRIPT]   CHAR (45)   CONSTRAINT [DF__RFQDETL__DESCRIP__2804A6E7] DEFAULT ('') NOT NULL,
    [DETLSTATUS] CHAR (10)   CONSTRAINT [DF__RFQDETL__DETLSTA__28F8CB20] DEFAULT ('') NOT NULL,
    [SOURCE]     CHAR (12)   CONSTRAINT [DF__RFQDETL__SOURCE__29ECEF59] DEFAULT ('') NOT NULL,
    [PART_NO]    CHAR (25)   CONSTRAINT [DF__RFQDETL__PART_NO__2AE11392] DEFAULT ('') NOT NULL,
    [REVISION]   CHAR (4)    CONSTRAINT [DF__RFQDETL__REVISIO__2BD537CB] DEFAULT ('') NOT NULL,
    [CUSTPARTNO] CHAR (25)   CONSTRAINT [DF__RFQDETL__CUSTPAR__2CC95C04] DEFAULT ('') NOT NULL,
    [CUSTREV]    CHAR (4)    CONSTRAINT [DF__RFQDETL__CUSTREV__2DBD803D] DEFAULT ('') NOT NULL,
    [CUSTNO]     CHAR (10)   CONSTRAINT [DF__RFQDETL__CUSTNO__2EB1A476] DEFAULT ('') NOT NULL,
    [CUSTNAME]   CHAR (20)   CONSTRAINT [DF__RFQDETL__CUSTNAM__2FA5C8AF] DEFAULT ('') NOT NULL,
    [QTYNOTE]    TEXT        CONSTRAINT [DF__RFQDETL__QTYNOTE__3099ECE8] DEFAULT ('') NOT NULL,
    [PARENTPT]   CHAR (25)   CONSTRAINT [DF__RFQDETL__PARENTP__318E1121] DEFAULT ('') NOT NULL,
    [UNIQLINENO] CHAR (10)   CONSTRAINT [DF__RFQDETL__UNIQLIN__3282355A] DEFAULT ('') NOT NULL,
    [U_OF_MEAS]  CHAR (4)    CONSTRAINT [DF__RFQDETL__U_OF_ME__33765993] DEFAULT ('') NOT NULL,
    [UNIQSUPLNO] CHAR (10)   CONSTRAINT [DF__RFQDETL__UNIQSUP__346A7DCC] DEFAULT ('') NOT NULL,
    CONSTRAINT [RFQDETL_PK] PRIMARY KEY CLUSTERED ([RFQDTLUNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [RFQUNIQ]
    ON [dbo].[RFQDETL]([RFQUNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQSUPLNO]
    ON [dbo].[RFQDETL]([UNIQSUPLNO] ASC);

