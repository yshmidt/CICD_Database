CREATE TABLE [dbo].[PayrollHistory] (
    [Id]              INT              IDENTITY (1, 1) NOT NULL,
    [UserId]          UNIQUEIDENTIFIER NOT NULL,
    [PayRate]         NUMERIC (20, 2)  NOT NULL,
    [HRType]          CHAR (50)        NOT NULL,
    [UpdatedDate]     DATETIME         NOT NULL,
    [UpdatedBy]       VARCHAR (8)      NOT NULL,
    [UpdatedByUserId] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_PayrollHistory] PRIMARY KEY CLUSTERED ([Id] ASC)
);

