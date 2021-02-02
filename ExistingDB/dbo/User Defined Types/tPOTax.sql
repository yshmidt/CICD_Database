CREATE TYPE [dbo].[tPOTax] AS TABLE (
    [ImportId]       UNIQUEIDENTIFIER NULL,
    [fkRowId]        UNIQUEIDENTIFIER NULL,
    [CssClass]       CHAR (10)        NULL,
    [Validation]     CHAR (10)        NULL,
    [TaxDescription] CHAR (25)        NULL,
    [TaxRate]        NUMERIC (9)      NULL,
    [TAXID]          CHAR (10)        NULL);

