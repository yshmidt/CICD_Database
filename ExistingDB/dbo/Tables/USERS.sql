﻿CREATE TABLE [dbo].[USERS] (
    [USERID]            CHAR (8)         CONSTRAINT [DF__USERS__USERID__6E8210C8] DEFAULT ('') NOT NULL,
    [PASSWORD]          CHAR (10)        CONSTRAINT [DF__USERS__PASSWORD__6F763501] DEFAULT ('') NOT NULL,
    [NAME]              CHAR (15)        CONSTRAINT [DF__USERS__NAME__706A593A] DEFAULT ('') NOT NULL,
    [FIRSTNAME]         CHAR (15)        CONSTRAINT [DF__USERS__FIRSTNAME__715E7D73] DEFAULT ('') NOT NULL,
    [MIDNAME]           CHAR (15)        CONSTRAINT [DF__USERS__MIDNAME__7252A1AC] DEFAULT ('') NOT NULL,
    [INITIALS]          CHAR (8)         CONSTRAINT [DF__USERS__INITIALS__7346C5E5] DEFAULT ('') NULL,
    [DEPT_ID]           CHAR (4)         CONSTRAINT [DF__USERS__DEPT_ID__743AEA1E] DEFAULT ('') NOT NULL,
    [WORKCENTER]        CHAR (25)        CONSTRAINT [DF__USERS__WORKCENTE__752F0E57] DEFAULT ('') NOT NULL,
    [DEPARTMENT]        CHAR (25)        CONSTRAINT [DF__USERS__DEPARTMEN__76233290] DEFAULT ('') NOT NULL,
    [SUPERVISOR]        BIT              CONSTRAINT [DF__USERS__SUPERVISO__771756C9] DEFAULT ((0)) NOT NULL,
    [SKIPWC]            BIT              CONSTRAINT [DF__USERS__SKIPWC__780B7B02] DEFAULT ((0)) NOT NULL,
    [CRDMOAPPRV]        BIT              CONSTRAINT [DF__USERS__CRDMOAPPR__78FF9F3B] DEFAULT ((0)) NOT NULL,
    [ISSUNONAVL]        BIT              CONSTRAINT [DF__USERS__ISSUNONAV__79F3C374] DEFAULT ((0)) NOT NULL,
    [SHIFT_NO]          NUMERIC (3)      CONSTRAINT [DF__USERS__SHIFT_NO__7AE7E7AD] DEFAULT ((0)) NOT NULL,
    [EXEMPT]            BIT              CONSTRAINT [DF__USERS__EXEMPT__7BDC0BE6] DEFAULT ((0)) NOT NULL,
    [RECOVERAGE]        BIT              CONSTRAINT [DF__USERS__RECOVERAG__7CD0301F] DEFAULT ((0)) NOT NULL,
    [SHIPPEDREV]        BIT              CONSTRAINT [DF__USERS__SHIPPEDRE__7DC45458] DEFAULT ((0)) NOT NULL,
    [UNIQ_USER]         CHAR (10)        CONSTRAINT [DF__USERS__UNIQ_USER__7EB87891] DEFAULT ('') NOT NULL,
    [GLDIVNO]           CHAR (2)         CONSTRAINT [DF__USERS__GLDIVNO__7FAC9CCA] DEFAULT ('') NOT NULL,
    [UPDPHYINVT]        BIT              CONSTRAINT [DF__USERS__UPDPHYINV__00A0C103] DEFAULT ((0)) NOT NULL,
    [CHGSTDCOST]        BIT              CONSTRAINT [DF__USERS__CHGSTDCOS__0194E53C] DEFAULT ((0)) NOT NULL,
    [XFERTOINVT]        BIT              CONSTRAINT [DF__USERS__XFERTOINV__02890975] DEFAULT ((0)) NOT NULL,
    [SALETRGR]          BIT              CONSTRAINT [DF__USERS__SALETRGR__037D2DAE] DEFAULT ((0)) NOT NULL,
    [PRODTRGR]          BIT              CONSTRAINT [DF__USERS__PRODTRGR__047151E7] DEFAULT ((0)) NOT NULL,
    [ACCTTRGR]          BIT              CONSTRAINT [DF__USERS__ACCTTRGR__05657620] DEFAULT ((0)) NOT NULL,
    [MATLTRGR]          BIT              CONSTRAINT [DF__USERS__MATLTRGR__06599A59] DEFAULT ((0)) NOT NULL,
    [QUALTRGR]          BIT              CONSTRAINT [DF__USERS__QUALTRGR__074DBE92] DEFAULT ((0)) NOT NULL,
    [QTTRANSFER]        BIT              CONSTRAINT [DF__USERS__QTTRANSFE__0841E2CB] DEFAULT ((0)) NOT NULL,
    [PRTPHYINVT]        BIT              CONSTRAINT [DF__USERS__PRTPHYINV__09360704] DEFAULT ((0)) NOT NULL,
    [MAXPASSWC]         BIT              CONSTRAINT [DF__USERS__MAXPASSWC__0A2A2B3D] DEFAULT ((0)) NOT NULL,
    [HOMESCREEN]        CHAR (8)         CONSTRAINT [DF__USERS__HOMESCREE__0B1E4F76] DEFAULT ('') NOT NULL,
    [HOMEAPP]           CHAR (20)        CONSTRAINT [DF__USERS__HOMEAPP__0C1273AF] DEFAULT ('') NOT NULL,
    [EDTSQCWONO]        BIT              CONSTRAINT [DF__USERS__EDTSQCWON__0D0697E8] DEFAULT ((0)) NOT NULL,
    [CHGWKSTWC]         BIT              CONSTRAINT [DF__USERS__CHGWKSTWC__0DFABC21] DEFAULT ((0)) NOT NULL,
    [EMAILADDRESS]      CHAR (50)        CONSTRAINT [DF__USERS__EMAILADDR__0EEEE05A] DEFAULT ('') NOT NULL,
    [LCHPASSWORDNEXT]   BIT              CONSTRAINT [DF__USERS__LCHPASSWO__1B54B73F] DEFAULT ((0)) NOT NULL,
    [LCANNOTCHPASSWORD] BIT              CONSTRAINT [DF__USERS__LCANNOTCH__1C48DB78] DEFAULT ((0)) NOT NULL,
    [LPASSWORDNEVEREXP] BIT              CONSTRAINT [DF__USERS__LPASSWORD__1D3CFFB1] DEFAULT ((0)) NOT NULL,
    [NPASSWORDEXPIN]    INT              CONSTRAINT [DF__USERS__NPASSWORD__1E3123EA] DEFAULT ((0)) NOT NULL,
    [TPASSWORDENETERED] SMALLDATETIME    NULL,
    [LASS]              BIT              CONSTRAINT [DF__USERS__LASS__1F254823] DEFAULT ((0)) NOT NULL,
    [euserid]           VARBINARY (64)   NULL,
    [epassword]         VARBINARY (64)   NULL,
    [celo]              VARBINARY (64)   CONSTRAINT [DF_USERS_celo] DEFAULT (CONVERT([varbinary](64),'',(0))) NOT NULL,
    [fk_aspnetUsers]    UNIQUEIDENTIFIER NULL,
    [webauth]           CHAR (10)        NULL,
    CONSTRAINT [USERS_PK] PRIMARY KEY CLUSTERED ([UNIQ_USER] ASC)
);


GO
CREATE NONCLUSTERED INDEX [aspnetuser]
    ON [dbo].[USERS]([fk_aspnetUsers] ASC);


GO
CREATE UNIQUE NONCLUSTERED INDEX [BYUSER]
    ON [dbo].[USERS]([USERID] ASC);


GO
CREATE NONCLUSTERED INDEX [NAME]
    ON [dbo].[USERS]([NAME] ASC);


GO
CREATE NONCLUSTERED INDEX [PASSWORD]
    ON [dbo].[USERS]([PASSWORD] ASC);


GO
CREATE NONCLUSTERED INDEX [WebAuth]
    ON [dbo].[USERS]([webauth] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/14/2009
-- Description:	Run after Users record is deleted
-- =============================================
CREATE TRIGGER [dbo].[Users_Delete]
   ON  dbo.USERS
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRANSACTION 
	DELETE FROM Rights WHERE Rights.fk_uniquser IN (SELECT Uniq_user FROM DELETED)
	DELETE FROM UserOption WHERE UserID IN (SELECT UserID FROM DELETED)
	COMMIT

END