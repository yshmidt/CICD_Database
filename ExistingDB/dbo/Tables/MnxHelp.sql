CREATE TABLE [dbo].[MnxHelp] (
    [HelpId]                 INT           IDENTITY (1, 1) NOT NULL,
    [HelpKey]                VARCHAR (100) NULL,
    [HeaderResourceKey]      VARCHAR (100) NOT NULL,
    [DescriptionResourceKey] VARCHAR (100) NOT NULL,
    [FieldLength]            INT           CONSTRAINT [DF_MnxHelp_FieldLength] DEFAULT ((0)) NOT NULL,
    [Definition]             VARCHAR (MAX) NULL,
    [DataBaseLocation]       VARCHAR (250) NOT NULL,
    [CssSelector]            VARCHAR (100) NULL,
    CONSTRAINT [PK_MnxHelp] PRIMARY KEY CLUSTERED ([HelpId] ASC)
);

