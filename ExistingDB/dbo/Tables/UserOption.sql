CREATE TABLE [dbo].[UserOption] (
    [UserOptionUK] CHAR (10) NOT NULL,
    [UserId]       CHAR (8)  NOT NULL,
    [SecOptionUk]  CHAR (10) NOT NULL,
    CONSTRAINT [UserOptnUk] PRIMARY KEY CLUSTERED ([UserOptionUK] ASC)
);

