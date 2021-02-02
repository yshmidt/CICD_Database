CREATE TABLE [dbo].[ECDocuments] (
    [ECDocUniq]      INT              IDENTITY (1, 1) NOT NULL,
    [UNIQECNO]       CHAR (10)        NOT NULL,
    [DocNameAndNo]   VARCHAR (200)    NOT NULL,
    [Description]    VARCHAR (200)    NOT NULL,
    [Revision]       VARCHAR (50)     NOT NULL,
    [IssueDate]      DATE             NOT NULL,
    [ExpirationDate] DATE             NULL,
    [UserId]         UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_ECDocuments] PRIMARY KEY CLUSTERED ([ECDocUniq] ASC)
);

