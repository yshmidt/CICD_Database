CREATE TABLE [dbo].[FcUsed] (
    [FcUsed_Uniq] CHAR (10)    NOT NULL,
    [Country]     VARCHAR (60) CONSTRAINT [DF__FcUsed__Country__5FB66532] DEFAULT ('') NOT NULL,
    [Currency]    VARCHAR (40) CONSTRAINT [DF__FcUsed__Currency__60AA896B] DEFAULT ('') NOT NULL,
    [Symbol]      VARCHAR (3)  CONSTRAINT [DF__FcUsed__Symbol__619EADA4] DEFAULT ('') NOT NULL,
    [Prefix]      VARCHAR (7)  CONSTRAINT [DF__FcUsed__Prefix__6292D1DD] DEFAULT ('') NOT NULL,
    [Unit]        VARCHAR (10) CONSTRAINT [DF__FcUsed__Unit__6386F616] DEFAULT ('') NOT NULL,
    [Subunit]     VARCHAR (10) CONSTRAINT [DF__FcUsed__Subunit__647B1A4F] DEFAULT ('') NOT NULL,
    [Thou_sep]    VARCHAR (1)  CONSTRAINT [DF__FcUsed__Thou_sep__656F3E88] DEFAULT ('') NOT NULL,
    [Deci_Sep]    VARCHAR (1)  CONSTRAINT [DF__FcUsed__Deci_Sep__666362C1] DEFAULT ('') NOT NULL,
    [Deci_no]     NUMERIC (2)  CONSTRAINT [DF__FcUsed__Deci_no__675786FA] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_FcUsed] PRIMARY KEY CLUSTERED ([FcUsed_Uniq] ASC)
);

