CREATE TABLE [dbo].[MnxKendoGridDefaults] (
    [fieldID]         INT           IDENTITY (1, 1) NOT NULL,
    [fieldName]       VARCHAR (200) NOT NULL,
    [localizationKey] VARCHAR (50)  NOT NULL,
    [editable]        BIT           CONSTRAINT [DF__MnxKendoG__edita__2F7E0D82] DEFAULT ('true') NOT NULL,
    [sortable]        BIT           CONSTRAINT [DF__MnxKendoG__sorta__307231BB] DEFAULT ((1)) NOT NULL,
    [width]           INT           CONSTRAINT [DF__MnxKendoG__width__316655F4] DEFAULT ((1)) NOT NULL,
    [align]           VARCHAR (10)  CONSTRAINT [DF__MnxKendoG__align__325A7A2D] DEFAULT ('') NOT NULL,
    [hidden]          BIT           CONSTRAINT [DF__MnxKendoG__hidde__334E9E66] DEFAULT ((0)) NOT NULL,
    [formatter]       VARCHAR (150) NULL,
    [formatoptions]   VARCHAR (MAX) CONSTRAINT [DF__MnxKendoG__forma__3536E6D8] DEFAULT ('') NOT NULL,
    [typeOfFormate]   NCHAR (30)    NULL,
    [validation]      VARCHAR (150) NULL,
    [nullable]        VARCHAR (150) NULL,
    [editor]          VARCHAR (150) NULL,
    [gridid]          VARCHAR (50)  NULL,
    [Filterable]      BIT           CONSTRAINT [DF__MnxKendoG__Filte__53122DD9] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK__MnxKendo__F0AC27FE744240FB] PRIMARY KEY CLUSTERED ([fieldID] ASC)
);

