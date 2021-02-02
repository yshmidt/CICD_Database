CREATE TYPE [dbo].[SerialnoValidate] AS TABLE (
    [Serialno]  CHAR (30) NOT NULL,
    [UNIQ_KEY]  CHAR (10) NOT NULL,
    [nSequence] INT       IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([nSequence] ASC));

