CREATE TABLE [dbo].[SecOption] (
    [SecoptionUk]    CHAR (10)  NOT NULL,
    [SecoptionField] CHAR (15)  NOT NULL,
    [SecoptionDesc]  CHAR (100) NOT NULL,
    [ScreenName]     CHAR (8)   NOT NULL,
    CONSTRAINT [SecOptnUk] PRIMARY KEY CLUSTERED ([SecoptionUk] ASC)
);

