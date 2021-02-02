CREATE TABLE [dbo].[MnxReportParamTargets] (
    [recordId]       UNIQUEIDENTIFIER CONSTRAINT [DF_rptParamTargets_recordId] DEFAULT (newid()) NOT NULL,
    [rptParamId]     UNIQUEIDENTIFIER NOT NULL,
    [parentParamId]  UNIQUEIDENTIFIER NOT NULL,
    [renderTogether] BIT              CONSTRAINT [DF_MnxReportParamTargets_renderTogether] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_rptParamTargets] PRIMARY KEY CLUSTERED ([recordId] ASC),
    CONSTRAINT [IX_rptParamTargets] UNIQUE NONCLUSTERED ([parentParamId] ASC, [rptParamId] ASC)
);

