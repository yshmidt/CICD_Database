-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: 09/14/2019  
-- Description: This SP will be used to post the transactions selected by the user  
-- Parameters:  
-- 1. @tGlRelease - userd defined table type when user selects which transaction to post on the screen only those transactions will be sent to the SP  
--   columns list:  
--     glrelunique primary keys from glreleased table,   
--     trans_dt most of the time will be the same as the one in the glreleased, but user has ability to modify on the screen  
--     fy,[period],fk_fydtluniq these columns are default to the values in the glreleased table, but if thats_dt is modified then this columns will be updated as well.  
-- 2. @transactionType - type of the transaction passed from the screen. If the user select to post all transactions, the posting will take place for each transaction separate  
-- 3. @userid - userid of the user who is completing the posting procedure  
-- =============================================  
CREATE PROCEDURE GlPost   
 -- Add the parameters for the stored procedure here  
  @tGlRelease tGlReleaseUnique READONLY,      
  @transactionType nvarchar(50),  
  @userid uniqueidentifier   
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 -- check if the system Foreign Currency activated  
 DECLARE @lFCInstalled bit ;  
 SELECT @lFCInstalled = dbo.fn_IsFCInstalled();  
 /* error handling */  
  
 DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;   
  
 --- temp tables   
 IF OBJECT_ID('tempdb..#GlTransTutto') IS NOT NULL  
 DROP TABLE #GlTransTutto  
  
 IF OBJECT_ID('tempdb..#transno') IS NOT NULL  
 drop table #transno  
  
 IF OBJECT_ID('tempdb..#glTransProto') IS NOT NULL  
 drop table #glTransProto  
    
 if OBJECT_ID('tempdb..#GetAllGlReleased') is not null  
 DROP TABLE #GetAllGlReleased  
    -- Insert statements for procedure here  
    -- 07/09/12 YS for JE group by cDrill, not trans date, Really want to have transaction per JE. Transaction date will not have time. Maybe need to change that also.  
    -- 10/23/13 YS same problem as JE with checks. No time saved for transaction date  
 --   08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill  
  
 SELECT [GLRELUNIQUE]  
--   08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill  
      ,RANKN= CASE WHEN TransactionType IN ('INVTREC', 'INVTISU', 'INVTTRNS') THEN DENSE_RANK () OVER (order by transactiontype,sourcetable,CSubDrill,Trans_dt)   
    ELSE DENSE_RANK () OVER (order by transactiontype,sourcetable,CDrill) END  
--   08/03/16 YS Penang reported  another transaction, 'PURCH' type that grouped transactions from different invoices together. I am changing all the trnasactions accept invenotry to group by cdrill. Inventory by cdrill and cSubdrill  
      ,[TrGroupIdNumber]=CASE WHEN TransactionType IN ('INVTREC', 'INVTISU', 'INVTTRNS') THEN ROW_NUMBER () OVER (partition by transactiontype,sourcetable,CSubDrill,Trans_dt order by cdrill,[GroupIdNumber])   
  ELSE ROW_NUMBER () OVER (partition by transactiontype,sourcetable,cDrill order by [GroupIdNumber]) END  
   ,[TRANS_DT]  
      ,[PERIOD]  
      ,[FY]  
      ,Glreleased.GL_NBR  
      ,Gl_nbrs.GL_DESCR  
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
      ,CAST(0 as Bit) as lSelect  
   ,Atduniq_key  
   -- functional currency columns  
   ,DebitPR, CreditPR, PRFcused_uniq, FuncFcused_uniq  
   INTO #GetAllGlReleased  
   FROM [dbo].[GLRELEASED] INNER JOIN GL_NBRS ON GLRELEASED.GL_NBR=GL_NBRS.GL_NBR   
   
  
 SELECT GetAllGlReleased.GLRELUNIQUE   
      ,GetAllGlReleased.RankN   
      ,GetAllGlReleased.TrGroupIdNumber   
      ,[@tGlRelease].TRANS_DT   
      ,[@tGlRelease].[PERIOD]   
      ,[@tGlRelease].FY   
      ,GetAllGlReleased.GL_NBR   
      ,GetAllGlReleased.GL_Descr   
      ,GetAllGlReleased.DEBIT   
      ,GetAllGlReleased.CREDIT   
      ,GetAllGlReleased.SAVEINIT   
      ,GetAllGlReleased.CIDENTIFIER   
      ,GetAllGlReleased.LPOSTEDTOGL   
      ,GetAllGlReleased.CDRILL   
      ,GetAllGlReleased.TransactionType   
      ,GetAllGlReleased.SourceTable   
      ,GetAllGlReleased.SourceSubTable   
      ,GetAllGlReleased.cSubIdentifier   
      ,GetAllGlReleased.cSubDrill   
      ,[@tGlRelease].fk_fydtluniq   
      ,GetAllGlReleased.GroupIdNumber   
      ,GetAllGlReleased.lSelect   
      ,cast('' as char(10)) as GLUNIQ_KEY  
      ,CAST('' as char(10)) as Fk_GLTRansUnique   
      ,DEBITPR   
    ,CREDITPR   
   ,PRFcused_uniq   
    ,FuncFcused_uniq   
   INTO #GlTransTutto   
   FROM #GetAllGlReleased GetAllGlReleased INNER JOIN @tGlRelease  ON GetAllGlReleased.glrelunique= [@tGlRelease].glrelunique   
 WHERE GetAllGlReleased.TransactionType= @TransactionType   
 ORDER BY GetAllGlReleased.cDrill,GetAllGlReleased.Trans_dt  
   
 --- Validations  
 IF EXISTS (SELECT 1 FROM #GlTransTutto    
  WHERE Gl_nbr is null OR Gl_nbr='' OR FY is null OR FY='' OR [Period] is null OR Period=0)    
 RAISERROR('Some transactions for are missing G/L Number or Fiscal Year and Period',1,1)  
  
  
 IF (@lFCInstalled = 0)  
 BEGIN  
  IF EXISTS (SELECT SUM(Debit) as Sum_debit,SUM(Credit) as SUM_credit, rankN   
   FROM  #GlTransTutto   
  GROUP BY RankN   
  HAVING  SUM(Debit) <> SUM(Credit) )  
  
  RAISERROR('Some transactions are out of balance. The posting is termimated',1,1)  
 END   
 IF (@lFCInstalled = 0)  
 BEGIN  
  IF EXISTS (SELECT SUM(Debit) as Sum_debit,SUM(Credit) as SUM_credit, SUM(DebitPR) as Sum_debitPR ,SUM(CreditPR) as SUM_creditPR, rankN   
   FROM  #GlTransTutto   
  GROUP BY RankN   
  HAVING (SUM(Debit) <> SUM(CREDIT)   
  OR SUM(debitPr) <> SUM(creditpr)))  
  
  RAISERROR('Some transactions are out of balance. The posting is termimated',1,1)  
 END   
 --- now split  
  
 SELECT DISTINCT RankN,CAST(' ' as char(10)) as GLTRansUnique,TRansactionType,SourceTable,cIdentifier,  
  Trans_dt,Period,Fy,@userid as userid,  
  fk_fydtluniq, PRFcused_uniq, FuncFcused_uniq   
  INTO #transno  
  FROM #GlTransTutto   
   
 -- create unique transaction for each transaction group  
     
   UPDATE #TransNo SET GLTRansUnique=dbo.fn_GenerateUniqueNumber();  
   UPDATE #GlTransTutto SET fk_GLTRansUnique=[#transno].GLTRansUnique FROM #TransNo WHERE #GlTransTutto.Rankn=[#TransNo].RankN; 
  
 --select * from #GlTransTutto  
 --- get records for the gltrans table  
   
 SELECT CAST(' ' as char(10)) as GLUNIQ_KEY,RankN   
           ,GL_NBR  
           ,SUM(DEBIT) as Debit  
           ,SUM(CREDIT) as Credit  
           ,CIDENTIFIER  
           ,SourceTable  
           ,SourceSubTable  
           ,cSubIdentifier,Fk_GLTRansUnique   
           ,SUM(DEBITPR) as DebitPR  
           ,SUM(CREDITPR) as CreditPR  
           ,PrFcused_uniq   
           ,FuncFcused_uniq   
           INTO #glTransProto  
     FROM #GlTransTutto   
     GROUP BY RankN,GL_Nbr,CIDENTIFIER,SourceTable,SourceSubTable,cSubIdentifier ,Fk_GLTRansUnique, PrFcused_uniq, FuncFcused_uniq   
       
         
    UPDATE #glTransProto SET GLUNIQ_KEY=dbo.fn_GenerateUniqueNumber(); 
  
    UPDATE #GlTransTutto SET GLUNIQ_KEY=[#glTransProto].GLUNIQ_KEY FROM #glTransProto WHERE [#GlTransTutto].Rankn=[#glTransProto].RankN    
  AND [#GlTransTutto].GL_Nbr=[#glTransProto].GL_Nbr   
  AND [#GlTransTutto].CIDENTIFIER=[#glTransProto].CIDENTIFIER   
  AND [#GlTransTutto].SourceTable=[#glTransProto].SourceTable   
  AND [#GlTransTutto].SourceSubTable=[#glTransProto].SourceSubTable   
     AND [#GlTransTutto].cSubIdentifier=[#glTransProto].cSubIdentifier      
     
   
 --select * from #GlTransTutto  
 BEGIN TRY  
 BEGIN TRANSACTION  
  /*  insert into GltransHeader */  
  
  INSERT INTO GLTRANSHEADER   
           (GLTRANSUNIQUE   
           ,TRansactionType  
           ,SourceTable  
           ,CIdentifier  
            ,TRANS_DT  
           ,[PERIOD]  
           ,FY  
           ,SAVEuserid  
           ,fk_fydtluniq  
           ,PRFcused_uniq  
           ,FuncFcused_uniq)  
  SELECT   
           GLTRANSUNIQUE   
           ,TRansactionType   
           ,SourceTable  
           ,CIdentifier  
           ,TRANS_DT   
           ,[PERIOD]  
           ,FY  
           ,@userid  
           ,fk_fydtluniq  
           ,PRFcused_uniq  
           ,FuncFcused_uniq FROM #transno   
    
  /*  insert into Gltrans */  
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
           ,DebitPR  
           ,CreditPR  
           FROM #glTransProto   
     ---ORDER BY Fk_GLTRansUnique   
  
   
   
  /*now insert gltransDetails*/  
   
  INSERT INTO GlTransDetails   
           (fk_gluniq_key   
           ,Debit  
           ,Credit  
           ,cDrill   
           ,cSubDrill   
           ,TrGroupIdNumber   
           ,Transactiontype   
           ,CreditPR  
           ,DebitPR  
           )   
  SELECT GlTrans.GLUNIQ_KEY   
           ,[#GlTransTutto].Debit  
           ,[#GlTransTutto].Credit  
           ,[#GlTransTutto].cDrill   
           ,[#GlTransTutto].cSubDrill   
           ,[#GlTransTutto].TrGroupIdNumber   
           ,[#GlTransTutto].Transactiontype   
           ,[#GlTransTutto].CreditPR  
           ,[#GlTransTutto].DebitPR  
            FROM GlTrans INNER JOIN [#GlTransTutto] ON GlTrans.fk_GLTRansUnique= [#GlTransTutto].fk_GLTRansUnique   
   AND GlTrans.GLUNIQ_KEY= [#GlTransTutto].GLUNIQ_KEY   
     
  /* delete records from glreleased */  
  DELETE FROM glreleased WHERE exists (select 1 from [#GlTransTutto] where  [#GlTransTutto].GLRELUNIQUE =glreleased.GLRELUNIQUE )  
 IF @@TRANCOUNT>0  
  COMMIT  
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
 IF OBJECT_ID('tempdb..#GlTransTutto') IS NOT NULL  
  DROP TABLE #GlTransTutto  
  
 IF OBJECT_ID('tempdb..#transno') IS NOT NULL  
  drop table #transno  
  
 IF OBJECT_ID('tempdb..#glTransProto') IS NOT NULL  
  drop table #glTransProto  
   
 if OBJECT_ID('tempdb..#GetAllGlReleased') is not null  
  DROP TABLE #GetAllGlReleased   
  
END  