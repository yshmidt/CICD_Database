CREATE TABLE [dbo].[UsersPrefForms] (
    [Fk_UniqUser]  CHAR (10) CONSTRAINT [DF_UsersPrefApps_Fk_UniqUser] DEFAULT ('') NOT NULL,
    [FK_WebFormID] INT       CONSTRAINT [DF_UsersPrefApps_Fk_UniqApp] DEFAULT ((0)) NOT NULL,
    [UniqueUPFA]   INT       IDENTITY (1, 1) NOT NULL,
    [FormsOrder]   INT       CONSTRAINT [DF_UsersPrefApps_AppOrder] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_UsersPrefForms] PRIMARY KEY NONCLUSTERED ([UniqueUPFA] ASC),
    CONSTRAINT [FK_UsersPrefApps_Users] FOREIGN KEY ([Fk_UniqUser]) REFERENCES [dbo].[USERS] ([UNIQ_USER]) ON DELETE CASCADE,
    CONSTRAINT [FK_UsersPrefApps_WebForms] FOREIGN KEY ([FK_WebFormID]) REFERENCES [dbo].[WebFormsList] ([WebFormID]) ON DELETE CASCADE
);


GO
CREATE UNIQUE CLUSTERED INDEX [UserForms]
    ON [dbo].[UsersPrefForms]([Fk_UniqUser] ASC, [FK_WebFormID] ASC);


GO
CREATE NONCLUSTERED INDEX [FK_WebFormID]
    ON [dbo].[UsersPrefForms]([FK_WebFormID] ASC);


GO
CREATE NONCLUSTERED INDEX [UserPref]
    ON [dbo].[UsersPrefForms]([Fk_UniqUser] ASC, [FormsOrder] ASC);

