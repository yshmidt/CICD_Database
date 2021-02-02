CREATE TABLE [dbo].[aspmnx_UserSuppliers] (
    [UserSuppId]  UNIQUEIDENTIFIER CONSTRAINT [DF_aspmnx_UserSuppliers_UserSuppId] DEFAULT (newsequentialid()) NOT NULL,
    [fkUserId]    UNIQUEIDENTIFIER NOT NULL,
    [fkUniqSupNo] CHAR (10)        NOT NULL,
    CONSTRAINT [PK_aspmnx_UserSuppliers_1] PRIMARY KEY CLUSTERED ([UserSuppId] ASC),
    CONSTRAINT [FK_aspmnx_UserSuppliers_aspnet_Users] FOREIGN KEY ([fkUserId]) REFERENCES [dbo].[aspnet_Users] ([UserId]) ON DELETE CASCADE,
    CONSTRAINT [FK_aspmnx_UserSuppliers_SUPINFO] FOREIGN KEY ([fkUniqSupNo]) REFERENCES [dbo].[SUPINFO] ([UNIQSUPNO]) ON DELETE CASCADE
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UserSuppliersUnique]
    ON [dbo].[aspmnx_UserSuppliers]([fkUniqSupNo] ASC, [fkUserId] ASC);

