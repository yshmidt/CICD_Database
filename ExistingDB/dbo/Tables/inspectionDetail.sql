CREATE TABLE [dbo].[inspectionDetail] (
    [inspHeaderId] CHAR (10)       CONSTRAINT [DF_inspectionDetail_inspHeaderId] DEFAULT ('') NOT NULL,
    [InspDetailID] CHAR (10)       CONSTRAINT [DF_inspectionDetail_InspDetailID] DEFAULT ('') NOT NULL,
    [def_code]     VARCHAR (20)    CONSTRAINT [DF_inspectioDetail_def_code] DEFAULT ('') NOT NULL,
    [defectQty]    NUMERIC (12, 2) CONSTRAINT [DF_inspectioDetail_defectQty] DEFAULT ((0.00)) NOT NULL,
    [defectNote]   NVARCHAR (MAX)  CONSTRAINT [DF__inspectio__defec__06D03253] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_inspectioDetail] PRIMARY KEY CLUSTERED ([InspDetailID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_inspectionDetail_hdr]
    ON [dbo].[inspectionDetail]([inspHeaderId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_inspectionDetail_Defect]
    ON [dbo].[inspectionDetail]([def_code] ASC);

