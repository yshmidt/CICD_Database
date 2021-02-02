CREATE TABLE [dbo].[aspmnx_UserCustomers] (
    [UserCustId] UNIQUEIDENTIFIER CONSTRAINT [DF_aspmnx_UserCustomers_UserCustId] DEFAULT (newsequentialid()) NOT NULL,
    [fkUserId]   UNIQUEIDENTIFIER NOT NULL,
    [fkCustno]   CHAR (10)        CONSTRAINT [DF_aspmnx_UserCustomers_Custno] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_aspmnx_UserCustomers] PRIMARY KEY CLUSTERED ([UserCustId] ASC),
    CONSTRAINT [FK_aspmnx_UserCustomers_aspnet_Users] FOREIGN KEY ([fkUserId]) REFERENCES [dbo].[aspnet_Users] ([UserId]) ON DELETE CASCADE,
    CONSTRAINT [FK_aspmnx_UserCustomers_CUSTOMER] FOREIGN KEY ([fkCustno]) REFERENCES [dbo].[CUSTOMER] ([CUSTNO]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UserCustomersUnique]
    ON [dbo].[aspmnx_UserCustomers]([fkCustno] ASC, [fkUserId] ASC);

