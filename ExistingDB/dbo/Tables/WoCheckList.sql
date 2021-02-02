CREATE TABLE [dbo].[WoCheckList] (
    [WoCheckUniq]     INT              IDENTITY (1, 1) NOT NULL,
    [Dept_ID]         CHAR (4)         NOT NULL,
    [Wono]            CHAR (10)        NOT NULL,
    [Description]     CHAR (100)       NOT NULL,
    [UniqueNumber]    CHAR (10)        NOT NULL,
    [TemplateId]      INT              NOT NULL,
    [WOCheckPriority] INT              NOT NULL,
    [CheckedDate]     DATETIME         NULL,
    [IsAssemblyAdded] BIT              CONSTRAINT [DF__WoCheckLi__IsAss__01B80E29] DEFAULT ((0)) NOT NULL,
    [CheckedBy]       UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_WoCheckList] PRIMARY KEY CLUSTERED ([WoCheckUniq] ASC)
);

