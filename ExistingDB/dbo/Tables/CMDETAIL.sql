CREATE TABLE [dbo].[CMDETAIL] (
    [TRANS_NO]    NUMERIC (7)    CONSTRAINT [DF__CMDETAIL__TRANS___06B7F65E] DEFAULT ((0)) NOT NULL,
    [CMEMONO]     CHAR (10)      CONSTRAINT [DF__CMDETAIL__CMEMON__07AC1A97] DEFAULT ('') NOT NULL,
    [PACKLISTNO]  CHAR (10)      CONSTRAINT [DF__CMDETAIL__PACKLI__08A03ED0] DEFAULT ('') NOT NULL,
    [UNIQUELN]    CHAR (10)      CONSTRAINT [DF__CMDETAIL__UNIQUE__09946309] DEFAULT ('') NOT NULL,
    [UOFMEAS]     CHAR (4)       CONSTRAINT [DF__CMDETAIL__UOFMEA__0A888742] DEFAULT ('') NOT NULL,
    [CMQTY]       NUMERIC (9, 2) CONSTRAINT [DF__CMDETAIL__CMQTY__0B7CAB7B] DEFAULT ((0)) NOT NULL,
    [IS_RESTOCK]  BIT            CONSTRAINT [DF__CMDETAIL__IS_RES__0C70CFB4] DEFAULT ((0)) NOT NULL,
    [RESTOCKQTY]  NUMERIC (9, 2) CONSTRAINT [DF__CMDETAIL__RESTOC__0D64F3ED] DEFAULT ((0)) NOT NULL,
    [SCRAPQTY]    NUMERIC (9, 2) CONSTRAINT [DF__CMDETAIL__SCRAPQ__0E591826] DEFAULT ((0)) NOT NULL,
    [SHIPPEDQTY]  NUMERIC (9, 2) CONSTRAINT [DF__CMDETAIL__SHIPPE__0F4D3C5F] DEFAULT ((0)) NOT NULL,
    [CMDESCR]     CHAR (45)      CONSTRAINT [DF__CMDETAIL__DESC__10416098] DEFAULT ('') NOT NULL,
    [NOTE]        TEXT           CONSTRAINT [DF__CMDETAIL__NOTE__113584D1] DEFAULT ('') NOT NULL,
    [S_N_PRINT]   NUMERIC (1)    CONSTRAINT [DF__CMDETAIL__S_N_PR__1229A90A] DEFAULT ((0)) NOT NULL,
    [BEGSERNO]    CHAR (10)      CONSTRAINT [DF__CMDETAIL__BEGSER__131DCD43] DEFAULT ('') NOT NULL,
    [ENDSERNO]    CHAR (10)      CONSTRAINT [DF__CMDETAIL__ENDSER__1411F17C] DEFAULT ('') NOT NULL,
    [CERTDONE]    BIT            CONSTRAINT [DF__CMDETAIL__CERTDO__150615B5] DEFAULT ((0)) NOT NULL,
    [INV_LINK]    CHAR (10)      CONSTRAINT [DF__CMDETAIL__INV_LI__15FA39EE] DEFAULT ('') NOT NULL,
    [WONOFLAG]    BIT            CONSTRAINT [DF__CMDETAIL__WONOFL__16EE5E27] DEFAULT ((0)) NOT NULL,
    [CMPRICELNK]  CHAR (10)      CONSTRAINT [DF__CMDETAIL__CMPRIC__17E28260] DEFAULT ('') NOT NULL,
    [WONO]        CHAR (10)      CONSTRAINT [DF__CMDETAIL__WONO__18D6A699] DEFAULT ('') NOT NULL,
    [PLUNIQLNK]   CHAR (10)      CONSTRAINT [DF__CMDETAIL__PLUNIQ__19CACAD2] DEFAULT ('') NOT NULL,
    [cmUnique]    CHAR (10)      CONSTRAINT [DF_CMDETAIL_cmUnique] DEFAULT ('') NOT NULL,
    [lAdjustLine] BIT            CONSTRAINT [DF_CMDETAIL_lAdjustLine] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [CMDETAIL_PK] PRIMARY KEY CLUSTERED ([CMPRICELNK] ASC)
);


GO
CREATE NONCLUSTERED INDEX [CMEMONO]
    ON [dbo].[CMDETAIL]([CMEMONO] ASC);


GO
CREATE NONCLUSTERED INDEX [cmUnique]
    ON [dbo].[CMDETAIL]([cmUnique] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);


GO
CREATE NONCLUSTERED INDEX [INV_LINK]
    ON [dbo].[CMDETAIL]([INV_LINK] ASC);


GO
CREATE NONCLUSTERED INDEX [PACKLISTNO]
    ON [dbo].[CMDETAIL]([PACKLISTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [PKNOULN]
    ON [dbo].[CMDETAIL]([PACKLISTNO] ASC, [UNIQUELN] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQUELN]
    ON [dbo].[CMDETAIL]([UNIQUELN] ASC);


GO
-- =============================================
-- Author:		Vicky Lu
-- Create date: <03/29/11>
-- Description:	<trigger for Cmdetail>
-- =============================================
CREATE TRIGGER [dbo].[Cmdetail_Insert]
   ON  dbo.CMDETAIL
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @lcCmUnique char(10), @lcInvoiceno char(10), @llIs_Rma bit, @lcUniqueln char(10), 
			@lnCmQty numeric(9,2), @lnSoBalance numeric(9,2)
	
    BEGIN TRANSACTION
    -- check if deleted records exists
    SELECT @lcCmUnique = CmUnique, @lcUniqueln = Uniqueln, @lnCmQty = CmQty FROM Inserted
    IF @@ROWCOUNT<>0
	BEGIN		
		SELECT @lcInvoiceno = Invoiceno, @llIs_Rma = Is_Rma
			FROM Cmmain
			WHERE CmUnique = @lcCmUnique
		-- Only update Sodetail if it's from RMA
		IF @@ROWCOUNT<>0 AND @llIs_Rma = 1 AND @lcInvoiceno <> ''
		BEGIN
			SELECT @lnSoBalance = ABS(Balance) 
				FROM Sodetail 
				WHERE Uniqueln = @lcUniqueln
			
			IF @@ROWCOUNT<>0
				BEGIN
					IF @lnCmQty > @lnSoBalance
						BEGIN
							RAISERROR('The RMA quantity has been changed when you modified this record.  Not enough RMA quantity to deduct. Aborting Save transaction.',1,1)
							ROLLBACK TRANSACTION
							RETURN		
						END				
				END
			ELSE
				BEGIN
					-- 11/01/11 VL added next IF to exclude RMA receiving Rounding Adjustment situation
					IF @lcUniqueln <> 'NONE'	-- Created from RMA Receiving Rounding Adjustment
						BEGIN
							RAISERROR('The system can not find associated RMA item. Aborting Save transaction.',1,1)
							ROLLBACK TRANSACTION
							RETURN
						END
				END
		END
	END
	
	COMMIT
END