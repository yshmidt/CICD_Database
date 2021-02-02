CREATE TABLE [dbo].[SCRAPREL] (
    [WONO]            CHAR (10)       CONSTRAINT [DF__SCRAPREL__WONO__188D592D] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]        CHAR (10)       CONSTRAINT [DF__SCRAPREL__UNIQ_K__19817D66] DEFAULT ('') NOT NULL,
    [SHRI_GL_NO]      CHAR (13)       CONSTRAINT [DF__SCRAPREL__SHRI_G__1A75A19F] DEFAULT ('') NOT NULL,
    [WIP_GL_NBR]      CHAR (13)       CONSTRAINT [DF__SCRAPREL__WIP_GL__1B69C5D8] DEFAULT ('') NOT NULL,
    [QTYTRANSF]       NUMERIC (12, 2) CONSTRAINT [DF__SCRAPREL__QTYTRA__1C5DEA11] DEFAULT ((0)) NOT NULL,
    [STDCOST]         NUMERIC (13, 5) CONSTRAINT [DF__SCRAPREL__STDCOS__1D520E4A] DEFAULT ((0)) NOT NULL,
    [INITIALS]        CHAR (8)        CONSTRAINT [DF__SCRAPREL__INITIA__1E463283] DEFAULT ('') NULL,
    [DATETIME]        SMALLDATETIME   NULL,
    [TRANS_NO]        CHAR (10)       CONSTRAINT [DF__SCRAPREL__TRANS___21229F2E] DEFAULT ('') NOT NULL,
    [IS_REL_GL]       BIT             CONSTRAINT [DF__SCRAPREL__IS_REL__2216C367] DEFAULT ((0)) NOT NULL,
    [STDCOSTPR]       NUMERIC (13, 5) CONSTRAINT [DF__SCRAPREL__STDCOS__2A3A3578] DEFAULT ((0)) NOT NULL,
    [PRFCUSED_UNIQ]   CHAR (10)       CONSTRAINT [DF__SCRAPREL__PRFCUS__3635F809] DEFAULT ('') NOT NULL,
    [FUNCFCUSED_UNIQ] CHAR (10)       CONSTRAINT [DF__SCRAPREL__FUNCFC__372A1C42] DEFAULT ('') NOT NULL,
    CONSTRAINT [SCRAPREL_PK] PRIMARY KEY CLUSTERED ([TRANS_NO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [DATETIME]
    ON [dbo].[SCRAPREL]([DATETIME] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL]
    ON [dbo].[SCRAPREL]([IS_REL_GL] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[SCRAPREL]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [WONO]
    ON [dbo].[SCRAPREL]([WONO] ASC);


GO
CREATE NONCLUSTERED INDEX [WONODT]
    ON [dbo].[SCRAPREL]([WONO] ASC, [DATETIME] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/29/2012
-- Description:	Mark as released if QtyTransf*stdcost=0.00
-- 01/12/17 VL added to update PRFcused_uniq and FuncFcused_uniq 
-- 04/17/17 VL added to update functional currency fields
-- =============================================
CREATE TRIGGER [dbo].[ScrapRel_Insert]
   ON  [dbo].[SCRAPREL]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	BEGIN TRANSACTION
	--UPDATE Scraprel SET IS_REL_GL = CASE WHEN I.QTYTRANSF*I.STDCOST =0.00 THEN 1 ELSE ScrapRel.IS_REL_GL END FROM inserted I WHERE I.TRANS_NO=SCRAPREL.TRANS_NO   
	-- 04/17/17 VL added functional currency code
	UPDATE Scraprel SET IS_REL_GL = CASE WHEN I.QTYTRANSF*I.STDCOST =0.00 THEN 1 ELSE ScrapRel.IS_REL_GL END,
						STDCOSTPR = Inventor.STDCOSTPR,
						PRFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END,
						FuncFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END	
		 FROM inserted I, Inventor WHERE I.Uniq_key=Inventor.UNIQ_KEY AND I.TRANS_NO=SCRAPREL.TRANS_NO   

	COMMIT
END