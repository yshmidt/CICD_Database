CREATE TABLE [dbo].[MnxSettingHelpManagement] (
    [HelpId]                  INT              IDENTITY (1, 1) NOT NULL,
    [SettingId]               UNIQUEIDENTIFIER NULL,
    [HeaderResourceKey]       NVARCHAR (MAX)   NULL,
    [DescriptionResourceKey]  NVARCHAR (MAX)   NULL,
    [LocationDescResourceKey] NVARCHAR (MAX)   NULL,
    [ExampleResourceKey]      NVARCHAR (MAX)   NULL,
    [ModuleId]                INT              NULL,
    [LocationDescImage]       NVARCHAR (MAX)   NULL,
    [SettingExampleImage]     NVARCHAR (MAX)   NULL,
    [OptionId]                INT              NULL,
    [HelpName]                NVARCHAR (MAX)   NULL,
    CONSTRAINT [PK_MnxSettingHelpManagement] PRIMARY KEY CLUSTERED ([HelpId] ASC)
);

