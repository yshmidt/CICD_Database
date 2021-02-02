CREATE TABLE [dbo].[MnxVisitorLog] (
    [visitId]        INT              IDENTITY (1, 1) NOT NULL,
    [fullName]       VARCHAR (200)    CONSTRAINT [DF_MnxVisitorLog_fullName] DEFAULT ('') NOT NULL,
    [companyName]    VARCHAR (100)    CONSTRAINT [DF_MnxVisitorLog_companyName] DEFAULT ('') NOT NULL,
    [citizen]        BIT              CONSTRAINT [DF_MnxVisitorLog_citizen] DEFAULT ((0)) NOT NULL,
    [timeIn]         SMALLDATETIME    CONSTRAINT [DF_MnxVisitorLog_timeIn] DEFAULT (getdate()) NOT NULL,
    [timeOut]        SMALLDATETIME    NULL,
    [purposeOfVisit] VARCHAR (200)    CONSTRAINT [DF_MnxVisitorLog_purposeOfVisit] DEFAULT ('') NOT NULL,
    [uniqePhrase]    VARCHAR (50)     NULL,
    [personVisiting] VARCHAR (200)    CONSTRAINT [DF_MnxVisitorLog_personVisiting] DEFAULT ('') NOT NULL,
    [badgeCode]      VARCHAR (100)    CONSTRAINT [DF_MnxVisitorLog_badgeCode] DEFAULT ('') NOT NULL,
    [imagePath]      NVARCHAR (MAX)   NULL,
    [escortUserId]   UNIQUEIDENTIFIER NULL,
    CONSTRAINT [PK_MnxVisitorLog] PRIMARY KEY CLUSTERED ([visitId] ASC),
    CONSTRAINT [FK_aspnet_Me_MnxVisitorLog] FOREIGN KEY ([escortUserId]) REFERENCES [dbo].[aspnet_Profile] ([UserId])
);


GO
CREATE NONCLUSTERED INDEX [IX_MnxVisitorLog]
    ON [dbo].[MnxVisitorLog]([fullName] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MnxVisitorLog_1]
    ON [dbo].[MnxVisitorLog]([companyName] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MnxVisitorLog_2]
    ON [dbo].[MnxVisitorLog]([badgeCode] ASC);

