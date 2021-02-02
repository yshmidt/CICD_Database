CREATE TABLE [dbo].[BANKS] (
    [BK_UNIQ]             CHAR (10)       CONSTRAINT [DF__BANKS__BK_UNIQ__2D47B39A] DEFAULT ('') NOT NULL,
    [BK_ACCT_NO]          VARCHAR (50)    CONSTRAINT [DF__BANKS__BK_ACCT_N__2E3BD7D3] DEFAULT ('') NOT NULL,
    [ACCTTITLE]           VARCHAR (50)    CONSTRAINT [DF__BANKS__ACCTTITLE__2F2FFC0C] DEFAULT ('') NOT NULL,
    [BANK]                VARCHAR (50)    CONSTRAINT [DF__BANKS__BANK__30242045] DEFAULT ('') NOT NULL,
    [ACCT_TYPE]           CHAR (20)       CONSTRAINT [DF__BANKS__ACCT_TYPE__3118447E] DEFAULT ('') NOT NULL,
    [GL_NBR]              CHAR (13)       CONSTRAINT [DF__BANKS__GL_NBR__320C68B7] DEFAULT ('') NOT NULL,
    [BC_GL_NBR]           CHAR (13)       CONSTRAINT [DF__BANKS__BC_GL_NBR__33008CF0] DEFAULT ('') NOT NULL,
    [INT_GL_NBR]          CHAR (13)       CONSTRAINT [DF__BANKS__INT_GL_NB__33F4B129] DEFAULT ('') NOT NULL,
    [BANK_BAL]            NUMERIC (12, 2) CONSTRAINT [DF__BANKS__BANK_BAL__34E8D562] DEFAULT ((0)) NOT NULL,
    [OPEN_BAL]            NUMERIC (12, 2) CONSTRAINT [DF__BANKS__OPEN_BAL__35DCF99B] DEFAULT ((0)) NOT NULL,
    [LAST_STMT]           SMALLDATETIME   NULL,
    [XXCKNOSYS]           BIT             CONSTRAINT [DF__BANKS__XXCKNOSYS__36D11DD4] DEFAULT ((0)) NOT NULL,
    [LASTCKNO]            CHAR (10)       CONSTRAINT [DF__BANKS__LASTCKNO__37C5420D] DEFAULT ('') NOT NULL,
    [BKLASTSAVE]          CHAR (10)       CONSTRAINT [DF__BANKS__BKLASTSAV__38B96646] DEFAULT ('') NOT NULL,
    [FK_UNIQLAYOUT]       CHAR (10)       CONSTRAINT [DF__BANKS__FK_UNIQLA__39AD8A7F] DEFAULT ('') NOT NULL,
    [LINACTIVE]           BIT             CONSTRAINT [DF__BANKS__LINACTIVE__3AA1AEB8] DEFAULT ((0)) NOT NULL,
    [AccountName]         VARCHAR (50)    CONSTRAINT [DF_BANKS_AccountName] DEFAULT ('') NOT NULL,
    [RoutingNumber]       CHAR (15)       CONSTRAINT [DF_BANKS_RoutingNumber] DEFAULT ('') NOT NULL,
    [SWIFT]               VARCHAR (50)    CONSTRAINT [DF_BANKS_SWIFT] DEFAULT ('') NOT NULL,
    [BranchNumber]        VARCHAR (10)    CONSTRAINT [DF_BANKS_BranchNumber] DEFAULT ('') NOT NULL,
    [CountryCode]         CHAR (4)        CONSTRAINT [DF_BANKS_CountryCode] DEFAULT ('') NOT NULL,
    [Address1]            VARCHAR (50)    CONSTRAINT [DF_BANKS_Address1] DEFAULT ('') NOT NULL,
    [Address2]            VARCHAR (50)    CONSTRAINT [DF_BANKS_Address2] DEFAULT ('') NOT NULL,
    [Address3]            VARCHAR (50)    CONSTRAINT [DF_BANKS_Address3] DEFAULT ('') NOT NULL,
    [Address4]            VARCHAR (50)    CONSTRAINT [DF_BANKS_Address4] DEFAULT ('') NOT NULL,
    [City]                VARCHAR (50)    CONSTRAINT [DF_BANKS_City] DEFAULT ('') NOT NULL,
    [StateCode]           VARCHAR (3)     CONSTRAINT [DF_BANKS_State] DEFAULT ('') NOT NULL,
    [ZipCode]             VARCHAR (10)    CONSTRAINT [DF_BANKS_ZipCode] DEFAULT ('') NOT NULL,
    [Country]             VARCHAR (50)    CONSTRAINT [DF_BANKS_Country] DEFAULT ('') NOT NULL,
    [attention]           VARCHAR (100)   CONSTRAINT [DF_BANKS_attention] DEFAULT ('') NOT NULL,
    [phone]               VARCHAR (20)    CONSTRAINT [DF_BANKS_phone] DEFAULT ('') NOT NULL,
    [fax]                 VARCHAR (20)    CONSTRAINT [DF_BANKS_fax] DEFAULT ('') NOT NULL,
    [email]               VARCHAR (100)   CONSTRAINT [DF_BANKS_email] DEFAULT ('') NOT NULL,
    [internalUse]         BIT             CONSTRAINT [DF_BANKS_internalUse] DEFAULT ((0)) NOT NULL,
    [PreferredDeposit]    BIT             CONSTRAINT [DF_BANKS_PreferredDeposit] DEFAULT ((0)) NOT NULL,
    [PaymentType]         VARCHAR (50)    CONSTRAINT [DF_BANKS_PaymentType] DEFAULT ('') NOT NULL,
    [eReferenceNumber]    VARCHAR (10)    CONSTRAINT [DF_BANKS_eReferenceNumber] DEFAULT ('') NULL,
    [AutoReferenceNumber] BIT             CONSTRAINT [DF_BANKS_AutoReferenceNumber] DEFAULT ((1)) NOT NULL,
    [Bank_BalFC]          NUMERIC (12, 2) CONSTRAINT [DF__BANKS__Bank_BalF__52FABD3B] DEFAULT ((0)) NOT NULL,
    [Open_BalFC]          NUMERIC (12, 2) CONSTRAINT [DF__BANKS__Open_BalF__53EEE174] DEFAULT ((0)) NOT NULL,
    [Fcused_Uniq]         CHAR (10)       CONSTRAINT [DF__BANKS__Fcused_Un__54E305AD] DEFAULT ('') NOT NULL,
    [lIs_Preferred]       BIT             CONSTRAINT [DF__BANKS__lIs_Prefe__56CB4E1F] DEFAULT ((0)) NOT NULL,
    [Currency]            CHAR (3)        CONSTRAINT [DF__BANKS__Currency__57BF7258] DEFAULT ('') NOT NULL,
    [lIs_Virtual]         BIT             CONSTRAINT [DF__BANKS__lIs_Virtu__7C51D889] DEFAULT ((0)) NOT NULL,
    [PreferredWithdrawal] BIT             CONSTRAINT [DF__BANKS__Preferred__5B85E19B] DEFAULT ((0)) NOT NULL,
    [Bank_BalPR]          NUMERIC (12, 2) CONSTRAINT [DF__BANKS__Bank_BalP__63089E80] DEFAULT ((0)) NOT NULL,
    [Open_BalPR]          NUMERIC (12, 2) CONSTRAINT [DF__BANKS__Open_BalP__63FCC2B9] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [BANKS_PK] PRIMARY KEY CLUSTERED ([BK_UNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [BANK]
    ON [dbo].[BANKS]([BANK] ASC);


GO
CREATE NONCLUSTERED INDEX [BK_ACCT_NO]
    ON [dbo].[BANKS]([BK_ACCT_NO] ASC);


GO
CREATE NONCLUSTERED INDEX [GL_NBR]
    ON [dbo].[BANKS]([GL_NBR] ASC);

