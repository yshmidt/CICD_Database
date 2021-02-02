CREATE TABLE [dbo].[CONTPRIC] (
    [MFGR_UNIQ]  CHAR (10)       CONSTRAINT [DF__CONTPRIC__MFGR_U__4944D3CA] DEFAULT ('') NOT NULL,
    [PRIC_UNIQ]  CHAR (10)       CONSTRAINT [DF__CONTPRIC__PRIC_U__4A38F803] DEFAULT ('') NOT NULL,
    [QUANTITY]   NUMERIC (10)    CONSTRAINT [DF__CONTPRIC__QUANTI__4B2D1C3C] DEFAULT ((0)) NOT NULL,
    [PRICE]      NUMERIC (13, 5) CONSTRAINT [DF__CONTPRIC__PRICE__4C214075] DEFAULT ((0)) NOT NULL,
    [CONTR_UNIQ] CHAR (10)       CONSTRAINT [DF__CONTPRIC__CONTR___4D1564AE] DEFAULT ('') NOT NULL,
    [PriceFC]    NUMERIC (13, 5) CONSTRAINT [DF__CONTPRIC__PriceF__203A3344] DEFAULT ((0)) NOT NULL,
    [PricePr]    NUMERIC (13, 5) CONSTRAINT [DF_CONTPRIC_PricePr] DEFAULT ((0.00)) NOT NULL,
    CONSTRAINT [CONTPRIC_PK] PRIMARY KEY NONCLUSTERED ([PRIC_UNIQ] ASC),
    CONSTRAINT [FK_CONTPRIC_CONTMPN] FOREIGN KEY ([MFGR_UNIQ]) REFERENCES [dbo].[CONTMFGR] ([MFGR_UNIQ]) ON DELETE CASCADE
);


GO
CREATE CLUSTERED INDEX [QUANTITY]
    ON [dbo].[CONTPRIC]([MFGR_UNIQ] ASC, [QUANTITY] DESC);


GO
CREATE NONCLUSTERED INDEX [CONTR_UNIQ]
    ON [dbo].[CONTPRIC]([CONTR_UNIQ] ASC);


GO
CREATE NONCLUSTERED INDEX [MFGR_UNIQ]
    ON [dbo].[CONTPRIC]([MFGR_UNIQ] ASC);


GO

-- =============================================
-- Author:		<Rajendra K>
-- Create date: <8/18/2017>
-- Description:	<Update columns PriceFC and PricePr from table CONTPRIC when user insert/Update CONTPRIC table>
-- Modification
   -- 09/19/2017 Rajendra K : Removed updating price column from trigger and added directly in insert query
-- =============================================
CREATE TRIGGER [dbo].[CONTPRIC_Insert]
	ON [dbo].[CONTPRIC]
AFTER INSERT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	DECLARE @FCInstalled BIT

	BEGIN TRY
		BEGIN TRANSACTION
		IF NOT EXISTS (select 1 from  CONTPRIC CP inner join Inserted I on  CP.PRIC_UNIQ = I.PRIC_UNIQ)
			BEGIN
				RAISERROR ('Cannot Locate any Records in CONTPRIC Table to update price.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);

			END

	SELECT @FCInstalled = dbo.fn_IsFCInstalled()  --Check for fc setting
		
	IF @FCInstalled=1
	  BEGIN
		  UPDATE CONTPRIC		  		
		  		SET PricePR =  dbo.fn_Convert4FCHC('F',CH.fcused_uniq,CP.PriceFC,CH.prFcUsed_uniq,CH.fchist_key)
					-- 09/19/2017 Rajendra K : Removed updating price column from trigger and added directly in insert query
		  FROM inserted CP INNER JOIN CONTRACT C ON CP.CONTR_UNIQ = C.CONTR_UNIQ 
		  					     INNER JOIN ContractHeader CH ON C.ContractH_unique = CH.ContractH_unique 
		  WHERE CONTPRIC.PRIC_UNIQ = CP.PRIC_UNIQ
	  END	
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
		COMMIT	
END
GO
-- =============================================
-- Author:		<Rajendra K>
-- Create date: <8/18/2017>
-- Description:	<Update columns PriceFC and PricePr from table CONTPRIC when user insert/Update CONTPRIC table>
-- Modification
   -- 09/19/2017 Rajendra K : Removed updating price column from trigger and added directly in update query
-- =============================================
CREATE TRIGGER [dbo].[CONTPRIC_Update]
	ON [dbo].[CONTPRIC]
AFTER UPDATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	DECLARE @FCInstalled BIT

	BEGIN TRY
		BEGIN TRANSACTION
		IF NOT EXISTS (select 1 from  CONTPRIC CP inner join Inserted I on  CP.PRIC_UNIQ = I.PRIC_UNIQ)
			BEGIN
				RAISERROR ('Cannot Locate any Records in CONTPRIC Table to update price.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);

			END

	SELECT @FCInstalled = dbo.fn_IsFCInstalled()  --Check for fc setting
		
	IF @FCInstalled=1
	  BEGIN
		  UPDATE CONTPRIC
		  		 SET PricePR =  dbo.fn_Convert4FCHC('F',CH.fcused_uniq,CP.PriceFC,CH.prFcUsed_uniq,CH.fchist_key)
				 -- 09/19/2017 Rajendra K : Removed updating price column from trigger and added directly in update query
		  FROM inserted CP INNER JOIN CONTRACT C ON CP.CONTR_UNIQ = C.CONTR_UNIQ 
		  				 INNER JOIN ContractHeader CH ON C.ContractH_unique = CH.ContractH_unique 
		  WHERE CONTPRIC.PRIC_UNIQ = CP.PRIC_UNIQ
	  END		 
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
		COMMIT	
END
