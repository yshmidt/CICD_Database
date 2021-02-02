CREATE TABLE [dbo].[wmTriggerEmails] (
    [messageid]       UNIQUEIDENTIFIER CONSTRAINT [DF__WMNotice__messa__529ACA88] DEFAULT (newid()) NOT NULL,
    [toEmail]         VARCHAR (MAX)    NULL,
    [tocc]            VARCHAR (MAX)    NULL,
    [tobcc]           VARCHAR (MAX)    NULL,
    [fromEmail]       VARCHAR (50)     NULL,
    [fromPw]          VARCHAR (50)     NULL,
    [subject]         VARCHAR (MAX)    NULL,
    [body]            VARCHAR (MAX)    NOT NULL,
    [attachments]     VARCHAR (MAX)    NULL,
    [isHtml]          BIT              CONSTRAINT [DF_wmTriggerEmails_isHtml] DEFAULT ((0)) NOT NULL,
    [dateAdded]       DATETIME2 (3)    NULL,
    [dateSent]        DATETIME2 (3)    NULL,
    [dateFirstOpened] DATETIME2 (3)    NULL,
    [note]            VARCHAR (MAX)    NULL,
    [hasError]        BIT              NULL,
    [errorCode]       VARCHAR (MAX)    NULL,
    [errorMessage]    VARCHAR (MAX)    NULL,
    [deleteOnSend]    BIT              CONSTRAINT [DF_WMTriggerEmails_deleteOnSend] DEFAULT ((0)) NOT NULL,
    [fktriggerID]     VARCHAR (50)     CONSTRAINT [DF_wmTriggerEmails_fktriggerID] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK__WMNotic__4807CDDB50B28216] PRIMARY KEY CLUSTERED ([messageid] ASC)
);

