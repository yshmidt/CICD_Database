CREATE TABLE [dbo].[UDFValues2] (
    [fk_FieldListId] UNIQUEIDENTIFIER NOT NULL,
    [RowId]          UNIQUEIDENTIFIER NOT NULL,
    [fk_RecordId]    CHAR (10)        NOT NULL,
    [Value]          VARCHAR (MAX)    NOT NULL,
    CONSTRAINT [PK__UDFValue__9C85E4D85947C817] PRIMARY KEY CLUSTERED ([fk_FieldListId] ASC, [RowId] ASC)
);

