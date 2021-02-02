﻿CREATE TABLE [dbo].[CONFGVAR] (
    [UNIQCONF]        CHAR (10)       CONSTRAINT [DF__CONFGVAR__UNIQCO__316D4A39] DEFAULT ('') NOT NULL,
    [WONO]            CHAR (10)       CONSTRAINT [DF__CONFGVAR__WONO__32616E72] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]        CHAR (10)       CONSTRAINT [DF__CONFGVAR__UNIQ_K__335592AB] DEFAULT ('') NOT NULL,
    [CNFG_GL_NB]      CHAR (13)       CONSTRAINT [DF__CONFGVAR__CNFG_G__3449B6E4] DEFAULT ('') NOT NULL,
    [WIP_GL_NBR]      CHAR (13)       CONSTRAINT [DF__CONFGVAR__WIP_GL__353DDB1D] DEFAULT ('') NOT NULL,
    [QTYTRANSF]       NUMERIC (12, 2) CONSTRAINT [DF__CONFGVAR__QTYTRA__3631FF56] DEFAULT ((0)) NOT NULL,
    [STDCOST]         NUMERIC (13, 5) CONSTRAINT [DF__CONFGVAR__STDCOS__3726238F] DEFAULT ((0)) NOT NULL,
    [WIPCOST]         NUMERIC (13, 5) CONSTRAINT [DF__CONFGVAR__WIPCOS__381A47C8] DEFAULT ((0)) NOT NULL,
    [VARIANCE]        NUMERIC (13, 5) CONSTRAINT [DF__CONFGVAR__VARIAN__390E6C01] DEFAULT ((0)) NOT NULL,
    [TOTALVAR]        NUMERIC (20, 5) CONSTRAINT [DF__CONFGVAR__TOTALV__3A02903A] DEFAULT ((0)) NULL,
    [DATETIME]        SMALLDATETIME   CONSTRAINT [DF_CONFGVAR_DATETIME] DEFAULT (getdate()) NULL,
    [INVTXFER_N]      CHAR (10)       CONSTRAINT [DF__CONFGVAR__INVTXF__3BEAD8AC] DEFAULT ('') NOT NULL,
    [TRANSFTBLE]      CHAR (3)        CONSTRAINT [DF__CONFGVAR__TRANSF__3CDEFCE5] DEFAULT ('') NOT NULL,
    [IS_REL_GL]       BIT             CONSTRAINT [DF__CONFGVAR__IS_REL__3DD3211E] DEFAULT ((0)) NOT NULL,
    [CNFGGLLINK]      CHAR (10)       CONSTRAINT [DF__CONFGVAR__CNFGGL__3EC74557] DEFAULT ('') NOT NULL,
    [VARTYPE]         CHAR (5)        CONSTRAINT [DF__CONFGVAR__VARTYP__3FBB6990] DEFAULT ('') NOT NULL,
    [PONUM]           CHAR (15)       CONSTRAINT [DF__CONFGVAR__PONUM__40AF8DC9] DEFAULT ('') NOT NULL,
    [STDCOSTPR]       NUMERIC (13, 5) CONSTRAINT [DF__CONFGVAR__STDCOS__2FF30ECE] DEFAULT ((0)) NOT NULL,
    [WIPCOSTPR]       NUMERIC (13, 5) CONSTRAINT [DF__CONFGVAR__WIPCOS__2728BEA3] DEFAULT ((0)) NOT NULL,
    [VARIANCEPR]      NUMERIC (13, 5) CONSTRAINT [DF__CONFGVAR__VARIAN__281CE2DC] DEFAULT ((0)) NOT NULL,
    [TOTALVARPR]      NUMERIC (13, 5) CONSTRAINT [DF__CONFGVAR__TOTALV__29110715] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)       CONSTRAINT [DF__CONFGVAR__PRFCUS__213ADB23] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__CONFGVAR__FUNCFC__222EFF5C] DEFAULT ('') NOT NULL,
    CONSTRAINT [CONFGVAR_PK] PRIMARY KEY CLUSTERED ([UNIQCONF] ASC)
);


GO
CREATE NONCLUSTERED INDEX [confgdate]
    ON [dbo].[CONFGVAR]([DATETIME] ASC);


GO
CREATE NONCLUSTERED INDEX [rectype]
    ON [dbo].[CONFGVAR]([VARTYPE] ASC);


GO
CREATE NONCLUSTERED INDEX [released]
    ON [dbo].[CONFGVAR]([IS_REL_GL] ASC);


GO
CREATE NONCLUSTERED INDEX [uniq_key]
    ON [dbo].[CONFGVAR]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [WONO]
    ON [dbo].[CONFGVAR]([WONO] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: 01/31/2017
-- Description:	Update PRFcused_uniq and FuncFcused_uniq if FC is installed
-- =============================================
CREATE TRIGGER [dbo].[CONFGVAR_INSERT]
   ON  [dbo].[CONFGVAR] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	DECLARE @ErrorMessage NVARCHAR(max);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;    
	
	-- Insert statements for trigger here
	IF dbo.fn_IsFCInstalled() = 1
	
	UPDATE CONFGVAR SET 
			PRFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END,
			FuncFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END
		FROM inserted I INNER JOIN Confgvar on I.UniqConf=Confgvar.UniqConf

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
		ROLLBACK
		SELECT @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
              @ErrorSeverity, -- Severity.
              @ErrorState -- State.
              );
	END CATCH
	IF @@TRANCOUNT>0
		COMMIT TRANSACTION
END