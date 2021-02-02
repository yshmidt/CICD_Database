-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 05/28/2013
-- Description:	Procedure will release and post scrap transactions automatically
-- Modification:
-- 01/06/17 VL: Added functional currency code
-- =============================================
CREATE PROCEDURE [dbo].[SpScrapReleasePost] 
	-- Add the parameters for the stored procedure here
	@SaveInit char(8) =' '  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	DECLARE @plposttopriorfy bit,@plposttopriorperiod bit,@plposttofutureperiod bit,@pccurrentfy char(4),@pncurrentperiod numeric(2,0),
			@ErrorMessage NVARCHAR(4000);
	SELECT @plposttopriorfy=CASE WHEN GlSys.PfyPost=1 THEN 1 ELSE 0 END,
			@plposttopriorperiod=CASE WHEN GlSys.PpPost = 1 THEN 1 ELSE 0 END,
			@plposttofutureperiod=CASE WHEN GlSys.FpPost = 1 THEN 1 ELSE 0 END,	
			@pccurrentfy= GlSys.Cur_fy ,
			@pncurrentperiod=Glsys.Cur_Period FROM GlSys

	-- 01/06/17 VL added to check if FC is installed or not
	DECLARE @lFCInstalled bit
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
			

	-- 01/06/17 VL: Added functional currency fields
	DECLARE @ScrapToRelease TABLE (wono char(10), uniq_key char(10), 
						TRANS_NO char(10) ,GL_NBR char(13),
						Trans_dt smalldatetime,	
						DEBIT Numeric(14,2),Credit Numeric(14,2),
						TransactionType char(50), 
						SourceTable	char(25),cIdentifier char(30),
						cDrill varchar(50),SourceSubTable char(25),
						cSubIdentifier char(30),
						cSubDrill char(20),
						FY char(4),Period numeric(2,0),fk_fyDtlUniq uniqueidentifier,GroupIdNumber int,
						-- 01/06/17 VL: Added functional currency fields
						DEBITPR Numeric(14,2),CreditPR Numeric(14,2))


	DECLARE @T as dbo.AllFYPeriods
	INSERT INTO @T EXEC GlFyrstartEndView	;
	with ScrapDebit AS
	(
	SELECT SCRAPREL.wono, SCRAPREL.uniq_key, SCRAPREL.SHRI_GL_NO as Gl_nbr,
	  SCRAPREL.wip_gl_nbr,  SCRAPREL.STDCOST ,SCRAPREL.QTYTRANSF ,
	  scraprel.TRANS_NO, SCRAPREL.datetime AS Trans_dt,
	  CASE WHEN  ROUND(qtytransf*stdcost,2)>0 THEN ROUND(qtytransf*stdcost,2) ELSE CAST(0.00 as numeric(14,2)) END as DEBIT,
	  CASE WHEN ROUND(qtytransf*stdcost,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(qtytransf*stdcost,2)) END as Credit,
	  CAST('SCRAP' as varchar(50)) as TransactionType, 
	  CAST('scraprel' as varchar(25)) as SourceTable,
	  'trans_no' as cIdentifier,
	  scraprel.trans_no as cDrill,
	  CAST('scraprel' as varchar(25)) as SourceSubTable,
	  'trans_no' as cSubIdentifier,
	  scraprel.trans_no as cSubDrill,
	  fy.FiscalYr as FY,fy.Period ,fy.fyDtlUniq as fk_fyDtlUniq,
	  -- 01/06/17 VL: Added functional currency fields
	  CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE SCRAPREL.STDCOSTPR END AS StdCostPR,
  	  CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE CASE WHEN  ROUND(qtytransf*stdcost,2)>0 THEN ROUND(qtytransf*stdcost,2) ELSE CAST(0.00 as numeric(14,2)) END END AS DEBITPR,
	  CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE CASE WHEN ROUND(qtytransf*stdcost,2)>0 THEN CAST(0.00 as numeric(14,2)) ELSE ABS(ROUND(qtytransf*stdcost,2)) END END AS CreditPR
	FROM  SCRAPREL OUTER APPLY (SELECT FiscalYr,Period,FyDtlUniq FROM @T as T 
	       WHERE CAST(scraprel.datetime as date) BETWEEN CAST(T.startDate as date) and  CAST(t.EndDate as date)) as FY
	WHERE is_Rel_Gl=0 and qtytransf*stdcost <>0.00
	),ScrapCredit AS
   (
	SELECT ScrapDebit.wono, ScrapDebit.uniq_key, 
	ScrapDebit.STDCOST ,ScrapDebit.QTYTRANSF ,
	ScrapDebit.TRANS_NO ,ScrapDebit.wip_gl_nbr as GL_NBR, 
	ScrapDebit.Trans_dt,
	ScrapDebit.Credit as DEBIT,
	ScrapDebit.Debit as Credit,
	ScrapDebit.TransactionType, 
	ScrapDebit.SourceTable,
	ScrapDebit.cIdentifier,
	ScrapDebit.cDrill,
	ScrapDebit.SourceSubTable,
	ScrapDebit.cSubIdentifier,
	ScrapDebit.cSubDrill,
	ScrapDebit.FY,ScrapDebit.Period,ScrapDebit.fk_fyDtlUniq,
	-- 01/06/17 VL: Added functional currency fields
	CASE WHEN @lFCInstalled = 0 THEN 0.00000 ELSE ScrapDebit.STDCOSTPR END AS StdCostPR,
	CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE ScrapDebit.CreditPR END AS DebitPR,
	CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE ScrapDebit.DebitPR END AS CreditPR
	FROM  ScrapDebit 
	),FinalScrap as
	(
	SELECT wono, uniq_key, 
		TRANS_NO ,GL_NBR,
		Trans_dt,
		DEBIT,
		Credit,
	    TransactionType, 
	    SourceTable,
	    cIdentifier,
	    cDrill,
	    SourceSubTable,
	    cSubIdentifier,
	   cSubDrill,
	   FY,Period ,fk_fyDtlUniq,
	   -- 01/06/17 VL: Added functional currency fields
		CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE DEBITPR END AS DebitPR,
		CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE CreditPR END AS CreditPR
	 FROM  ScrapDebit 
	 UNION ALL
	 SELECT wono, uniq_key, 
		TRANS_NO ,GL_NBR,
		Trans_dt,
		DEBIT,
		Credit,
		TransactionType, 
		SourceTable,
		cIdentifier,
		cDrill,
		SourceSubTable,
		cSubIdentifier,
		cSubDrill,
		FY,Period ,fk_fyDtlUniq,
		-- 01/06/17 VL: Added functional currency fields
		CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE DEBITPR END AS DebitPR,
		CASE WHEN @lFCInstalled = 0 THEN 0.00 ELSE CreditPR END AS CreditPR
	  FROM  ScrapCredit)

	-- 01/06/17 VL: Added functional currency fields
	INSERT INTO @ScrapToRelease (wono, uniq_key,TRANS_NO ,GL_NBR,
			Trans_dt,DEBIT,Credit,TransactionType,SourceTable,
			cIdentifier,cDrill,SourceSubTable,cSubIdentifier,
			cSubDrill,FY,Period ,fk_fyDtlUniq,GroupIdNumber,DEBITPR,CreditPR)
	SELECT wono, uniq_key,TRANS_NO ,GL_NBR,
			Trans_dt,DEBIT,Credit,TransactionType,SourceTable,
			cIdentifier,cDrill,SourceSubTable,cSubIdentifier,
			cSubDrill,FY,Period ,fk_fyDtlUniq,
			ROW_NUMBER () OVER(PARTITION BY cDrill ORDER BY Wono,Trans_dt) as GroupIdNumber,
			DEBITPR,CreditPR	 
			FROM FinalScrap 
			WHERE Fy<>' ' and Period<>0 
			AND 1=CASE WHEN @plposttofutureperiod =0 AND 
				(CAST(FY as int)>CAST(@pccurrentfy as int) OR (FY=@pccurrentfy AND Period>@pncurrentperiod )) THEN 0
			WHEN @plposttopriorperiod =0 AND
				(CAST(FY as int)<CAST(@pccurrentfy as int) OR (FY=@pccurrentfy AND Period<@pncurrentperiod )) THEN 0
			WHEN @plposttopriorfy = 0 AND CAST(FY as int)<CAST(@pccurrentfy as int) THEN 0
			ELSE 1 END
			ORDER BY WONO,trans_dt	
								  
	-- remove if problem with balance
	DELETE FROM @ScrapToRelease  
	WHERE EXISTS (SELECT TRANS_NO,SUM(Debit),SUM(credit) from @ScrapToRelease NR WHERE NR.TRANS_no=Trans_no GROUP BY NR.TRANS_NO HAVING SUM(debit)<>SUM(credit) ) 
	--select * from @ScrapToRelease

	-- create local cursor and insert one record at a time trigger for the glreleased work with a single record
	-- 01/06/17 VL: Added functional currency fields
	DECLARE @GLRELUNIQUE char(10),@Trans_dt smalldatetime,@Period numeric(2,0),@Fy char(4),
			@Gl_nbr char(13),@Debit numeric(14,2),@Credit numeric(14,2),
			@CIDENTIFIER char(30),@CDRILL varchar(50),@TransactionType char(50),
			@SourceTable char(25),@SourceSubTable char(25) ,@cSubIdentifier char(30) ,@cSubDrill varchar(50) ,
			@fk_fydtluniq uniqueidentifier,@GroupIdNumber int,
			@DebitPR numeric(14,2),@CreditPR numeric(14,2)
			
	BEGIN TRANSACTION
	BEGIN TRY		
	DECLARE GlScrapRel CURSOR LOCAL FAST_FORWARD
	-- 01/06/17 VL: Added functional currency fields
	FOR SELECT dbo.fn_GenerateUniqueNumber() as GLRELUNIQUE,Trans_dt,
		Period,Fy,Gl_nbr,Debit,Credit,CIDENTIFIER ,CDRILL ,TransactionType ,
		SourceTable ,SourceSubTable ,cSubIdentifier ,cSubDrill ,fk_fydtluniq ,GroupIdNumber,
		DebitPR,CreditPR
		FROM @ScrapToRelease ORDER BY Trans_no,GroupIdNumber			

	OPEN GlScrapRel;
	
	FETCH NEXT FROM GlScrapRel 
			INTO @GLRELUNIQUE,@Trans_dt ,@Period ,@Fy,
				 @Gl_nbr ,@Debit ,@Credit ,
				 @CIDENTIFIER ,@CDRILL ,@TransactionType ,
				 @SourceTable ,@SourceSubTable ,@cSubIdentifier ,@cSubDrill ,
				 @fk_fydtluniq, @GroupIdNumber,
				 -- 01/06/17 VL: Added functional currency fields
				 @DebitPR,@CreditPR;

	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- 01/06/17 VL: Added functional currency fields
		INSERT INTO GLRELEASED (GLRELUNIQUE ,TRANS_DT,PERIOD,FY,GL_NBR,DEBIT,CREDIT,SAVEINIT,CIDENTIFIER ,CDRILL ,TransactionType ,
						SourceTable ,SourceSubTable ,cSubIdentifier ,cSubDrill ,fk_fydtluniq ,GroupIdNumber, DEBITPR,CREDITPR,PRFcused_uniq, FuncFcused_uniq ) 
		VALUES 					
		(@GLRELUNIQUE,@Trans_dt,@Period,@Fy,@Gl_nbr,@Debit,@Credit,@SaveInit,@CIDENTIFIER ,@CDRILL ,@TransactionType ,
		@SourceTable ,@SourceSubTable ,@cSubIdentifier ,@cSubDrill ,@fk_fydtluniq ,@GroupIdNumber,@DebitPR,@CreditPR,dbo.fn_GetPresentationCurrency(),dbo.fn_GetFunctionalCurrency())			

		
		FETCH NEXT FROM GlScrapRel 
			INTO @GLRELUNIQUE,@Trans_dt ,@Period ,@Fy,
				 @Gl_nbr ,@Debit ,@Credit ,
				 @CIDENTIFIER ,@CDRILL ,@TransactionType ,
				 @SourceTable ,@SourceSubTable ,@cSubIdentifier ,@cSubDrill ,
				 @fk_fydtluniq, @GroupIdNumber,
 				 -- 01/06/17 VL: Added functional currency fields
				 @DebitPR,@CreditPR;


	END -- WHILE @@FETCH_STATUS = 0
	CLOSE GlScrapRel;
	DEALLOCATE GlScrapRel;
	END TRY
	BEGIN CATCH
		
		SELECT 
        @ErrorMessage = ERROR_MESSAGE() ;

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RAISERROR('Error occurred when releasing SCRAP transactions. Error %s',11,1,@ErrorMessage)
	END CATCH
	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
	-- Now post
	-- 01/06/17 VL: Added functional currency fields
	DECLARE @glTransTutto TABLE (
		[GLRELUNIQUE] char(10)
       ,RANKN INT 
       ,[TrGroupIdNumber] INT
       ,[TRANS_DT] smalldatetime
       ,[PERIOD] numeric(2,0)
       ,[FY] char(4)
       ,[GL_NBR] char(13)
       ,[DEBIT] numeric(14,2)
       ,[CREDIT] numeric(14,2)
       ,[SAVEINIT] char(8)
       ,[CIDENTIFIER] char(30)
       ,[LPOSTEDTOGL] bit
       ,[CDRILL] varchar(50)
       ,[TransactionType] varchar(50)
       ,[SourceTable] varchar(25)
       ,[SourceSubTable] varchar(25)
       ,[cSubIdentifier] char(30)
       ,[cSubDrill] varchar(50)
       ,[fk_fydtluniq] uniqueidentifier
       ,[GroupIdNumber] int
        ,[GLUNIQ_KEY] char(10)
        ,Fk_GLTRansUnique char(10)
		-- 01/06/17 VL: Added functional currency fields
       ,[DEBITPR] numeric(14,2)
       ,[CREDITPR] numeric(14,2)
		)
		
		
	DECLARE @GlTransHeader TABLE (RankN int,GLTRansUnique char(10),Transactiontype varchar(50),SourceTable varchar(25),
					cIdentifier char(30),Trans_dt smalldatetime,Period numeric(2,0),Fy char(4),SAVEINIT char(8),fk_fydtluniq uniqueidentifier)
	
	-- 01/06/17 VL: Added functional currency fields				
	DECLARE @GlTrans TABLE (glUniq_key char(10),RankN int,
           GL_NBR char(13),Debit numeric(14,2),Credit numeric(14,2),
           CIDENTIFIER char(30),SourceTable varchar(25),
           SourceSubTable varchar(25),cSubIdentifier char(30),Fk_GLTRansUnique char(10),
		   DebitPR numeric(14,2),CreditPR numeric(14,2))
           							
	INSERT INTO @glTransTutto (
	   [GLRELUNIQUE]
	  ,RANKN 
	  ,[TrGroupIdNumber]
	  ,[TRANS_DT]
	  ,[PERIOD]
	  ,[FY]
	  ,[GL_NBR]
	  ,[DEBIT]
	  ,[CREDIT]
      ,[SAVEINIT]
      ,[CIDENTIFIER]
      ,[LPOSTEDTOGL]
      ,[CDRILL]
      ,[TransactionType]
      ,[SourceTable]
      ,[SourceSubTable]
      ,[cSubIdentifier]
      ,[cSubDrill]
      ,[fk_fydtluniq]
      ,[GroupIdNumber]
	  -- 01/06/17 VL: Added functional currency fields	
	  ,[DEBITPR]
	  ,[CREDITPR]	  	
      )	
	SELECT [GLRELUNIQUE]
      ,DENSE_RANK () OVER (order by transactiontype,sourcetable,Trans_dt) 
      ,ROW_NUMBER () OVER (partition by transactiontype,sourcetable,Trans_dt order by cdrill)
      ,[TRANS_DT]
      ,[PERIOD]
      ,[FY]
      ,[GL_NBR]
      ,[DEBIT]
      ,[CREDIT]
      ,[SAVEINIT]
      ,[CIDENTIFIER]
      ,[LPOSTEDTOGL]
      ,[CDRILL]
      ,[TransactionType]
      ,[SourceTable]
      ,[SourceSubTable]
      ,[cSubIdentifier]
      ,[cSubDrill]
      ,[fk_fydtluniq]
      ,[GroupIdNumber]
	  -- 01/06/17 VL: Added functional currency fields	
	  ,[DEBITPR]
	  ,[CREDITPR]	
       FROM [dbo].[GLRELEASED] WHERE [TransactionType]='SCRAP'
       
       
     -- generate gltrans header
    INSERT INTO @GlTransHeader 
       SELECT DISTINCT RankN,CAST(' ' as char(10)) as GLTRansUnique,TRansactionType,SourceTable,cIdentifier,
		Trans_dt,Period,Fy,@SaveInit,
		fk_fydtluniq  
		FROM @glTransTutto 
		UPDATE @GlTransHeader SET GLTRansUnique=dbo.fn_GenerateUniqueNumber() 
  		UPDATE T SET fk_GLTRansUnique=H.GLTRansUnique FROM @GlTransHeader H INNER JOIN @GlTransTutto T ON T.Rankn=H.RankN

	-- generate gltrans
	INSERT INTO @GlTrans
		SELECT CAST(' ' as char(10)) as GLUNIQ_KEY,RankN 
           ,GL_NBR,SUM(DEBIT) as Debit
           ,SUM(CREDIT) as Credit
           ,CIDENTIFIER
           ,SourceTable
           ,SourceSubTable
           ,cSubIdentifier,Fk_GLTRansUnique 
		    -- 01/06/17 VL: Added functional currency fields
		   ,SUM(DEBITPR) as DebitPR
           ,SUM(CREDITPR) as CreditPR				
           FROM @GlTransTutto 
           GROUP BY RankN,GL_Nbr,CIDENTIFIER,SourceTable,SourceSubTable,cSubIdentifier ,Fk_GLTRansUnique
 
	UPDATE @GlTRans SET GLUNIQ_KEY=dbo.fn_GenerateUniqueNumber() 
	UPDATE D SET GLUNIQ_KEY=T.GLUNIQ_KEY FROM @GlTRans T INNER JOIN @GlTransTutto D ON D.RankN=T.RankN AND  
    	D.GL_Nbr=T.GL_Nbr AND 
    	D.CIDENTIFIER=T.CIDENTIFIER AND 
    	D.SourceTable=T.SourceTable AND  
    	D.SourceSubTable=T.SourceSubTable AND 
    	D.cSubIdentifier=T.cSubIdentifier      

	-- check for balance problems

	IF EXISTS (SELECT SUM(Debit) ,SUM(Credit), rankN 
		FROM 	@GlTransTutto 
		GROUP BY RankN 
		HAVING 	SUM(credit) <> Sum(debit) )
	BEGIN
		RAISERROR('Out of Balance Problem for some of the ''SCRAP'' transactions',11,1)
		RETURN -1
	END	-- @@ROWCOUNT<>0
	ELSE
	BEGIN -- ELSE -- @@ROWCOUNT<>0
		-- continue with Posting transactions
		-- create local cursor to insert one record at atime into header table
		BEGIN TRANSACTION
		BEGIN TRY
			DECLARE @GLTRANSUNIQUE char(10)
			DECLARE GltH CURSOR LOCAL FAST_FORWARD
			FOR SELECT GLTRANSUNIQUE 
			   ,TRansactionType 
			   ,SourceTable
			   ,CIdentifier
			   ,TRANS_DT 
			   ,PERIOD
			   ,FY
			   ,fk_fydtluniq FROM @GlTransHeader 			

			OPEN GltH;
	
			FETCH NEXT FROM GltH 
				INTO @GLTRANSUNIQUE 
			   ,@TRansactionType 
			   ,@SourceTable
			   ,@CIdentifier
			   ,@TRANS_DT 
			   ,@PERIOD
			   ,@FY
			   ,@fk_fydtluniq ;
				
			WHILE @@FETCH_STATUS = 0
			BEGIN
				INSERT INTO GLTRANSHEADER
			   (GLTRANSUNIQUE 
			   ,TRansactionType
			   ,SourceTable
			   ,CIdentifier
			   ,TRANS_DT
			   ,PERIOD
			   ,FY
			   ,SAVEINIT
			   ,fk_fydtluniq
			   -- 01/06/17 VL: Added functional currency fields
			   ,PRFCUSED_UNIQ
			   ,FUNCFCUSED_UNIQ
			   ) VALUES
			   (@GLTRANSUNIQUE 
			   ,@TRansactionType
			   ,@SourceTable
			   ,@CIdentifier
			   ,@TRANS_DT
			   ,@PERIOD
			   ,@FY
			   ,@SAVEINIT
			   ,@fk_fydtluniq
			   -- 01/06/17 VL: Added functional currency fields
			   ,dbo.fn_GetPresentationCurrency()
			   ,dbo.fn_GetFunctionalCurrency())
			
				-- insert into GlTrans
				INSERT INTO GlTrans
			   (GLUNIQ_KEY
			   ,GL_NBR
			   ,DEBIT
			   ,CREDIT
			   ,CIDENTIFIER
			   ,SourceTable
			   ,SourceSubTable
			   ,cSubIdentifier
			   ,Fk_GLTRansUnique
			   -- 01/06/17 VL: Added functional currency fields
			   ,DEBITPR
			   ,CREDITPR)
			   SELECT  
			   GLUNIQ_KEY
			   ,GL_NBR
			   ,DEBIT
			   ,CREDIT
			   ,CIDENTIFIER
			   ,SourceTable
			   ,SourceSubTable
			   ,cSubIdentifier,Fk_GLTRansUnique
			   -- 01/06/17 VL: Added functional currency fields 
   			   ,DEBITPR
			   ,CREDITPR
			   FROM @GlTrans WHERE fk_gltransunique=@GLTRANSUNIQUE
			
			
				-- insert into GlTransDetails				
				INSERT INTO GlTransDetails 
			   (fk_gluniq_key 
			   ,Debit
			   ,Credit
			   ,cDrill 
			   ,cSubDrill 
			   ,TrGroupIdNumber 
			   ,Transactiontype
			   -- 01/06/17 VL: Added functional currency fields 
			   ,DEBITPR
			   ,CREDITPR
			   ) 
				SELECT T.GLUNIQ_KEY 
			   ,D.Debit
			   ,D.Credit
			   ,D.cDrill 
			   ,D.cSubDrill 
			   ,D.TrGroupIdNumber 
			   ,D.Transactiontype 
			   -- 01/06/17 VL: Added functional currency fields
			   ,D.DEBITPR
			   ,D.CREDITPR
				FROM @GlTrans T INNER JOIN @GlTransTutto D ON T.fk_GLTRansUnique= D.fk_GLTRansUnique 
					AND T.GLUNIQ_KEY= D.GLUNIQ_KEY  AND T.fk_gltransunique=@GLTRANSUNIQUE
				
				
				-- get next record
				FETCH NEXT FROM GltH 
					INTO @GLTRANSUNIQUE 
				   ,@TRansactionType 
				   ,@SourceTable
				   ,@CIdentifier
				   ,@TRANS_DT 
				   ,@PERIOD
				   ,@FY
				   ,@fk_fydtluniq ;
			END -- WHILE @@FETCH STATUS = 0
			CLOSE GlTH;
			DEALLOCATE GlTH;
			DELETE FROM GLReleased WHERE GLRELUNIQUE IN (SELECT GLRELUNIQUE FROM @GlTransTutto )
			
			END TRY
			BEGIN CATCH
				SELECT 
					@ErrorMessage = ERROR_MESSAGE() ;
				IF @@TRANCOUNT > 0
					ROLLBACK TRANSACTION;
					RAISERROR('Error occurred when releasing SCRAP transactions. Error %s',11,1,@ErrorMessage)
					RETURN -1
			END CATCH
			IF @@TRANCOUNT > 0
			COMMIT TRANSACTION;
	END --- ELSE @@ROWCOUNT<>0
	
				

END