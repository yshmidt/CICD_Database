CREATE TABLE [dbo].[GlTransDetails] (
    [fk_gluniq_key]   CHAR (10)        CONSTRAINT [DF_GlTransDetails_fk_gluniq_key] DEFAULT ('') NOT NULL,
    [cDrill]          VARCHAR (50)     CONSTRAINT [DF_GlTransDetails_cDrill] DEFAULT ('') NOT NULL,
    [cSubDrill]       VARCHAR (50)     CONSTRAINT [DF_GlTransDetails_cSubDrill] DEFAULT ('') NOT NULL,
    [Debit]           NUMERIC (14, 2)  CONSTRAINT [DF_GlTransDetails_Debit] DEFAULT ((0)) NOT NULL,
    [Credit]          NUMERIC (14, 2)  CONSTRAINT [DF_GlTransDetails_Credit] DEFAULT ((0)) NOT NULL,
    [GltransDUnique]  UNIQUEIDENTIFIER CONSTRAINT [DF__GLTRANSDUNIQUE] DEFAULT (newsequentialid()) NOT NULL,
    [TrGroupIdNumber] INT              CONSTRAINT [DF_GlTransDetails_TrGroupIdNumber] DEFAULT ((0)) NOT NULL,
    [transactiontype] VARCHAR (50)     CONSTRAINT [DF_GlTransDetails_transactiontype] DEFAULT ('') NOT NULL,
    [DebitPR]         NUMERIC (14, 2)  CONSTRAINT [DF_GlTransDetails_DebitPR] DEFAULT ((0.0)) NOT NULL,
    [CreditPR]        NUMERIC (14, 2)  CONSTRAINT [DF_GlTransDetails_CreditPR] DEFAULT ((0.00)) NOT NULL,
    CONSTRAINT [PK_GlTransDetails] PRIMARY KEY CLUSTERED ([GltransDUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Fk_GLUniq_key]
    ON [dbo].[GlTransDetails]([fk_gluniq_key] ASC);


GO
CREATE NONCLUSTERED INDEX [GlTransDetails_cDrill]
    ON [dbo].[GlTransDetails]([cDrill] ASC);


GO

-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 01/16/2012
-- Description:	Insert trigger for GltransDetails , will update JE tables if transactiottype='JE'
-- Modified: 03/09/15 YS when posted , original Je that had reversed checked, lost it reversed flag. 
-- I.e. when copied to Gljehdr from Gljehdro the reverse flag was set 0
-- 01/21/16 VL added new field AdjustEntry will copy from GlJeHdro to GlJeHdr
-- 07/28/16 YS when updating gljehdr, make sure fc_used is populated if FC
-- 05/24/17 VL Added functional currency code
-- 06/21/17 VL Added EnterCurrBy field
-- 11/30/17 Nilesh S insert value into Reserved column for table 'GLJEHDR'
-- 5/24/19 Nilesh S insert value into SaveUserId column for table 'GLJEHDR'
--09/20/19 YS remove this code and allow for multiple records in the inserted 
-- =============================================
CREATE TRIGGER [dbo].[GltransDetails_Insert]
   ON  [dbo].[GlTransDetails]
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- 05/24/17 VL comment out @homeCurrency and @isFC
    -- 07/28/16 YS check for FC and get home currency key
	--declare @homeCurrency char(10), @isFc bit

	
	--select @isFc = [dbo].[fn_IsFCInstalled]()
	--select @homeCurrency = dbo.fn_GetHomeCurrency()
 


	
	-- Insert statements for trigger here
    DECLARE @T as [dbo].[AllFYPeriods]
	INSERT INTO @T EXEC GlFyrstartEndView	;
    
    DECLARE @nRowCount int,@nCounter int,@Jeno [numeric](6,0),
		@TransactionType as varchar(50),@cDrill as varchar(50),@cSubDrill as varchar(50),@SaveInit as char(8),@TrGroupIdNumber int
	
	-- 01/21/16 VL added AdjustEntry
	-- 07/28/16 YS when updating gljehdr, make sure fc_used is populated if FC
	-- 05/24/17 VL Added functional currency code
	-- 06/21/17 VL Added EnterCurrBy field
	DECLARE @GlJEReversedH AS Table (JE_NO [numeric](6, 0),
									[TRANSDATE] [smalldatetime] ,
									[SAVEINIT] [char](8) ,
									[REASON] [varchar](max) ,
									[STATUS] [char](12) ,
									[JETYPE] [char](10) ,
									[REVERSE] [bit] ,
									[PERIOD] [numeric](2, 0) ,
									[FY] [char](4) ,
									[JEOHKEY] [char](10),
									[OLDJEOHKEY] [char](10),
									[ADJUSTENTRY] [bit],
									[FCUSED_UNIQ] [char](10),
									[PRFCUSED_UNIQ] [char](10),
									[FUNCFCUSED_UNIQ] [char](10),
									[FCHIST_KEY] [char](10),
									[EnterCurrBy] [char](1),
									[rownum] int IDENTITY (1, 1))
						
	--09/20/19 YS remove this code and allow for multiple records in the inserted 
	--SELECT @TransactionType = TransactionType,
	--		   @TrGroupIdNumber=TrGroupIdNumber,
	--		   @cDrill =cDrill,
	--		   @cSubDrill=cSubDrill
	--		  FROM inserted
BEGIN TRANSACTION
 

          
      -- for some transactions special treatment only if it is a first record of the same transaction
      --IF (@TransactionType='JE' and @TrGroupIdNumber=1)
      --BEGIN
		-- create new records in the GlJeHdr 
		-- 01/21/16 VL added AdjustEntry
		-- 05/24/17 VL Added functional currency code
		-- 06/21/17 VL Added EnterCurrBy field
		INSERT INTO [GLJEHDR]
           ([UNIQJEHEAD]
           ,[JE_NO]
           ,[TRANSDATE]
           ,[POSTEDDT]
           ,[SAVEINIT]
           ,[APP_DT]
           ,[REASON]
           ,[STATUS]
           ,[JETYPE]
           ,[PERIOD]
           ,[FY]
           ,[POSTED]
		   ,[REVERSED] -- 11/30/17 Nilesh S added column REVERSED
           ,[REVERSE] 
           ,[REVPERIOD]
           ,[REV_FY]
           ,[APP_INIT]
		     -- 07/28/16 YS when updating gljehdr, make sure fc_used is populated if FC
		   ,[FCUSED_UNIQ]
		   ,[ADJUSTENTRY]
		   ,[PRFCUSED_UNIQ]
		   ,[FUNCFCUSED_UNIQ]
		   ,[FCHIST_KEY]
		   ,[EnterCurrBy]
		   -- 5/24/19 Nilesh S insert value into SaveUserId column for table 'GLJEHDR'
		   ,[SaveUserId])
         SELECT  Jeohkey
            ,Je_no
            ,TRANSDATE 
           ,GETDATE()
           ,GlJeHdrO.SAVEINIT
           ,APP_DT
           ,REASON
           ,'POSTED'
           ,JETYPE
           ,GlJeHdrO.PERIOD
           ,GlJeHdrO.FY
           ,1
		   ---03/09/15 YS save reversed status for the original je
		   ,GlJeHdrO.[REVERSED] -- 11/30/17 Nilesh S added column REVERSED
           ,GlJeHdrO.[REVERSE]
           ,GLJEHDRO.[REVPERIOD]
           ,GLJEHDRO.[REV_FY]
           ,APP_INIT
		   -- 07/28/16 YS when updating gljehdr, make sure fc_used is populated if FC
		   -- 05/24/17 VL changed to get Fcused_uniq from GlJehdro
		   --,CASE WHEN @isFc=1 then @homeCurrency else '' end
		   ,Fcused_uniq
		   ,AdjustEntry
		   ,PRFcused_uniq
		   ,FUNCFCUSED_UNIQ
		   ,GljeHdro.FCHIST_KEY
		   ,EnterCurrBy
		   ,SaveUserId -- 5/24/19 Nilesh S insert value into SaveUserId column for table 'GLJEHDR'
          --09/20/19 YS remove this code and allow for multiple records in the inserted 
		   FROM GlJeHdrO INNER JOIN inserted ON GlJeHdro.JEOHKEY = RTRIM(Inserted.cDrill)
		   where inserted.transactiontype='JE' and inserted.TrGroupIdNumber=1 ;
		   
		-- create new records in the GlJeDet    
		-- 05/24/17 VL Added functional currency code  
		INSERT INTO [GLJEDET]
           ([UNIQJEHEAD]
           ,[UNIQJEDET]
           ,[GL_NBR]
           ,[DEBIT]
           ,[CREDIT]
		   ,[DEBITPR]
		   ,[CREDITPR]
		   ,[DEBITFC]
		   ,[CREDITFC])
		SELECT fkjeoh 
           ,Jeodkey 
           ,GLJEDETO.GL_NBR
           ,GLJEDETO.DEBIT
           ,GLJEDETO.CREDIT
		   ,GLJEDETO.DEBITPR
           ,GLJEDETO.CREDITPR
		   ,GLJEDETO.DEBITFC
           ,GLJEDETO.CREDITFC FROM GLJEDETO INNER JOIN inserted ON GlJeDetO.FKJEOH=RTRIM(Inserted.cDrill)  
			--09/20/19 YS remove this code and allow for multiple records in the inserted 
		   where inserted.transactiontype='JE' and inserted.TrGroupIdNumber=1 ;   
           
		-- check if reverse transaction has to be created
		-- 01/21/16 VL added AdjustEntry
		-- 05/24/17 VL Added functional currency code  
		-- 06/21/17 VL Added EnterCurrBy field
		INSERT INTO @GlJEReversedH   ([TRANSDATE] ,
									[SAVEINIT] ,
									[REASON] ,
									[STATUS]  ,
									[JETYPE]  ,
									[REVERSE] ,
									[PERIOD] ,
									[FY]  ,
									[JEOHKEY],[OLDJEOHKEY],
									 -- 07/28/16 YS when updating gljehdr, make sure fc_used is populated if FC
									[FCUSED_UNIQ],
									[ADJUSTENTRY],
									[PRFCUSED_UNIQ],
									[FUNCFCUSED_UNIQ],
									[FCHIST_KEY],
									[EnterCurrBy] )
						SELECT 		T.EndDate,
									GlJeHdrO.SaveInit,
									'Reversal '+RTRIM(LTRIM(Reason)),
									'NOT APPROVED',
									JeType,
									0,
									RevPeriod,
									Rev_fy,
									dbo.fn_GenerateUniqueNumber(),
									JeohKey,
									-- 07/28/16 YS when updating gljehdr, make sure fc_used is populated if FC
									-- 05/24/17 VL changed to get directly from Gljehdro
									--CASE WHEN @isFc=1 then @homeCurrency else '' end,
									Fcused_uniq,
									AdjustEntry,
									PRFCUSED_UNIQ,
									FUNCFCUSED_UNIQ,
									FCHIST_KEY,
									EnterCurrBy
									FROM GlJeHdrO INNER JOIN Inserted on GlJeHdro.JEOHKEY = RTRIM(Inserted.cDrill) 
									INNER JOIN @T as T ON GlJeHdrO.RevPeriod=T.Period and GlJeHdrO.Rev_fy=T.FiscalYr WHERE GlJeHdro.[Reverse]=1
										--09/20/19 YS remove this code and allow for multiple records in the inserted 
									 and inserted.transactiontype='JE' and inserted.TrGroupIdNumber=1 ;	
		SET @nRowCount=@@ROWCOUNT
		IF(@nRowCount<>0)
		BEGIN	
			-- records to reverse 
			-- create new Je_no
			SET @nCounter=1
	 		WHILE @nCounter<=@nRowCount
	 		BEGIN
	 			EXEC GetNextJeno @Jeno OUTPUT 
	 			UPDATE @GlJEReversedH SET Je_no=@JeNo WHERE RowNum=@nCounter
	 			SET @nCounter=@nCounter+1
	 		END   -- WHILE @nCounter<@nRowCount							
			-- create Header 
			-- 01/21/16 VL added AdjustEntry
			-- 05/24/17 VL Added functional currency code  
			-- 06/21/17 VL Added EnterCurrBy field
			INSERT INTO [GLJEHDRO]
				([JE_NO]
				,[TRANSDATE]
				,[SAVEINIT]
				,[REASON]
				,[STATUS]
			    ,[JETYPE]
			   ,[REVERSE]
			   ,[PERIOD]
			   ,[FY]
			   ,[JEOHKEY]
			   -- 07/28/16 YS when updating gljehdr, make sure fc_used is populated if FC
			   ,[FCUSED_UNIQ]
			   ,[ADJUSTENTRY]
			   ,[PRFCUSED_UNIQ]
			   ,[FUNCFCUSED_UNIQ]
			   ,[FCHIST_KEY]
			   ,[EnterCurrBy])
			SELECT JE_NO
			   ,TRANSDATE
			   ,SAVEINIT
			   ,REASON
			   ,STATUS
			   ,JETYPE
			   ,REVERSE
			   ,PERIOD
			   ,FY
			   ,JEOHKEY
			   -- 07/28/16 YS when updating gljehdr, make sure fc_used is populated if FC
			   ,[FCUSED_UNIQ]
			   ,ADJUSTENTRY
			   ,PRFCUSED_UNIQ
			   ,FUNCFCUSED_UNIQ
			   ,FCHIST_KEY
			   ,EnterCurrBy FROM @GlJEReversedH
			   
			-- create GlJeDetO records
			-- 05/24/17 VL Added functional currency code  
			INSERT INTO [GLJEDETO]
					([GL_NBR]
					,[DEBIT]
					,[CREDIT]
					,[JEODKEY]
					,[FKJEOH]
					,[DEBITPR]
					,[CREDITPR]
					,[DEBITFC]
					,[CREDITFC])
			SELECT 
					GL_NBR,
					Credit as DEBIT,
					Debit as CREDIT,
					dbo.fn_GenerateUniqueNumber(),
					H.[JEOHKEY], 
					CreditPR as DEBITPR,
					DebitPR as CREDITPR,
					CreditFC as DEBITFC,
					DebitFC as CREDITFC
					FROM GLJEDETO INNER JOIN @GlJEReversedH H ON GlJeDetO.FKJEOH=H.[OLDJEOHKEY]
			-- 						
       END ---IF(@nRowCount<>0)
      -- remove records from GlJeHdrO
	 	--09/20/19 YS remove this code and allow for multiple records in the inserted 
      DELETE FROM GlJeHdrO WHERE GlJeHdro.JEOHKEY IN (SELECT RTRIM(Inserted.cDrill) FROM INSERTED  where inserted.transactiontype='JE' and inserted.TrGroupIdNumber=1) ;
      
      
      --END -- IF (@TransactionType='JE')           
COMMIT
	
END