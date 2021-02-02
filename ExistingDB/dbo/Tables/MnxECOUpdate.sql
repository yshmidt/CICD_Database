CREATE TABLE [dbo].[MnxECOUpdate] (
    [ID]             INT            IDENTITY (1, 1) NOT NULL,
    [UpdateCriteria] NVARCHAR (100) NOT NULL,
    [FieldType]      CHAR (10)      NOT NULL,
    [FieldLength]    NUMERIC (20)   NULL,
    CONSTRAINT [PK__MnxECOUp__3214EC27C9932901] PRIMARY KEY CLUSTERED ([ID] ASC)
);

