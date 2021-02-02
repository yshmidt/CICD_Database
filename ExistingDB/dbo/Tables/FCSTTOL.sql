﻿CREATE TABLE [dbo].[FCSTTOL] (
    [CCUSTOMER]        CHAR (10)     CONSTRAINT [DF__FCSTTOL__CCUSTOM__3FA65AF7] DEFAULT ('') NOT NULL,
    [NP1HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP1HI] DEFAULT ((0)) NOT NULL,
    [NP1LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP1LO] DEFAULT ((0)) NOT NULL,
    [NP2HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP2HI] DEFAULT ((0)) NOT NULL,
    [NP2LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP2LO] DEFAULT ((0)) NOT NULL,
    [NP3HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP3HI] DEFAULT ((0)) NOT NULL,
    [NP3LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP3LO] DEFAULT ((0)) NOT NULL,
    [NP4HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP4HI] DEFAULT ((0)) NOT NULL,
    [NP4LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP4LO] DEFAULT ((0)) NOT NULL,
    [NP5HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP5HI] DEFAULT ((0)) NOT NULL,
    [NP5LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP5LO] DEFAULT ((0)) NOT NULL,
    [NP6HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP6HI] DEFAULT ((0)) NOT NULL,
    [NP6LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP6LO] DEFAULT ((0)) NOT NULL,
    [NP7HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP7HI] DEFAULT ((0)) NOT NULL,
    [NP7LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP7LO] DEFAULT ((0)) NOT NULL,
    [NP8HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP8HI] DEFAULT ((0)) NOT NULL,
    [NP8LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP8LO] DEFAULT ((0)) NOT NULL,
    [NP9HI]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP9HI] DEFAULT ((0)) NOT NULL,
    [NP9LO]            NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP9LO] DEFAULT ((0)) NOT NULL,
    [NP10HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP10HI] DEFAULT ((0)) NOT NULL,
    [NP10LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP10LO] DEFAULT ((0)) NOT NULL,
    [NP11HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP11HI] DEFAULT ((0)) NOT NULL,
    [NP11LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP11LO] DEFAULT ((0)) NOT NULL,
    [NP12HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP12HI] DEFAULT ((0)) NOT NULL,
    [NP12LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP12LO] DEFAULT ((0)) NOT NULL,
    [NP13HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP13HI] DEFAULT ((0)) NOT NULL,
    [NP13LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP13LO] DEFAULT ((0)) NOT NULL,
    [NP14HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP14HI] DEFAULT ((0)) NOT NULL,
    [NP14LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP14LO] DEFAULT ((0)) NOT NULL,
    [NP15HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP15HI] DEFAULT ((0)) NOT NULL,
    [NP15LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP15LO] DEFAULT ((0)) NOT NULL,
    [NP16HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP16HI] DEFAULT ((0)) NOT NULL,
    [NP16LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP16LO] DEFAULT ((0)) NOT NULL,
    [NP17HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP17HI] DEFAULT ((0)) NOT NULL,
    [NP17LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP17LO] DEFAULT ((0)) NOT NULL,
    [NP18HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP18HI] DEFAULT ((0)) NOT NULL,
    [NP18LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP18LO] DEFAULT ((0)) NOT NULL,
    [NP19HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP19HI] DEFAULT ((0)) NOT NULL,
    [NP19LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP19LO] DEFAULT ((0)) NOT NULL,
    [NP20HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP20HI] DEFAULT ((0)) NOT NULL,
    [NP20LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP20LO] DEFAULT ((0)) NOT NULL,
    [NP21HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP21HI] DEFAULT ((0)) NOT NULL,
    [NP21LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP21LO] DEFAULT ((0)) NOT NULL,
    [NP22HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP22HI] DEFAULT ((0)) NOT NULL,
    [NP22LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP22LO] DEFAULT ((0)) NOT NULL,
    [NP23HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP23HI] DEFAULT ((0)) NOT NULL,
    [NP23LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP23LO] DEFAULT ((0)) NOT NULL,
    [NP24HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP24HI] DEFAULT ((0)) NOT NULL,
    [NP24LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP24LO] DEFAULT ((0)) NOT NULL,
    [LUSECPN]          BIT           CONSTRAINT [DF__FCSTTOL__LUSECPN__6E6149E0] DEFAULT ((0)) NOT NULL,
    [LDELDRPDPART]     BIT           CONSTRAINT [DF__FCSTTOL__LDELDRP__6F556E19] DEFAULT ((0)) NOT NULL,
    [TCARRYRESETDT]    SMALLDATETIME NULL,
    [NP25HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP25HI] DEFAULT ((0)) NOT NULL,
    [NP25LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP25LO] DEFAULT ((0)) NOT NULL,
    [NP26HI]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP26HI] DEFAULT ((0)) NOT NULL,
    [NP26LO]           NUMERIC (7)   CONSTRAINT [DF_FCSTTOL_NP26LO] DEFAULT ((0)) NOT NULL,
    [LUSEFORECASTLINE] BIT           CONSTRAINT [DF_FCSTTOL_LUSEFORECASTLINE] DEFAULT ((0)) NOT NULL,
    [LCURRENTONLY]     BIT           CONSTRAINT [DF_FCSTTOL_LCURRENTONLY] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [FCSTTOL_PK] PRIMARY KEY CLUSTERED ([CCUSTOMER] ASC)
);
