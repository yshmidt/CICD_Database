CREATE TABLE [dbo].[UserSettingGridColumns] (
    [id]             INT              IDENTITY (1, 1) NOT NULL,
    [userId]         UNIQUEIDENTIFIER NULL,
    [gridId]         NVARCHAR (50)    NULL,
    [fixedCols]      NVARCHAR (MAX)   NULL,
    [hideCols]       NVARCHAR (MAX)   NULL,
    [IsColumnUpdate] BIT              CONSTRAINT [DF__UserSetti__IsCol__141780DD] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_UserSettingGridColumns] PRIMARY KEY CLUSTERED ([id] ASC)
);

