CREATE TABLE [dbo].[mnxTabOption] (
    [OptionId]    INT           IDENTITY (1, 1) NOT NULL,
    [OptionName]  VARCHAR (MAX) NULL,
    [ModuleId]    INT           NULL,
    [HrefRoute]   VARCHAR (MAX) NULL,
    [renderOrder] INT           CONSTRAINT [DF__mnxTabOpt__rende__4EEC973A] DEFAULT ((0)) NOT NULL,
    [Type]        NVARCHAR (50) CONSTRAINT [DF__mnxTabOpti__Type__469813B2] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_MnxSetup] PRIMARY KEY CLUSTERED ([OptionId] ASC)
);

