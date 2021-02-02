-- Author:  Vijay G                                                 
-- Create date: 10/13/2019                                             
-- DescriptiON: Used to update sales order for newly created  assembly from ECO                                       
-- Modified Vijay G:11/27/2019 Update balance column by zero        
-- Modified Vijay G:11/27/2019 Delete records from  @SOPRICES        
-- Modified Vijay G:01/10/2020 Changes the size of columns of temp table     
-- Modified Vijay G:01/20/2020 Uncomment the code of inserting data into temp table  
-- Modified Vijay G:01/20/2020 For inserting new line number by mistake two times increased the number so one is removed from here   
-- Modified Vijay G:01/28/2020 Removed substraction of QTY and ACT_SHP_QT for new schedule line
-- EXEC [UpdateSalesOrderForECO] 'IFT2CS5JX5','KITGNNOPOR','S2477YOUUK'                                 
--==============================================================                              
CREATE PROCEDURE [dbo].[UpdateSalesOrderForECO]                                      
(                       
 @oldUniqKey VARCHAR(10),                                     
 @newUniqKey VARCHAR(10)  ,                                    
 @uniqEcNo VARCHAR(10)                                      
)                                       
AS                                                      
BEGIN                                           
                                      
DECLARE @ErrorMessage NVARCHAR(4000),@ErrorSeverity INT,@ErrorState INT                                         
                                    
SET NOCOUNT ON;                                          
BEGIN TRY                            
    BEGIN TRANSACTION                               
 DECLARE @SONOs TABLE(sono VARCHAR(10),ln VARCHAR(10))                          
 DECLARE @DUE_DTS TABLE(DUEDT_UNIQ varchar(10), QTY numeric(5) , ACT_SHP_QTY numeric(5))             
 -- Modified Vijay G:01/10/2020 Changes the size of columns of temp table                  
 DECLARE @SOPRICES TABLE(Quantity numeric(9,2), Price numeric(9,2),Extended numeric(13,2),PriceFC numeric(9,2),ExtendedFC numeric(13,2),Recordtype varchar(10),                      
 Sono varchar(10), Descriptio varchar(45), Plpricelnk varchar(10), NewPlpricelnk varchar(10), Uniqueln varchar(10), SaleTypeID varchar(10), Pl_gl_nbr varchar(13),                      
 Cog_gl_nbr varchar(13), Taxable bit, Flat bit,UniqSopricesTax varchar(10),Tax_id varchar(8),Tax_Rate varchar(5), Taxtype varchar(1),                      
 PtProd bit,PtFrt bit, StProd bit, StFrt bit, Sttx bit)                      
                                
 DECLARE @sono varchar(10), @ln varchar(10) ,@shipQTY NUMERIC(5) ,@serialYes BIT=0,@newWOQty NUMERIC(5),@uniquerout VARCHAR(10) ,@newLn VARCHAR(7),                      
 @newUniqlno VARCHAR(10) ,@copyOtherPrices bit=0 ,@QTY numeric(9,2)                                  
                         
 --SELECT @serialYes =SERIALYES FROM INVENTOR WHERE UNIQ_KEY=@oldUniqKey                              
                               
 INSERT INTO @SONOs (sono ,ln )                                         
 SELECT SONO,LINE_NO FROM ECSO                       
 WHERE UNIQECNO=@uniqEcNo                       
                              
 SELECT  @copyOtherPrices= COPYOTHPRC FROM ECMAIN WHERE UNIQECNO= @uniqEcNo                         
   -- SELECT @uniquerout= uniquerout FROM routingProductSetup WHERE Uniq_key=@newUniqKey AND isDefault=1                              
                                   
 WHILE (SELECT COUNT(*) From @SONOs) > 0                              
 BEGIN                              
  SELECT TOP 1 @sono= sono,@ln=ln FROM @SONOs                              
  SELECT @shipQTY= SHIPPEDQTY FROM SODETAIL WHERE SONO=@sono and LINE_NO = @ln                        
                            
IF(@shipQTY=0)                              
   BEGIN                              
      SET @newUniqlno=dbo.fn_GenerateUniqueNumber()                              
   SELECT @newLN=MAX(LINE_NO) + 1 FROM SODETAIL WHERE SONO =@sono                            
   --UPDATE WOENTRY SET UNIQUELN= @newUniqlno WHERE UNIQUELN IN(SELECT UNIQUELN FROM SODETAIL WHERE SONO=@sono AND LINE_NO=@ln)                                 
   UPDATE SODETAIL SET UNIQ_KEY=@newUniqKey WHERE SONO=@sono AND LINE_NO=@ln                              
   END       
ELSE                               
  BEGIN         
  -- Modified Vijay G:01/20/2020 For inserting new line number by mistake two times increased the number so one is removed from here                          
 SET @newUniqlno =dbo.fn_GenerateUniqueNumber()          
 SELECT @newLN=MAX(LINE_NO)                      
 FROM SODETAIL WHERE SONO =@sono                              
                        
 INSERT INTO SODETAIL         
  (SONO,UNIQUELN,LINE_NO,UNIQ_KEY,UOFMEAS,EACHQTY,ORD_QTY,SHIPPEDQTY,BALANCE,Sodet_Desc,TRANS_DAYS,FSTDUEDT,DELIFREQ,CATEGORY,        
  STATUS,W_KEY,ORIGINUQLN,PRJUNIQUE)                              
 SELECT SONO,@newUniqlno,RIGHT('000000'+ CONVERT(VARCHAR,@newLN + 1),7),@newUniqKey,UOFMEAS,EACHQTY,ORD_QTY-SHIPPEDQTY,0,ORD_QTY-SHIPPEDQTY,Sodet_Desc,                      
 TRANS_DAYS,FSTDUEDT,DELIFREQ,CATEGORY,'Open',W_KEY,ORIGINUQLN,PRJUNIQUE                              
 FROM SODETAIL                       
 WHERE SONO =@sono AND LINE_NO=@ln AND BALANCE<>0                    
                     
 UPDATE SODETAIL SET         
  -- Modified Vijay G:27/11/2019 Update balance column by zero        
 ORD_QTY=(SELECT SHIPPEDQTY FROM SODETAIL WHERE SONO=@sono AND LINE_NO=@ln),         
 BALANCE=0                               
 WHERE SONO=@sono AND LINE_NO=@ln AND  BALANCE<>0                               
 -- Modified Vijay G:01/28/2020 Removed substraction of QTY and ACT_SHP_QT for new schedule line                         
 INSERT INTO DUE_DTS        
 (SONO,DUE_DTS,SHIP_DTS,COMMIT_DTS,QTY,STDCHG,PRICHG,OTHCHG,JOBPRI,DAYMIN,LOTNO,QUOTE_SEL,START_DTS,ACT_SHP_QT,ON_SCHED,COMPL_DTS,UNIQUELN,DUEDT_UNIQ)                          
 SELECT SONO,DUE_DTS,SHIP_DTS,COMMIT_DTS,QTY,STDCHG,PRICHG,OTHCHG,JOBPRI,DAYMIN,LOTNO,QUOTE_SEL,                          
 START_DTS,0,ON_SCHED,COMPL_DTS,@newUniqlno,dbo.fn_GenerateUniqueNumber()                           
 FROM DUE_DTS                       
 WHERE UNIQUELN=(SELECT UNIQUELN FROM SODETAIL WHERE SONO=@sono AND LINE_NO=@ln)  AND QTY<>0   --AND ACT_SHP_QT<>0                      
                        
 UPDATE t set t.qty = t.ACT_SHP_QT                      
 FROM DUE_DTS t                       
 WHERE  UNIQUELN=(SELECT UNIQUELN FROM SODETAIL WHERE SONO=@sono AND LINE_NO=@ln) AND ACT_SHP_QT<>0 AND QTY<>0                                                       
                                   
 SELECT  @QTY=SUM(ACT_SHP_QT)         
 FROM DUE_DTS         
 WHERE UNIQUELN = (SELECT UNIQUELN FROM SODETAIL WHERE SONO=@sono AND LINE_NO=@ln)                      
                                      
 DELETE FROM DUE_DTS WHERE                       
 UNIQUELN=(SELECT UNIQUELN FROM SODETAIL WHERE SONO=@sono AND LINE_NO=@ln) AND ACT_SHP_QT =0                     
                   
 --Insert prices and taxes info  
 -- Modified Vijay G:01/20/2020 Uncomment the code of inserting data into temp table                       
 INSERT INTO @SOPRICES                       
 ( Quantity, Price,Extended,PriceFC,ExtendedFC,Sono, Descriptio,Recordtype, Plpricelnk,NewPlpricelnk, Uniqueln, SaleTypeID, Pl_gl_nbr,                      
  Cog_gl_nbr, Taxable, Flat,UniqSopricesTax, Tax_id, Tax_Rate, Taxtype, PtProd, PtFrt, StProd, StFrt, Sttx                      
 )                         
 SELECT                       
 CASE WHEN (@copyOtherPrices=1 AND Quantity > @QTY) OR RECORDTYPE='p' THEN  Quantity - @QTY ELSE 0  END AS QUANTITY,                     
 CASE WHEN @copyOtherPrices=1  OR RECORDTYPE='p' THEN PRICE  ELSE 0 END ,                      
 CASE WHEN (@copyOtherPrices=1  AND Quantity > @QTY) OR RECORDTYPE='p' THEN PRICE *(Quantity- @QTY) ELSE 0 END ,                      
 CASE WHEN @copyOtherPrices=1  OR RECORDTYPE='p' THEN PriceFC  ELSE 0 END ,                      
 CASE WHEN (@copyOtherPrices=1  AND Quantity > @QTY) OR RECORDTYPE='p' THEN PriceFC *(Quantity- @QTY) ELSE 0 END ,                      
 s.Sono,Descriptio,Recordtype, s.Plpricelnk,dbo.fn_GenerateUniqueNumber(),@newUniqlno,SaleTypeID,Pl_gl_nbr,Cog_gl_nbr, Taxable, Flat,                      
 UniqSopricesTax, Tax_id, Tax_Rate, Taxtype, PtProd, PtFrt, StProd, StFrt, Sttx                      
 FROM SOPRICES s                       
 LEFT JOIN SOPRICESTAX st ON s.PLPRICELNK=st.PLPRICELNK                        
 WHERE s.UNIQUELN = (SELECT UNIQUELN FROM SODETAIL WHERE SONO=@sono AND LINE_NO=@ln )                       
                      
  IF EXISTS (SELECT 1 FROM @SOPRICES)                   
  BEGIN                    
      --Used to add soprice newly added reamining qty prices                      
  INSERT INTO SOPRICES (Quantity, Price,Extended,PriceFC,ExtendedFC,Recordtype,Sono, Descriptio, Plpricelnk, Uniqueln, SaleTypeID, Pl_gl_nbr)                      
  SELECT Quantity, Price,Extended,PriceFC,ExtendedFC,Recordtype,Sono, Descriptio, NewPlpricelnk, Uniqueln, SaleTypeID, Pl_gl_nbr                      
  FROM @SOPRICES                       
                      
  IF EXISTS (SELECT 1 FROM @SOPRICES WHERE UniqSopricesTax<>NULL OR UniqSopricesTax<>'')                    
  --Used to add soprice taxes from newly added prices                
  BEGIN                      
   INSERT INTO SOPRICESTAX                       
   (UniqSopricesTax, Sono, Uniqueln, Plpricelnk, Tax_id, Tax_Rate, Taxtype, PtProd, PtFrt, StProd, StFrt, Sttx)                      
   SELECT UniqSopricesTax, Sono,Uniqueln,NewPlpricelnk,Tax_id,Tax_Rate,Taxtype, PtProd, PtFrt, StProd, StFrt, Sttx                      
   FROM @SOPRICES                       
  END                       
 END                    
  --Update SOPRICES                      
  UPDATE s SET s.Quantity = CASE WHEN (@copyOtherPrices=1 AND s.Quantity > @QTY) OR s.RECORDTYPE='p' THEN @QTY ELSE s.Quantity END ,                      
  s.EXTENDED =CASE WHEN (@copyOtherPrices=1 AND s.Quantity > @QTY) OR s.RECORDTYPE='p' THEN @QTY * s.PRICE ELSE s.PRICE * s.Quantity END                      
  FROM SOPRICES s                       
  WHERE UNIQUELN = (SELECT UNIQUELN FROM SODETAIL WHERE SONO=@sono AND LINE_NO=@ln )                       
   END                                   
  DELETE FROM @SONOs where sono=@sono         
-- Modified Vijay G:27/11/2019 Delete records from  @SOPRICES        
  DELETE FROM @SOPRICES where sono=@sono                              
 END        
 COMMIT TRANSACTION                    
END TRY                                   
BEGIN CATCH                                                                  
 IF @@TRANCOUNT > 0                   
 ROLLBACK                                
     SELECT @ErrorMessage = ERROR_MESSAGE(),                                        
        @ErrorSeverity = ERROR_SEVERITY(),                                        
        @ErrorState = ERROR_STATE();                                        
  RAISERROR (@ErrorMessage,                                        
               @ErrorSeverity,                                       
         @ErrorState                                       
               );                                                            
END CATCH                                        
END