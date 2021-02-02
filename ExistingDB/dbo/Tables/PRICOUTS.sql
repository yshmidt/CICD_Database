﻿CREATE TABLE [dbo].[PRICOUTS] (
    [PART_CLASS] CHAR (8)        CONSTRAINT [DF__PRICOUTS__PART_C__3632CAAD] DEFAULT ('') NOT NULL,
    [PART_TYPE]  CHAR (8)        CONSTRAINT [DF__PRICOUTS__PART_T__3726EEE6] DEFAULT ('') NOT NULL,
    [PART_NO]    CHAR (25)       CONSTRAINT [DF__PRICOUTS__PART_N__381B131F] DEFAULT ('') NOT NULL,
    [REVISION]   CHAR (4)        CONSTRAINT [DF__PRICOUTS__REVISI__390F3758] DEFAULT ('') NOT NULL,
    [PAGEBREAK]  CHAR (2)        CONSTRAINT [DF__PRICOUTS__PAGEBR__3A035B91] DEFAULT ('') NOT NULL,
    [FROMQTY]    NUMERIC (7)     CONSTRAINT [DF__PRICOUTS__FROMQT__3AF77FCA] DEFAULT ((0)) NOT NULL,
    [TOQTY]      NUMERIC (7)     CONSTRAINT [DF__PRICOUTS__TOQTY__3BEBA403] DEFAULT ((0)) NOT NULL,
    [COST]       NUMERIC (8, 2)  CONSTRAINT [DF__PRICOUTS__COST__3CDFC83C] DEFAULT ((0)) NOT NULL,
    [COST1]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST1__3DD3EC75] DEFAULT ((0)) NOT NULL,
    [COST2]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST2__3EC810AE] DEFAULT ((0)) NOT NULL,
    [COST3]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST3__3FBC34E7] DEFAULT ((0)) NOT NULL,
    [COST4]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST4__40B05920] DEFAULT ((0)) NOT NULL,
    [COST5]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST5__41A47D59] DEFAULT ((0)) NOT NULL,
    [COST6]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST6__4298A192] DEFAULT ((0)) NOT NULL,
    [COST7]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST7__438CC5CB] DEFAULT ((0)) NOT NULL,
    [COST8]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST8__4480EA04] DEFAULT ((0)) NOT NULL,
    [COST9]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST9__45750E3D] DEFAULT ((0)) NOT NULL,
    [COST10]     NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__COST10__46693276] DEFAULT ((0)) NOT NULL,
    [TOTAL]      NUMERIC (12, 5) CONSTRAINT [DF__PRICOUTS__TOTAL__475D56AF] DEFAULT ((0)) NOT NULL,
    [PRICOUTSUK] CHAR (10)       CONSTRAINT [DF_PRICOUTS_PRICOUTSUK] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_PRICOUTS] PRIMARY KEY CLUSTERED ([PRICOUTSUK] ASC)
);


GO
CREATE NONCLUSTERED INDEX [PRICOUTS]
    ON [dbo].[PRICOUTS]([PART_CLASS] ASC, [PART_TYPE] ASC, [PART_NO] ASC, [REVISION] ASC, [PAGEBREAK] ASC);

