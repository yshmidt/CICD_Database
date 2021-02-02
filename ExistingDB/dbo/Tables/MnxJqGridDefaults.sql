CREATE TABLE [dbo].[MnxJqGridDefaults] (
    [fieldName]       VARCHAR (200) NOT NULL,
    [localizationKey] VARCHAR (50)  NOT NULL,
    [editable]        BIT           CONSTRAINT [DF_MnxJqGridDefaults_editable] DEFAULT ('true') NOT NULL,
    [sortable]        BIT           CONSTRAINT [DF_MnxJqGridDefaults_sortable] DEFAULT ((1)) NOT NULL,
    [width]           INT           CONSTRAINT [DF_MnxJqGridDefaults_width] DEFAULT ((1)) NOT NULL,
    [align]           VARCHAR (10)  CONSTRAINT [DF_MnxJqGridDefaults_align] DEFAULT ('') NOT NULL,
    [hidden]          BIT           CONSTRAINT [DF_MnxJqGridDefaults_hidden] DEFAULT ((0)) NOT NULL,
    [sorttype]        VARCHAR (MAX) CONSTRAINT [DF_MnxJqGridDefaults_sorttype] DEFAULT ('') NOT NULL,
    [formatter]       VARCHAR (20)  CONSTRAINT [DF_MnxJqGridDefaults_formatter] DEFAULT ('') NOT NULL,
    [formatoptions]   VARCHAR (MAX) CONSTRAINT [DF_MnxJqGridDefaults_formatoptions] DEFAULT ('') NOT NULL,
    [datefmt]         VARCHAR (100) CONSTRAINT [DF_MnxJqGridDefaults_datefmt] DEFAULT ('') NOT NULL,
    [adtlParams]      VARCHAR (MAX) CONSTRAINT [DF_MnxJqGridDefaults_summaryType] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_MnxJqGridDefaults] PRIMARY KEY CLUSTERED ([fieldName] ASC)
);

