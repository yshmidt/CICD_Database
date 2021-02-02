-- =============================================  
-- Author:  Yelena Shmidt   
-- Create date: 01/23/2012   
-- Description: Generate Autodistribution records for given period  
-- 04/03/13 YS move declaration for the @tJe before ID @@ROWCOUNT In case no auto distribution found will return an empty set, instead of no set at all  
-- 12/09/16 VL added presentation currency fields  
-- 2/13/2019 Nilesh Sa If period end date is past than todays date then generating date will be end date of the period
-- =============================================  
CREATE PROCEDURE [dbo].[SP_GenerateAutoDistr]  
 -- Add the parameters for the stored procedure here  
 @nPeriod int=0,@cFy char(4)=' ',@cSaveinit char(8)=' '  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
 -- if no parameters sent use current period and fy  
 SELECT @nPeriod = CASE WHEN @nPeriod=0 THEN Glsys.CUR_PERIOD ELSE @nPeriod  END ,  
     @cFy = CASE WHEN @cFy=' ' THEN Glsys.CUR_FY  ELSE @cFy END FROM GLSYS   
 EXEC sp_RecalculateTB   
 DECLARE @Je_no [numeric](6,0),@JEOHKEY char(10)=' ',@nCount integer =0  
 -- 12/09/16 VL added presentation currency fields  
 DECLARE @JeAutoD Table (gl_nbr char(13),Debit numeric(14,2),Credit numeric(14,2),nearnvalue numeric(14,2), Reason varchar(max),gladetkey char(10),fkglahdr char(10), DebitPR numeric(14,2),CreditPR numeric(14,2),nearnvaluePR numeric(14,2))   
   
 --04/03/13 YS move declaration for the @tJe here. In case no auto distribution found will return an empty set, instead of no set at all  
 DECLARE @tJeno table (fkglahdr char(10)  
       ,[Je_no] numeric(6,0) default 0   
       ,[TRANSDATE] smalldatetime  
       ,[SAVEINIT] char(8)  
       ,[REASON] varchar(max)  
       ,[STATUS] char(12)  
       ,[JETYPE] char(10)  
       ,[PERIOD] numeric(2,0)  
       ,[FY] char(4)  
       ,[JEOHKEY] char(10)  
       ,nRecord int );  
   
 INSERT INTO @JeAutoD SELECT gladdet.GL_NBR,   
 CASE WHEN A.END_BAL>0.00 AND Credit <> 0.00 THEN ROUND(Credit * isnull(A.end_bal,0)/100,2)   
  WHEN A.END_BAL<0.00 AND CREDIT = 0.00 THEN ROUND(Debit* isnull(ABS(A.end_bal),0)/100,2)   
  ELSE 0.00 END as Debit,  
 CASE WHEN A.end_bal>0.00 AND Debit<>0.00 THEN ROUND(Debit * isnull(A.end_bal,0)/100,2)   
  WHEN A.END_BAL <0.00 AND DEBIT=0.00 THEN ROUND(Credit * isnull(ABS(A.end_bal),0)/100,2)   
  ELSE 0.00 END as Credit,ISNULL(A.end_bal,0),  
  gladhdr.ADDESCR,GLADDET.GLADETKEY,GLADDET.FKGLAHDR,  
 -- 12/09/16 VL added presentation currency fields   
 CASE WHEN A.END_BALPR>0.00 AND CreditPR <> 0.00 THEN ROUND(CreditPR * isnull(A.end_balPR,0)/100,2)   
  WHEN A.END_BALPR<0.00 AND CREDITPR = 0.00 THEN ROUND(DebitPR* isnull(ABS(A.end_balPR),0)/100,2)   
  ELSE 0.00 END as DebitPR,  
 CASE WHEN A.end_balPR>0.00 AND DebitPR<>0.00 THEN ROUND(DebitPR * isnull(A.end_balPR,0)/100,2)   
  WHEN A.END_BALPR <0.00 AND DEBITPR=0.00 THEN ROUND(CreditPR * isnull(ABS(A.end_balPR),0)/100,2)   
  ELSE 0.00 END as CreditPR,ISNULL(A.end_balPR,0)  
 FROM GLADHDR inner join GLADDET on gladhdr.GLAHDRKEY =gladdet.FKGLAHDR   
 INNER JOIN   
  -- 12/09/16 VL added presentation currency fields  
  (SELECT View_GlAccts.gl_nbr,FISCALYR,PERIOD,END_BAL ,GLADDET.FKGLAHDR, END_BALPR  
  FROM View_GlAccts inner join GLADDET on View_GlAccts.GL_NBR =gladdet.GL_NBR    
  where View_GlAccts.FISCALYR =@cFy   
  and View_glaccts.PERIOD=@nPeriod   
  and gladdet.Debit=100 and END_BAL<>0.00) as A ON GLADDET.FKGLAHDR =A.FKGLAHDR  
 where (gladhdr.POST_FY=' ' OR gladhdr.POST_FY<@cFy OR (gladhdr.POST_FY=@cFy and gladhdr.LAST_POST <@nPeriod)) ;  
   
 --select * from @JeAutoD order by FKGLAHDR  
   
 IF @@ROWCOUNT<>0  
 BEGIN  
  ;WITH Diff as  
  (  
   -- 12/09/16 VL added presentation currency fields   
   select sum(debit-credit) as diff, sum(debitPR-creditPR) as diffPR from @JeAutoD having (SUM(debit-credit)<>0 OR SUM(debitPR-creditPR)<>0)  
  )  
  UPDATE @JeAutoD   
   SET  debit=CASE WHEN diff.diff>0 then debit-isnull(diff.diff,0) else debit+isnull(abs(diff),0) end,  
    -- 12/09/16 VL added presentation currency fields   
     debitPR=CASE WHEN diff.diffPR>0 then debitPR-isnull(diff.diffPR,0) else debitPR+isnull(abs(diffPR),0) end   
  from diff cross join @JeAutoD t join (SELECT  TOP 1 gladetkey FROM @JeAutoD t2 where (t2.debit<>0 OR t2.debitPR<>0) order by debit asc) T1 on t1.gladetkey=t.gladetkey ;  
  ---SELECT * from @JeAutoD  
  -- find total earning  
           
  -- populate JE table  
   
  -- find number of unique FKGLAHDR  
  --04/03/13 YS move declaration for the @tJe up above IF @@ROWCOUNT. In case no auto distribution found will return an empty set, instead of no set at all  
   
  --DECLARE @tJeno table (fkglahdr char(10)  
  --     ,[Je_no] numeric(6,0) default 0   
  --     ,[TRANSDATE] smalldatetime  
  --     ,[SAVEINIT] char(8)  
  --     ,[REASON] varchar(max)  
  --     ,[STATUS] char(12)  
  --     ,[JETYPE] char(10)  
  --     ,[PERIOD] numeric(2,0)  
  --     ,[FY] char(4)  
  --     ,[JEOHKEY] char(10)  
  --     ,nRecord int );  

  -- 2/13/2019 Nilesh Sa If period end date is past than todays date then generating date will be end date of the period
   DECLARE @periodEndDate smalldatetime,@transDate smalldatetime = GETDATE();

   SELECT @periodEndDate = GLFYRSDETL.ENDDATE FROM GLFISCALYRS 
   INNER JOIN GLFYRSDETL ON GLFISCALYRS.FY_UNIQ = GLFYRSDETL.FK_FY_UNIQ
   WHERE GLFISCALYRS.FISCALYR = @cFy AND GLFYRSDETL.PERIOD = @nPeriod;

   IF @transDate > @periodEndDate
   BEGIN
	SET @transDate = @periodEndDate;
   END

  ;WITH JeHdr AS  
   (SELECT DISTINCT AD.fkglahdr  
       ,@cSaveinit as Saveinit  
       ,AD.Reason    
       ,'NOT APPROVED' as Status  
       ,'AUTO DISTR' AS JeType  
       ,@nPeriod as Period  
       ,@cFy AS Fy  
    FROM @JeAutoD AD )  
  INSERT INTO @tJeno (fkglahdr   
       ,[TRANSDATE]   
       ,[SAVEINIT]  
       ,[REASON]   
       ,[STATUS]   
       ,[JETYPE]   
       ,[PERIOD]   
       ,[FY]   
       ,[JEOHKEY]   
       ,nRecord )  
  SELECT DISTINCT JH.fkglahdr  
       ,@transDate -- 2/13/2019 Nilesh Sa If period end date is past than todays date then generating date will be end date of the period
       ,@cSaveinit   
       ,JH.Reason    
       ,JH.Status   
       ,JH.JeType   
       ,JH.Period    
       ,JH.Fy   
       ,dbo.fn_GenerateUniqueNumber()  
       ,ROW_NUMBER() OVER(ORDER BY fkglahdr)   
       FROM JeHdr JH     
  set @ncount=@@ROWCOUNT  
    
  WHILE @ncount<>0  
  BEGIN  
   EXEC GetNextJeno @Je_no OUTPUT   
   UPDATE @tJeno SET Je_no=@Je_no where nRecord=@nCount  
   set @ncount=@ncount-1   
  END  
    
    
    
  BEGIN TRANSACTION  
  --EXEC GetNextJeno @Jeno OUTPUT   
  --SET @JEOHKEY=dbo.fn_GenerateUniqueNumber()  
  INSERT INTO [GLJEHDRO]  
           ([Je_no]  
           ,[TRANSDATE]  
           ,[SAVEINIT]  
           ,[REASON]  
           ,[STATUS]  
           ,[JETYPE]  
           ,[PERIOD]  
           ,[FY]  
           ,[JEOHKEY])  
     SELECT [Je_no]  
           ,[TRANSDATE]  
           ,[SAVEINIT]  
           ,[REASON]  
           ,[STATUS]  
           ,[JETYPE]  
           ,[PERIOD]  
           ,[FY]  
           ,[JEOHKEY] FROM @tJeno   
          
  INSERT INTO [GLJEDETO]  
           ([GL_NBR]  
           ,[DEBIT]  
           ,[CREDIT]  
           ,[JEODKEY]  
           ,[FKJEOH]  
     -- 12/09/16 VL added presentation currency fields   
     ,[DEBITPR]  
           ,[CREDITPR])  
  SELECT Ad.GL_NBR   
      ,Ad.DEBIT  
   ,Ad.CREDIT  
           ,dbo.fn_GenerateUniqueNumber()  
           ,Je.JEOHKEY  
     ,Ad.DEBITPR  
     ,Ad.CREDITPR FROM @JeAutoD AD INNER JOIN @tJeno Je ON Ad.fkglahdr=Je.fkglahdr  
           
           
        -- update GLADHDR  
        UPDATE GLADHDR SET LAST_POST = @nPeriod ,POST_FY = @cFy,POST_DT =GETDATE() FROM @tJeno JE WHERE GLADHDR.GLAHDRKEY = je.fkglahdr     
        COMMIT     
  --04/03/13 YS move declaration for the @tJe outside of if @@ROWCOUNT<>0 . In case no auto distribution found will return an empty set, instead of no set at all  
  -- move select outside of END --- @@ROWCOUNT<>0   
   
    
    
 END --- @@ROWCOUNT<>0   
 SELECT JEOHKEY,Je_no FROM @tJeno  
       
       
END