﻿CREATE TABLE [dbo].[DMrheader] (
    [dmr_no]     CHAR (10)     CONSTRAINT [DF_DMrheader_dmr_no] DEFAULT ('') NOT NULL,
    [RMA_NO]     CHAR (15)     CONSTRAINT [DF_DMrheader_RMA_NO] DEFAULT ('') NOT NULL,
    [confirmBy]  CHAR (30)     CONSTRAINT [DF_DMrheader_confirmBy] DEFAULT ('') NOT NULL,
    [dmr_Date]   SMALLDATETIME NULL,
    [RMA_DATE]   SMALLDATETIME NULL,
    [SHIPVIA]    CHAR (15)     CONSTRAINT [DF__DMrheader__SHIPVI__3B2C89F4] DEFAULT ('') NOT NULL,
    [SHIPCHARGE] CHAR (15)     CONSTRAINT [DF__DMrheader__SHIPCH__3C20AE2D] DEFAULT ('') NOT NULL,
    [FOB]        CHAR (15)     CONSTRAINT [DF__DMrheader__FOB__3D14D266] DEFAULT ('') NOT NULL,
    [TERMS]      CHAR (15)     CONSTRAINT [DF__DMrheader__TERMS__3E08F69F] DEFAULT ('') NOT NULL,
    [FREIGHTAMT] CHAR (15)     CONSTRAINT [DF__DMrheader__FREIGH__3EFD1AD8] DEFAULT ('') NOT NULL,
    [WAYBILL]    CHAR (20)     CONSTRAINT [DF__DMrheader__WAYBIL__3FF13F11] DEFAULT ('') NOT NULL,
    [LINKADD]    CHAR (10)     CONSTRAINT [DF__DMrheader__LINKAD__40E5634A] DEFAULT ('') NOT NULL,
    [DMRUNIQUE]  CHAR (10)     CONSTRAINT [DF__DMrheader__DMRUNI__42CDABBC] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [PRINTDMR]   BIT           CONSTRAINT [DF__DMrheader__PRINTD__43C1CFF5] DEFAULT ((0)) NOT NULL,
    [Ponum]      CHAR (15)     CONSTRAINT [DF_DMrheader_Ponum] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_DMrheader] PRIMARY KEY CLUSTERED ([DMRUNIQUE] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_DMrheader]
    ON [dbo].[DMrheader]([dmr_no] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DMrheader_1]
    ON [dbo].[DMrheader]([RMA_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DMrheader_2]
    ON [dbo].[DMrheader]([LINKADD] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DMrheader_3]
    ON [dbo].[DMrheader]([Ponum] ASC);

