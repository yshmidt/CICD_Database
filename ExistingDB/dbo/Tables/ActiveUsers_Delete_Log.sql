CREATE TABLE [dbo].[ActiveUsers_Delete_Log] (
    [sessionId]        VARCHAR (50)     NOT NULL,
    [fkuserId]         UNIQUEIDENTIFIER NOT NULL,
    [lastActivityDate] DATETIME         NOT NULL,
    [workstationId]    VARCHAR (50)     NULL,
    [lastModule]       VARCHAR (50)     NULL,
    [ipaddress]        VARCHAR (50)     NULL,
    [oldsessionId]     VARCHAR (50)     CONSTRAINT [DF_ActiveUsers_Delete_Log_oldsessionId] DEFAULT ('') NOT NULL,
    [deleteDate]       DATETIME2 (7)    CONSTRAINT [DF__ActiveUse__delet__479E1928] DEFAULT (getdate()) NOT NULL,
    [pkDeleteLog]      UNIQUEIDENTIFIER CONSTRAINT [DF_ActiveUsers_Delete_Log_pkDeleteLog] DEFAULT (newid()) NOT NULL,
    CONSTRAINT [pk_ActiveUsers_Delete_Log] PRIMARY KEY NONCLUSTERED ([pkDeleteLog] ASC)
);

