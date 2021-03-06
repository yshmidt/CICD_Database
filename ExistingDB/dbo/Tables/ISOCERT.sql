﻿CREATE TABLE [dbo].[ISOCERT] (
    [CERTIFIER]  CHAR (25) CONSTRAINT [DF_ISOCERT_CERTIFIER] DEFAULT ('') NOT NULL,
    [CERT_ADD1]  CHAR (25) CONSTRAINT [DF_ISOCERT_CERT_ADD1] DEFAULT ('') NOT NULL,
    [CERT_ADD2]  CHAR (25) CONSTRAINT [DF_ISOCERT_CERT_ADD2] DEFAULT ('') NOT NULL,
    [CERT_ADD3]  CHAR (25) CONSTRAINT [DF_ISOCERT_CERT_ADD3] DEFAULT ('') NOT NULL,
    [CERT_PHONE] CHAR (16) CONSTRAINT [DF_ISOCERT_CERT_PHONE] DEFAULT ('') NOT NULL,
    [CERT_FAX]   CHAR (16) CONSTRAINT [DF_ISOCERT_CERT_FAX] DEFAULT ('') NOT NULL,
    [CERT_CONT1] CHAR (16) CONSTRAINT [DF_ISOCERT_CERT_CONT1] DEFAULT ('') NOT NULL,
    [CERT_CONT2] CHAR (16) CONSTRAINT [DF_ISOCERT_CERT_CONT2] DEFAULT ('') NOT NULL,
    [CERT_CONT3] CHAR (16) CONSTRAINT [DF_ISOCERT_CERT_CONT3] DEFAULT ('') NOT NULL,
    [CERT_CONT4] CHAR (16) CONSTRAINT [DF_ISOCERT_CERT_CONT4] DEFAULT ('') NOT NULL,
    [CON_PHONE1] CHAR (16) CONSTRAINT [DF_ISOCERT_CON_PHONE1] DEFAULT ('') NOT NULL,
    [CON_PHONE2] CHAR (16) CONSTRAINT [DF_ISOCERT_CON_PHONE2] DEFAULT ('') NOT NULL,
    [CON_PHONE3] CHAR (16) CONSTRAINT [DF_ISOCERT_CON_PHONE3] DEFAULT ('') NOT NULL,
    [CON_PHONE4] CHAR (16) CONSTRAINT [DF_ISOCERT_CON_PHONE4] DEFAULT ('') NOT NULL,
    [CON_FAX1]   CHAR (16) CONSTRAINT [DF_ISOCERT_CON_FAX1] DEFAULT ('') NOT NULL,
    [CON_FAX2]   CHAR (16) CONSTRAINT [DF_ISOCERT_CON_FAX2] DEFAULT ('') NOT NULL,
    [CON_FAX3]   CHAR (16) CONSTRAINT [DF_ISOCERT_CON_FAX3] DEFAULT ('') NOT NULL,
    [CON_FAX4]   CHAR (16) CONSTRAINT [DF_ISOCERT_CON_FAX4] DEFAULT ('') NOT NULL,
    [TITLE1]     CHAR (16) CONSTRAINT [DF_ISOCERT_TITLE1] DEFAULT ('') NOT NULL,
    [TITLE2]     CHAR (16) CONSTRAINT [DF_ISOCERT_TITLE2] DEFAULT ('') NOT NULL,
    [TITLE3]     CHAR (16) CONSTRAINT [DF_ISOCERT_TITLE3] DEFAULT ('') NOT NULL,
    [TITLE4]     CHAR (16) CONSTRAINT [DF_ISOCERT_TITLE4] DEFAULT ('') NOT NULL,
    [UNIQUENUM]  INT       IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [ISOCERT_PK] PRIMARY KEY CLUSTERED ([UNIQUENUM] ASC)
);

