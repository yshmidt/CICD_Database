-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 12/11/14 
-- Description:	import Journal Entry from excel
-- Modification:
-- 06/07/17 VL Added functional currency code
-- 06/08/17 VL use presentation currency as the fcused_Uniq 2nd parameter and use dbo.fn_GetFunctionalCurrency() as 4th parameter to get correct PR values
-- =============================================
CREATE PROCEDURE [dbo].[SP_JEUpload]
	-- Add the parameters for the stored procedure here
	@timport timportJE READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- variable to hold an error information

	DECLARE @ERRORNUMBER Int= 0
		,@ERRORSEVERITY int=0
		,@ERRORPROCEDURE varchar(max)=''
		,@ERRORLINE int =0
		,@ERRORMESSAGE varchar(max)=' '

	--remove records from prior error log for the upload
	DELETE FROM importJeErrors

	-- {06/07/17 VL added a table variable that can be updated
	DECLARE @ZImport TABLE ([JE_NO] [numeric](6, 0) NOT NULL, [TRANSDATE] [smalldatetime] NULL, [App_dt] [smalldatetime] NULL, [SAVEINIT] [char](8) NULL,
							[REASON] [varchar](max) NOT NULL, [STATUS] [char](12) NOT NULL,	[JETYPE] [char](10) NOT NULL, [GL_NBR] [char](13) NOT NULL,
							[DEBIT] [numeric](14, 2) NOT NULL, [CREDIT] [numeric](14, 2) NOT NULL, [DEBITFC] [numeric](14, 2) NOT NULL,	[CREDITFC] [numeric](14, 2) NOT NULL,
							[DEBITPR] [numeric](14, 2) NOT NULL, [CREDITPR] [numeric](14, 2) NOT NULL, [FCUSED_UNIQ] [char](10) NULL, [FCHIST_KEY][char](10) NULL, [SYMBOL][char](3))

	INSERT @ZImport SELECT * FROM @timport
	-- 06/07/17 VL End}

	declare @tJEHDR TABLE ([JE_NO] [numeric](6, 0) NOT NULL,
		[TRANSDATE] [smalldatetime] NULL,
		[SAVEINIT] [char](8) NULL,
		[APP_DT] [smalldatetime] NULL,
		[REASON] [varchar](max) NOT NULL,
		[STATUS] [char](12) NOT NULL,
		[JETYPE] [char](10) NOT NULL,
		[REVERSE] [bit] NOT NULL DEFAULT(0),
		[PERIOD] [numeric](2, 0) NOT NULL,
		[FY] [char](4) NOT NULL,
		[REVERSED] [bit] NOT NULL DEFAULT(0),
		[REVPERIOD] [numeric](2, 0) NOT NULL DEFAULT(0),
		[REV_FY] [char](4) NOT NULL DEFAULT(''),
		[JEOHKEY] [char](10) NOT NULL DEFAULT(''),
		[APP_INIT] [char](8) NULL,
		[IS_REL_GL] [bit] NOT NULL DEFAULT(0),
		-- 06/07/17 VL Added functional currency code
		[Fcused_uniq][char](10) NULL,
		[Fchist_key][char](10) NULL)
	
	declare @tJeDet TABLE (
		[GL_NBR] [char](13) NOT NULL,
		[DEBIT] [numeric](14, 2) NOT NULL,
		[CREDIT] [numeric](14, 2) NOT NULL,
		[JEODKEY] [char](10) NOT NULL DEFAULT(''),
		[FKJEOH] [char](10) NOT NULL DEFAULT(''),
		-- 06/07/17 VL Added functional currency code
		[DEBITFC] [numeric](14, 2) NOT NULL,
		[CREDITFC] [numeric](14, 2) NOT NULL,
		[DEBITPR] [numeric](14, 2) NOT NULL,
		[CREDITPR] [numeric](14, 2) NOT NULL)
	
	-- get next JE #
	
	declare @je_no numeric(6,0) ,@JEOHKEY char(10) 
	exec [GetNextJeNo] @pnNextNumber=@je_no OUTPUT
	-- get Fiscal Year and Period information
	DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView	;
	select @Jeohkey=dbo.fn_GenerateUniqueNumber() ;

	-- 06/07/17 VL added code to convert between functional, transaction values, also update presentation, now should only Fcused_uniq are updated, will get Fchist_key and update all amount
	IF dbo.fn_IsFCInstalled() = 1
		BEGIN
		;WITH ZMaxDate AS
			(SELECT MAX(Fcdatetime) AS Fcdatetime, FcUsed_Uniq
			FROM FcHistory 
			GROUP BY Fcused_Uniq),
		ZFCPrice AS 
			(SELECT FcHistory.AskPrice, AskPricePR, FcHistory.FcUsed_Uniq, FcHist_key, FcHistory.Fcdatetime
				FROM FcHistory, ZMaxDate
				WHERE FcHistory.FcUsed_Uniq = ZMaxDate.FcUsed_Uniq
				AND FcHistory.Fcdatetime = ZMaxDate.Fcdatetime)
	

		UPDATE @ZImport	
			SET Fchist_key = ZFCPrice.Fchist_key
			FROM @ZImport ZImport, ZFCPrice
			WHERE ZImport.Fcused_uniq = ZFCPrice.Fcused_uniq

		-- if user only update DebitFC/CreditFC, then convert and update Debit/Credit and DebitPR/CreditPR
		UPDATE @ZImport SET Debit = ROUND(dbo.fn_Convert4FCHC('F', Fcused_uniq, DebitFC, dbo.fn_GetFunctionalCurrency(), Fchist_key),2),
							Credit = ROUND(dbo.fn_Convert4FCHC('F', Fcused_uniq, CreditFC, dbo.fn_GetFunctionalCurrency(), Fchist_key),2),
							DebitPR = ROUND(dbo.fn_Convert4FCHC('F', Fcused_uniq, DebitFC, dbo.fn_GetPresentationCurrency(), Fchist_key),2),
							CreditPR = ROUND(dbo.fn_Convert4FCHC('F', Fcused_uniq, CreditFC, dbo.fn_GetPresentationCurrency(), Fchist_key),2)
				WHERE (DebitFC <> 0 OR CreditFC <> 0 ) AND (Debit = 0 AND Credit = 0)

		-- if user only update DebitFC/CreditFC, then convert and update Debit/Credit and DebitPR/CreditPR
		UPDATE @ZImport SET DebitFC = ROUND(dbo.fn_Convert4FCHC('H', Fcused_uniq, Debit, dbo.fn_GetFunctionalCurrency(), Fchist_key),2),
							CreditFC = ROUND(dbo.fn_Convert4FCHC('H', Fcused_uniq, Credit, dbo.fn_GetFunctionalCurrency(), Fchist_key),2),
							-- 06/08/17 VL use presentation currency as the fcused_Uniq 2nd parameter and use dbo.fn_GetFunctionalCurrency() as 4th parameter to get correct PR values
							DebitPR = ROUND(dbo.fn_Convert4FCHC('H', dbo.fn_GetPresentationCurrency(), Debit, dbo.fn_GetFunctionalCurrency(), Fchist_key),2),
							CreditPR = ROUND(dbo.fn_Convert4FCHC('H', dbo.fn_GetPresentationCurrency(), Credit, dbo.fn_GetFunctionalCurrency(), Fchist_key),2)
				WHERE (DebitFC = 0 AND CreditFC = 0 ) AND (Debit <> 0 OR Credit <> 0)

	END
	-- 06/07/17 VL End}

	INSERT INTO @tJEHDR 
		([Je_no],
		[TRANSDATE] ,
		[SAVEINIT] ,
		[APP_DT] ,
		[REASON] ,
		[STATUS] ,
		[JETYPE] ,
		[PERIOD] ,
		[FY] ,
		[JEOHKEY] ,
		[APP_INIT] ,
		[IS_REL_GL],
		-- 06/07/17 VL Added functional currency code
		[Fcused_uniq],
		[Fchist_key])
	SELECT DISTINCT @je_no as Je_no,[TRANSDATE] ,
		[SAVEINIT] ,
		[APP_DT] ,
		[REASON] ,
		[STATUS] ,
		[JETYPE] ,
		Fy.[PERIOD] ,
		fy.[FiscalYr] as FY,
		@Jeohkey ,
		[SAVEINIT] as [APP_INIT] ,
		0 as [IS_REL_GL],
		-- 06/07/17 VL Added functional currency code
		[Fcused_uniq],
		[Fchist_key]
	from @ZImport OUTER APPLY (SELECT FiscalYr,Period,fyDtlUniq FROM @T as T 
			WHERE CAST(TransDate as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY ;


	INSERT INTO @tJeDet 
		([GL_NBR] ,
		[DEBIT] ,
		[CREDIT],
		[FKJEOH],
		-- 06/07/17 VL Added functional currency code
		[DEBITFC] ,
		[CREDITFC],
		[DEBITPR] ,
		[CREDITPR])
		select [GL_NBR] ,
		SUM([DEBIT]) ,
		SUM([CREDIT]),
		@Jeohkey as [FKJEOH],
		-- 06/07/17 VL Added functional currency code
		SUM([DEBITFC]) ,
		SUM([CREDITFC]),
		SUM([DEBITPR]) ,
		SUM([CREDITPR]) 
		from @ZImport GROUP BY GL_NBR

		update @tJeDet SET [JEODKEY]=dbo.fn_GenerateUniqueNumber()
		--- update tables
		BEGIN TRANSACTION
		BEGIN TRY
			INSERT INTO GlJeHdro (
			JE_NO,
			[TRANSDATE] ,
			[SAVEINIT] ,
			[APP_DT] ,
			[REASON] ,
			[STATUS] ,
			[JETYPE] ,
			[PERIOD] ,
			[FY] ,
			[JEOHKEY] ,
			[APP_INIT] ,
			[IS_REL_GL],
			-- 06/07/17 VL Added functional currency code
			[Fcused_uniq],
			[Fchist_key],
			[PrFcused_uniq],
			[FuncFcused_uniq]) SELECT 
			JE_NO,
			[TRANSDATE] ,
			[SAVEINIT] ,
			[APP_DT] ,
			[REASON] ,
			[STATUS] ,
			[JETYPE] ,
			[PERIOD] ,
			[FY] ,
			[JEOHKEY] ,
			[APP_INIT] ,
			[IS_REL_GL],
			-- 06/07/17 VL Added functional currency code
			[Fcused_uniq],
			[Fchist_key],
			dbo.fn_GetPresentationCurrency() AS [PRFcused_uniq],
			dbo.fn_GetFunctionalCurrency() AS [FuncFcused_uniq] FROM @tJEHDR
		END TRY
		BEGIN CATCH
			SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
			IF @@TRANCOUNT>0
				ROLLBACK TRANSACTION

			INSERT INTO importJeErrors (ErrorMessage)
				VALUES 
			('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
			'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
			'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
			'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
			'Error Message: '+@ERRORMESSAGE)
			return -1
		END CATCH
		BEGIN TRY
			INSERT INTO GlJeDetO
			([GL_NBR] ,
			[DEBIT] ,
			[CREDIT],
			[FKJEOH] ,
			[JEODKEY],
			-- 06/07/17 VL Added functional currency code
			[DEBITFC] ,
			[CREDITFC],
			[DEBITPR] ,
			[CREDITPR])
			select [GL_NBR] ,
			[DEBIT] ,
			[CREDIT],
			[FKJEOH] ,
			[JEODKEY],
			-- 06/07/17 VL Added functional currency code 
			[DEBITFC] ,
			[CREDITFC],
			[DEBITPR] ,
			[CREDITPR]
			FROM @tJeDet
		END TRY
		BEGIN CATCH
			SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
			IF @@TRANCOUNT>0
				ROLLBACK TRANSACTION

			INSERT INTO importJeErrors (ErrorMessage)
				VALUES 
			('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
			'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
			'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
			'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
			'Error Message: '+@ERRORMESSAGE)
			return -1
		END CATCH
		IF @@TRANCOUNT>0
		COMMIT TRANSACTION
END