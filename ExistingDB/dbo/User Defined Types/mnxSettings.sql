CREATE TYPE [dbo].[mnxSettings] AS TABLE (
    [settingName]        VARCHAR (100) NULL,
    [settingValue]       VARCHAR (MAX) NULL,
    [settingType]        VARCHAR (50)  NULL,
    [settingDescription] VARCHAR (MAX) NULL,
    [sourceLink]         VARCHAR (100) NULL,
    [paramType]          VARCHAR (50)  NULL);

