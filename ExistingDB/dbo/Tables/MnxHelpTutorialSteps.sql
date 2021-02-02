CREATE TABLE [dbo].[MnxHelpTutorialSteps] (
    [Id]           INT IDENTITY (1, 1) NOT NULL,
    [HelpId]       INT NULL,
    [ModuleId]     INT NOT NULL,
    [ControlOrder] INT NOT NULL,
    [Required]     BIT CONSTRAINT [DF_MnxHelpTutorialSteps_Required] DEFAULT ((0)) NOT NULL,
    [CanAffectUI]  BIT CONSTRAINT [DF_MnxHelpTutorialSteps_CanAffectUI] DEFAULT ((0)) NULL,
    [isHighlight]  BIT CONSTRAINT [DF_MnxHelpTutorialSteps_isHighlight] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MnxHelpTutorialSteps] PRIMARY KEY CLUSTERED ([Id] ASC)
);

