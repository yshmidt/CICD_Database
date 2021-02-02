CREATE TABLE [dbo].[WmReportParamTargets] (
    [recordId]       UNIQUEIDENTIFIER CONSTRAINT [wmDF_rptParamTargets_recordId] DEFAULT (newid()) NOT NULL,
    [rptParamId]     UNIQUEIDENTIFIER NOT NULL,
    [parentParamId]  UNIQUEIDENTIFIER NOT NULL,
    [renderTogether] BIT              CONSTRAINT [wmDF_MnxReportParamTargets_renderTogether] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [wmPK_rptParamTargets] PRIMARY KEY CLUSTERED ([recordId] ASC),
    CONSTRAINT [wmIX_rptParamTargets] UNIQUE NONCLUSTERED ([parentParamId] ASC, [rptParamId] ASC)
);

