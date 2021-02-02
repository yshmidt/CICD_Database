CREATE TABLE [dbo].[AUDITFISCALYRS] (
    [fk_fy_uniq]       CHAR (10)      CONSTRAINT [DF_AUDITFISCALYRS_fk_fy_uniq] DEFAULT ('') NOT NULL,
    [auditfiscalyrsuk] INT            IDENTITY (1, 1) NOT NULL,
    [userid]           NVARCHAR (200) CONSTRAINT [DF_AUDITFISCALYRS_userid] DEFAULT ('') NOT NULL,
    [changetype]       CHAR (1)       NOT NULL,
    [changedate]       SMALLDATETIME  CONSTRAINT [DF_AUDITFISCALYRS_changedate] DEFAULT (getdate()) NOT NULL,
    [changetext]       TEXT           CONSTRAINT [DF_AUDITFISCALYRS_changetext] DEFAULT ('') NOT NULL,
    CONSTRAINT [AUDITFISCALYRS_PK] PRIMARY KEY CLUSTERED ([auditfiscalyrsuk] ASC),
    CONSTRAINT [CK_AUDITFISCALYRS_changetype] CHECK ([changetype]='I' OR [changetype]='D' OR [changetype]='U')
);

