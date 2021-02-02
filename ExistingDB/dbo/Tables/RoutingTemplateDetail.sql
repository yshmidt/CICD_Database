CREATE TABLE [dbo].[RoutingTemplateDetail] (
    [TemplateDetailId] INT         IDENTITY (1, 1) NOT NULL,
    [DeptId]           CHAR (4)    NOT NULL,
    [SequenceNo]       NUMERIC (4) NOT NULL,
    [TemplateId]       INT         NOT NULL,
    [IsOptional]       BIT         CONSTRAINT [DF__RoutingTe__IsOpt__5CE5B0D6] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TemplateDetail] PRIMARY KEY CLUSTERED ([TemplateDetailId] ASC),
    CONSTRAINT [FK_TemplateDetail_RoutingTemplate] FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[RoutingTemplate] ([TemplateID])
);

