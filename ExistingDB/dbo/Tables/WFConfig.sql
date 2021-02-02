CREATE TABLE [dbo].[WFConfig] (
    [WFConfigId]   CHAR (10)        NOT NULL,
    [ApproverId]   UNIQUEIDENTIFIER NULL,
    [ConfigName]   CHAR (100)       NOT NULL,
    [MetaDataId]   CHAR (10)        NOT NULL,
    [OperatorType] CHAR (20)        NULL,
    [StartValue]   NUMERIC (12, 2)  NULL,
    [EndValue]     NUMERIC (12, 2)  NULL,
    [IsAll]        BIT              NULL,
    [WFid]         CHAR (10)        NOT NULL,
    [StepNumber]   INT              NOT NULL,
    [IsGroup]      BIT              NULL,
    CONSTRAINT [PK_WFConfig] PRIMARY KEY CLUSTERED ([WFConfigId] ASC)
);

