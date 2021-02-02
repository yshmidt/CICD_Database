CREATE TYPE [dbo].[tCustomerCreditAvailable] AS TABLE (
    [CustName]        CHAR (50)       NOT NULL,
    [CustNo]          CHAR (10)       NOT NULL,
    [CreditAvailable] NUMERIC (20, 2) NOT NULL);

