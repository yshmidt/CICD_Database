CREATE TABLE [dbo].[AuditFyDtl] (
    [fk_fydtluniq] UNIQUEIDENTIFIER NULL,
    [fk_fy_uniq]   CHAR (10)        CONSTRAINT [DF_AuditFyDtl_fk_fy_uniq] DEFAULT ('') NOT NULL,
    [auditfydtluk] INT              IDENTITY (1, 1) NOT NULL,
    [userid]       NVARCHAR (200)   CONSTRAINT [DF_AuditFyDtl_userid] DEFAULT ('') NOT NULL,
    [changetype]   CHAR (1)         CONSTRAINT [DF_AuditFyDtl_changetype] DEFAULT ('') NOT NULL,
    [changedate]   SMALLDATETIME    CONSTRAINT [DF_AuditFyDtl_changedate] DEFAULT (getdate()) NOT NULL,
    [changetext]   TEXT             CONSTRAINT [DF_AuditFyDtl_changetext] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_AuditFyDtl] PRIMARY KEY CLUSTERED ([auditfydtluk] ASC),
    CONSTRAINT [CK_AuditFyDtl_Changetype] CHECK ([changetype]='I' OR [changetype]='D' OR [changetype]='U')
);

