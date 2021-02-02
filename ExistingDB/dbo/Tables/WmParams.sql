CREATE TABLE [dbo].[WmParams] (
    [rptParamId]      UNIQUEIDENTIFIER CONSTRAINT [wmDF_wmParams_paramId] DEFAULT (newid()) NOT NULL,
    [localizationKey] VARCHAR (50)     CONSTRAINT [wmDF_wmParams_displayName] DEFAULT ('') NOT NULL,
    [paramName]       VARCHAR (50)     NOT NULL,
    [paramType]       VARCHAR (50)     CONSTRAINT [wmDF_wmParams_paramType] DEFAULT ('Text') NOT NULL,
    [sourceLink]      VARCHAR (100)    CONSTRAINT [wmDF_wmParams_sourceLink] DEFAULT ('') NOT NULL,
    [fieldWidth]      VARCHAR (50)     CONSTRAINT [wmDF_wmParams_fieldWidth] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_wmParams] PRIMARY KEY CLUSTERED ([rptParamId] ASC)
);

