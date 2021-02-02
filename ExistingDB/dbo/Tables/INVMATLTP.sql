﻿CREATE TABLE [dbo].[INVMATLTP] (
    [UQINVMATTP]      CHAR (10)   CONSTRAINT [DF__INVMATLTP__UQINV__39D87308] DEFAULT ('') NOT NULL,
    [INVMATLTYPE]     CHAR (10)   CONSTRAINT [DF__INVMATLTP__INVMA__3ACC9741] DEFAULT ('') NOT NULL,
    [INVMATLTYPEDESC] CHAR (30)   CONSTRAINT [DF__INVMATLTP__INVMA__3BC0BB7A] DEFAULT ('') NOT NULL,
    [CHECKORDER]      NUMERIC (3) CONSTRAINT [DF__INVMATLTP__CHECK__3CB4DFB3] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [INVMATLTP_PK] PRIMARY KEY CLUSTERED ([UQINVMATTP] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CHECKORDER]
    ON [dbo].[INVMATLTP]([CHECKORDER] ASC);


GO
CREATE NONCLUSTERED INDEX [INVMATLTP]
    ON [dbo].[INVMATLTP]([INVMATLTYPE] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 09/09/2009
-- Description:	Run after InvMatlTp record is deleted
-- =============================================
CREATE TRIGGER [dbo].[InvMatlTp_Delete]
   ON  [dbo].[InvMatlTp]
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRANSACTION 
	DELETE FROM MatTpLogic WHERE UqInvMatTp IN (SELECT UqInvMatTp FROM DELETED)
	COMMIT

END
