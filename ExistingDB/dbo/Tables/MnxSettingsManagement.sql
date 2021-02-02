CREATE TABLE [dbo].[MnxSettingsManagement] (
    [settingId]          UNIQUEIDENTIFIER CONSTRAINT [DF_MnxSettingsManagement_settingId] DEFAULT (newid()) NOT NULL,
    [moduleId]           INT              CONSTRAINT [DF_mnxSettingsManagement_moduleId] DEFAULT ((0)) NOT NULL,
    [settingName]        VARCHAR (100)    CONSTRAINT [DF_MnxSettingsManagement_settingName] DEFAULT ('') NOT NULL,
    [settingValue]       VARCHAR (MAX)    CONSTRAINT [DF_MnxSettingsManagement_settingValue] DEFAULT ('') NOT NULL,
    [settingType]        VARCHAR (50)     CONSTRAINT [DF_settingTimeManagement_settingType] DEFAULT ('string') NOT NULL,
    [settingDescription] VARCHAR (MAX)    CONSTRAINT [DF_MnxSettingsManagement_settingDescription] DEFAULT ('') NOT NULL,
    [sourceLink]         VARCHAR (100)    CONSTRAINT [DF_MnxSettingsManagement_listType] DEFAULT ('') NOT NULL,
    [paramType]          VARCHAR (50)     CONSTRAINT [DF_MnxSettingsManagement_listValues] DEFAULT ('') NOT NULL,
    [renderOrder]        INT              CONSTRAINT [DF_MnxSettingsManagement_renderOrder] DEFAULT ((0)) NOT NULL,
    [settingModule]      NVARCHAR (300)   NULL,
    [IsInfoRequired]     BIT              CONSTRAINT [DF__MnxSettin__IsInf__35ABE824] DEFAULT ((0)) NOT NULL,
    [radioLabelValue]    VARCHAR (MAX)    NULL,
    [ValueMaxLength]     INT              CONSTRAINT [DF_MnxSettingsManagement_ValueMaxLength] DEFAULT (NULL) NULL,
    [IsShowSetting]      BIT              CONSTRAINT [DF_MnxSettingsManagement_IsShowSetting] DEFAULT ((1)) NOT NULL,
    [IsEditor]           BIT              CONSTRAINT [DF__MnxSettin__IsEdi__14B69F5B] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_mnxSettingsManagement] PRIMARY KEY NONCLUSTERED ([settingId] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [SettingModule]
    ON [dbo].[MnxSettingsManagement]([moduleId] ASC, [settingName] ASC);

