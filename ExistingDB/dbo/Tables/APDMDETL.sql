CREATE TABLE [dbo].[APDMDETL] (
    [UNIQDMDETL]   CHAR (10)       CONSTRAINT [DF__APDMDETL__UNIQDM__7FEAFD3E] DEFAULT ('') NOT NULL,
    [UNIQDMHEAD]   CHAR (10)       CONSTRAINT [DF__APDMDETL__UNIQDM__00DF2177] DEFAULT ('') NOT NULL,
    [ITEM_NO]      INT             CONSTRAINT [DF__APDMDETL__ITEM_N__04AFB25B] DEFAULT ((0)) NOT NULL,
    [ITEM_DESC]    CHAR (25)       CONSTRAINT [DF__APDMDETL__ITEM_D__05A3D694] DEFAULT ('') NOT NULL,
    [IS_TAX]       BIT             CONSTRAINT [DF__APDMDETL__IS_TAX__0697FACD] DEFAULT ((0)) NOT NULL,
    [TAX_PCT]      NUMERIC (8, 4)  CONSTRAINT [DF__APDMDETL__TAX_PC__078C1F06] DEFAULT ((0)) NOT NULL,
    [QTY_EACH]     NUMERIC (9, 2)  CONSTRAINT [DF__APDMDETL__QTY_EA__0880433F] DEFAULT ((0)) NOT NULL,
    [PRICE_EACH]   NUMERIC (13, 5) CONSTRAINT [DF__APDMDETL__PRICE___09746778] DEFAULT ((0)) NOT NULL,
    [ITEM_TOTAL]   NUMERIC (10, 2) CONSTRAINT [DF__APDMDETL__ITEM_T__0A688BB1] DEFAULT ((0)) NOT NULL,
    [GL_NBR]       CHAR (13)       CONSTRAINT [DF__APDMDETL__GL_NBR__0B5CAFEA] DEFAULT ('') NOT NULL,
    [ITEM_NOTE]    TEXT            CONSTRAINT [DF__APDMDETL__ITEM_N__0C50D423] DEFAULT ('') NOT NULL,
    [UNIQAPHEAD]   CHAR (10)       CONSTRAINT [DF__APDMDETL__UNIQAP__0D44F85C] DEFAULT ('') NOT NULL,
    [UNIQAPDETL]   CHAR (10)       CONSTRAINT [DF_APDMDETL_UNIQAPDETL] DEFAULT ('') NOT NULL,
    [PRICE_EACHFC] NUMERIC (13, 5) CONSTRAINT [DF__APDMDETL__PRICE___2EB33B24] DEFAULT ((0)) NOT NULL,
    [ITEM_TOTALFC] NUMERIC (10, 2) CONSTRAINT [DF__APDMDETL__ITEM_T__2FA75F5D] DEFAULT ((0)) NOT NULL,
    [PRICE_EACHPR] NUMERIC (13, 5) CONSTRAINT [DF__APDMDETL__PRICE___38534AA5] DEFAULT ((0)) NOT NULL,
    [ITEM_TOTALPR] NUMERIC (10, 2) CONSTRAINT [DF__APDMDETL__ITEM_T__39476EDE] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [APDMDETL_PK] PRIMARY KEY CLUSTERED ([UNIQDMDETL] ASC)
);


GO
CREATE NONCLUSTERED INDEX [UNIQAPDETL]
    ON [dbo].[APDMDETL]([UNIQDMDETL] ASC) WITH (ALLOW_PAGE_LOCKS = OFF);


GO
CREATE NONCLUSTERED INDEX [UNIQDMHEAD]
    ON [dbo].[APDMDETL]([UNIQDMHEAD] ASC);


GO
-- =============================================
-- Author:		Vicky Lu	
-- Create date: 12/06/16
-- Description:	After Delete trigger for the Apdmdetl table
-- =============================================
CREATE TRIGGER  [dbo].[Apdmdetl_Delete]
   ON  [dbo].[Apdmdetl] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION 
	DELETE FROM ApdmdetlTax WHERE Uniqdmdetl IN (SELECT Uniqdmdetl FROM DELETED)
	COMMIT

END
GO
-- =============================================
-- Author:		Satish B	
-- Create date: 04/06/2017
-- Description:	Update DMEMO Table > DMTotal column (calculated DM total from combined from the apdmdetl table SUM of qty_each*price_each-ndiscAmt) 
                --After Insert Into APDMDETL Table
-- Modified : Satish B : 09/04/2017 : Comment code which was used to update debit memo tables 
--          : Satish B : 09/04/2017 : Change the logic of updating the Dmemos table and foreign currency fields population
--          : Satish B : 09/04/2017 : Comment code which was used to update debit memo tables 
--			: Satish B : 05/04/2018 : Declare @ErrorMessage,@ErrorSeverity,@ErrorState for error handling
--			: Satish B : 05/04/2018 : Implement BEGIN TRY and BEGIN CATCH for error handling
--			: Satish B : 05/04/2018 : Check rowcount
--			: Satish B : 05/16/2018 : Ne need of dmFCInstalled variable
--			: Satish B : 05/16/2018 : Optimize the code for check fn_IsFCInstalled or not (Comment extra code and check directely in if condition)
--- 12/13/2019 YS still using DM in the desktop- disable the code for now
-- =============================================
CREATE TRIGGER  [dbo].[Apdmdetl_Insert]
   ON  [dbo].[APDMDETL] 
   AFTER INSERT
AS 
BEGIN
	
	SET NOCOUNT ON;
	IF (0=1)
	BEGIN
	--Satish B : 05/04/2018 : Declare @ErrorMessage,@ErrorSeverity,@ErrorState for error handling
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;
	BEGIN TRANSACTION 
	-- Satish B : 09/04/2017 : Comment code which was used to update debit memo tables 
		--DECLARE @lcDmTotal numeric(10,2);
		--DECLARE @lcQtyAndPrice numeric(13,5);
			
		--SET @lcDmTotal=(SELECT DMTOTAL FROM DMEMOS WHERE UNIQDMHEAD= (SELECT UNIQDMHEAD FROM Inserted))
		--SET @lcQtyAndPrice=((SELECT QTY_EACH * PRICE_EACH FROM Inserted)) 
		--IF @lcDmTotal<>0
		--	BEGIN
		--		UPDATE DMEMOS
		--        SET DMTOTAL=DMTOTAL+@lcQtyAndPrice 
		--		WHERE UNIQDMHEAD= (SELECT UNIQDMHEAD FROM Inserted);
		--	END
       --     ELSE
	   --      BEGIN
		--	   UPDATE DMEMOS
		--	   SET DMTOTAL=(@lcQtyAndPrice) - (SELECT NDISCAMT FROM DMEMOS WHERE UNIQDMHEAD= (SELECT UNIQDMHEAD FROM Inserted))
		--	   WHERE UNIQDMHEAD= (SELECT UNIQDMHEAD FROM Inserted) 
		--   END

		-- Satish B : 09/04/2017 : Change the logic of updating the Dmemos table and foreign currency fields population
		-- Satish B : 05/16/2018 : Ne need of dmFCInstalled variable 
		--DECLARE @dmFCInstalled bit
		SELECT SUM(I.QTY_EACH * I.PRICE_EACH) AS TotalPrice
				  ,I.UNIQDMHEAD
				  ,SI.Fcused_Uniq
		INTO #TEMP
		FROM inserted I INNER JOIN DMEMOS DM ON DM.UNIQDMHEAD = I.UNIQDMHEAD
		LEFT JOIN SUPINFO SI ON DM.UNIQSUPNO = SI.UNIQSUPNO
		GROUP BY I.UNIQDMHEAD,SI.Fcused_Uniq
		-- Udpate Dmemos for DMTOTAL 
		--Satish B : 05/04/2018 : Implement BEGIN TRY and BEGIN CATCH for error handling
		BEGIN TRY
			UPDATE DMEMOS
			SET DMTOTAL = CASE WHEN DMTOTAL <> 0 THEN  DMTOTAL + TotalPrice ELSE TotalPrice - DM.NDISCAMT END
				,FCUSED_UNIQ=SI.Fcused_Uniq
				,FUNCFCUSED_UNIQ=(SELECT CAST(dbo.fn_GetFunctionalCurrency() AS Char(10)))
				,PRFCUSED_UNIQ=(SELECT CAST(dbo.fn_GetPresentationCurrency() AS Char(10)))
			FROM #TEMP I INNER JOIN DMEMOS DM ON DM.UNIQDMHEAD = I.UNIQDMHEAD
			LEFT JOIN SUPINFO SI ON DM.UNIQSUPNO = SI.UNIQSUPNO
		END TRY	
		BEGIN CATCH
			IF @@TRANCOUNT <>0
				ROLLBACK;
					SELECT @ErrorMessage = ERROR_MESSAGE(),
						   @ErrorSeverity = ERROR_SEVERITY(),
						   @ErrorState = ERROR_STATE();
					RAISERROR (@ErrorMessage, -- Message text.
							   @ErrorSeverity, -- Severity.
							   @ErrorState -- State.
							   );
		END CATCH	
		--Update fC column values
		--Satish B : 05/16/2018 : Optimize the code for check fn_IsFCInstalled or not (Comment extra code and check directely in if condition)
		--SELECT @dmFCInstalled = dbo.fn_IsFCInstalled()
		--IF @dmFCInstalled = 1
		IF((Select  dbo.fn_IsFCInstalled()) = 1) 
			BEGIN
			   	-- Update DMEMOS table
				--Satish B : 05/04/2018 : Implement BEGIN TRY and BEGIN CATCH for error handling
				BEGIN TRY
					UPDATE DMEMOS SET 
						DMTOTALFC	= dbo.fn_Convert4FCHC('H',DM.FCUSED_UNIQ,DM.DMTOTAL,DM.FUNCFCUSED_UNIQ,DM.FCHIST_KEY),
						DMAPPLIEDFC	= dbo.fn_Convert4FCHC('H',DM.FCUSED_UNIQ,DM.DMAPPLIED,DM.FUNCFCUSED_UNIQ,DM.FCHIST_KEY),
						NDISCAMTFC	= dbo.fn_Convert4FCHC('H',DM.FCUSED_UNIQ,DM.NDISCAMT,DM.FUNCFCUSED_UNIQ,DM.FCHIST_KEY),
						NTAXAMTFC	= dbo.fn_Convert4FCHC('H',DM.FCUSED_UNIQ,DM.NTAXAMT,DM.FUNCFCUSED_UNIQ,DM.FCHIST_KEY),
						DMTOTALPR	= dbo.fn_Convert4FCHC('F',DM.FCUSED_UNIQ,DM.DMTOTAL,DM.PRFCUSED_UNIQ,DM.FCHIST_KEY),
						DMAPPLIEDPR	= dbo.fn_Convert4FCHC('F',DM.FCUSED_UNIQ,DM.DMAPPLIED,DM.PRFCUSED_UNIQ,DM.FCHIST_KEY),
						NDISCAMTPR	= dbo.fn_Convert4FCHC('F',DM.FCUSED_UNIQ,DM.NDISCAMT,DM.PRFCUSED_UNIQ,DM.FCHIST_KEY),
						NTAXAMTPR   = dbo.fn_Convert4FCHC('F',DM.FCUSED_UNIQ,DM.NTAXAMT,DM.PRFCUSED_UNIQ,DM.FCHIST_KEY)
					FROM DMEMOS DM INNER JOIN INSERTED I ON DM.UNIQAPHEAD=I.UNIQAPHEAD

					-- Update APDMDETL table
					UPDATE APDMDETL SET
						PRICE_EACHFC = dbo.fn_Convert4FCHC('H',DM.FCUSED_UNIQ,I.PRICE_EACH,DM.FUNCFCUSED_UNIQ,DM.FCHIST_KEY),	
						ITEM_TOTALFC = dbo.fn_Convert4FCHC('H',DM.FCUSED_UNIQ,I.ITEM_TOTAL,DM.FUNCFCUSED_UNIQ,DM.FCHIST_KEY),	
						PRICE_EACHPR = dbo.fn_Convert4FCHC('F',DM.FCUSED_UNIQ,I.PRICE_EACH,DM.PRFCUSED_UNIQ,DM.FCHIST_KEY),	
						ITEM_TOTALPR = dbo.fn_Convert4FCHC('F',DM.FCUSED_UNIQ,I.ITEM_TOTAL,DM.PRFCUSED_UNIQ,DM.FCHIST_KEY)
					FROM INSERTED I
					INNER JOIN DMEMOS DM ON DM.UNIQAPHEAD=I.UNIQAPHEAD
			 END TRY	
			 BEGIN CATCH
				IF @@TRANCOUNT <>0
					ROLLBACK;
						SELECT @ErrorMessage = ERROR_MESSAGE(),
							   @ErrorSeverity = ERROR_SEVERITY(),
							   @ErrorState = ERROR_STATE();
						RAISERROR (@ErrorMessage, -- Message text.
								   @ErrorSeverity, -- Severity.
								   @ErrorState -- State.
								   );
			END CATCH	
		END
		--Satish B : 05/04/2018 : Check rowcount
	IF @@TRANCOUNT>0
	COMMIT
	END
END
