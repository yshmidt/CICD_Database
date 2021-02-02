CREATE TABLE [dbo].[WOEquipments] (
    [WOEquipmentID]       INT        IDENTITY (1, 1) NOT NULL,
    [Dept_Id]             CHAR (4)   NOT NULL,
    [WONO]                CHAR (10)  NOT NULL,
    [Description]         CHAR (100) NOT NULL,
    [UniqueNumber]        CHAR (10)  NOT NULL,
    [TemplateId]          INT        NOT NULL,
    [WOEquipmentPriority] INT        NOT NULL,
    [WcEquipmentId]       INT        CONSTRAINT [DF__WOEquipme__WcEqu__0A2D5899] DEFAULT (NULL) NULL,
    [IsAssemblyAdded]     BIT        CONSTRAINT [DF__WOEquipme__IsAss__02AC3262] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WOEquipments] PRIMARY KEY CLUSTERED ([WOEquipmentID] ASC)
);

