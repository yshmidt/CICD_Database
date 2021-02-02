CREATE TABLE [dbo].[WOTools] (
    [WOToolID]          INT           IDENTITY (1, 1) NOT NULL,
    [Dept_Id]           CHAR (4)      NOT NULL,
    [WONO]              CHAR (10)     NOT NULL,
    [Description]       CHAR (100)    NOT NULL,
    [UniqueNumber]      CHAR (10)     NOT NULL,
    [TemplateId]        INT           NOT NULL,
    [WOToolPriority]    INT           NOT NULL,
    [ToolsAndFixtureId] CHAR (10)     CONSTRAINT [DF__WOTools__ToolsAn__0D09C544] DEFAULT (NULL) NULL,
    [IsAssemblyAdded]   BIT           CONSTRAINT [DF__WOTools__IsAssem__03A0569B] DEFAULT ((0)) NOT NULL,
    [ToolId]            CHAR (10)     CONSTRAINT [DF__WOTools__ToolId__763C39DC] DEFAULT (NULL) NULL,
    [Location]          NVARCHAR (50) CONSTRAINT [DF__WOTools__Locatio__10B1044D] DEFAULT ('') NOT NULL,
    [ToolSerialNumber]  NVARCHAR (50) CONSTRAINT [DF__WOTools__ToolSer__11A52886] DEFAULT ('') NOT NULL,
    [ToolCustomerID]    NVARCHAR (50) CONSTRAINT [DF__WOTools__ToolCus__12994CBF] DEFAULT ('') NOT NULL,
    [DateofPurchase]    SMALLDATETIME NULL,
    [ExpirationDate]    SMALLDATETIME NULL,
    CONSTRAINT [PK_WOTools] PRIMARY KEY CLUSTERED ([WOToolID] ASC)
);

