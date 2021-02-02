-- =============================================                        
-- Author:  Suraj Patil,Aloha                        
-- Create date: 11/01/2013                        
-- Description: Update PO details          
    
-- Author:  Suraj Patil,Aloha    
-- Modify date: 03/12/2014    
-- Description: Update orgCommitDate,requestDate,schduleQty, PO Total  

-- Suraj Aloha, Update procedure for change CO when only Delivery Schedule Date's and note is changed
--Suraj Aloha, Update procedure for use POUNIQUE instead Ponum.
--- 04/14/15 YS change "location" column length to 256
-- =============================================                        
CREATE PROCEDURE [dbo].[MnxPODetailsUpdate]               
 @balance     NUMERIC(10,2),    
 @coNumber     NUMERIC(3,0),    
 @changeHistoryNote VARCHAR(max),    
 @flgOrderPriceUpdate BIT,           
 @glNumber    CHAR(13),                       
 @isCancel    BIT,    
 @isFirm    BIT,    
 @isFirstarticle  BIT,                        
 --@isFreightInclude  BIT,                        
 @isInspExcept   BIT,                
 --@isStatusChanged BIT,   
 --- 04/14/15 YS change "location" column length to 256         
 @location       VARCHAR(256),                   
 @orderPrice   NUMERIC(13,5),                        
 @orderQuantity   NUMERIC(10,2),                        
 @orderUOM    CHAR(4),                  
 @orgCommitDate smallDatetime,    
 @overage    NUMERIC(5,2),                        
 @poNum     CHAR(15),                   
 @poStatus  CHAR(8),
 @poUNIQUE     CHAR(10),                         
 @PriceUniqKey   CHAR(10),                        
 @purchTime    NUMERIC(3,0),                        
 @purchUnit    CHAR(2),                     
 @requestDate   smallDatetime,    
 @requestTp    CHAR(10),        
 @schdDate      smallDatetime,              
 @schdNotes text,                     
 @schduleQty    NUMERIC(10,2),    
 @stockQuantity   NUMERIC(10,2),    
 @suplarPartNo   CHAR(30),          
 @uniqDetNo    CHAR(10),                      
 @uniqKey    CHAR(10),                        
 @uniqLnNo    CHAR(10),                        
 @uniqMfgrHD   CHAR(10),            
 @uniqWh       CHAR(10),               
 @workProjNumber  CHAR(10)                      
AS                        
BEGIN                  
      
DECLARE @getReceivingTaxData TABLE(TAX_RATE NUMERIC(5,4),TAXDESC CHAR(25), TAX_ID CHAR(8), LINKADD CHAR(10), UNQSHIPTAX CHAR(10), TAXTYPE CHAR(1), RECORDTYPE CHAR(1))        
      
DECLARE  @getPOTotalData TABLE(PO_Total NUMERIC(12,2),TaxTotal NUMERIC(10,2))       
      
BEGIN TRANSACTION BEGIN TRY;                                
                                
--Update PO Items                               
 UPDATE dbo.POITEMS                                 
 SET                                
    ord_qty  = @orderQuantity,                                
    s_ord_qty = @stockQuantity,                                
    pur_uofm  = @orderUOM,                                
    costeach  = @orderPrice,                                
    overage  = @overage,                                
    lcancel  = @isCancel,                                
    firstarticle = @isFirstarticle,                                
    isfirm  = @isFirm,                                
    INSPEXCEPT = @isInspExcept,                                
    UniqMfSp  = @suplarPartNo                                
 WHERE                                
    UNIQLNNO  = @uniqLnNo
                                      
--Update  Purchase Info and Inspection                               
 UPDATE dbo.INVENTOR                                 
 SET                                
    Pur_lTime = @purchTime,                                
    pur_lunit = @purchUnit                                
 WHERE                                   
    UNIQ_KEY  = @uniqKey                                
      
 --Update  POMAIN table
 UPDATE dbo.POMAIN         
  SET                    
	POSTATUS = @poStatus,            
	CONUM=@coNumber,
	APPVNAME='',         --Clear PO Approve details on PO Edit
	FINALNAME=''
  WHERE                                   
	POUNIQUE = @poUNIQUE  
                                  
--Update Contract price if User agree START                              
    IF (@flgOrderPriceUpdate='1')                              
  BEGIN                                
   UPDATE dbo.CONTPRIC                                
   SET                                
		PRICE=@orderPrice                                
   WHERE                                
		PRIC_UNIQ=@PriceUniqKey                                
  END                                                                                  
             
 --Update Delivery Information                               
 UPDATE dbo.POITSCHD                              
 SET                              
	REQUESTTP   = @requestTp,                              
	WOPRJNUMBER = @workProjNumber,                  
	GL_NBR   = @glNumber,                  
	LOCATION   = @location,                  
	UNIQWH   = @uniqWh,                
	SCHD_DATE= @schdDate,                
	SCHDNOTES=@schdNotes,              
	REQ_DATE=@requestDate,              
	ORIGCOMMITDT=@orgCommitDate,              
	SCHD_QTY=@schduleQty,              
	BALANCE=@balance            
 WHERE                                
	UNIQDETNO = @uniqDetNo
	
--Get PO total and update in POMain   
 INSERT INTO @getReceivingTaxData(
				TAX_RATE,TAXDESC,
				TAX_ID,
				LINKADD,
				UNQSHIPTAX,
				TAXTYPE,
				RECORDTYPE
		)    
 EXEC ReceivingTaxView 
    
 INSERT INTO @getPOTotalData   
 SELECT 
		ISNULL(SUM(ROUND((COSTEACH * ORD_QTY),2)),0.00) + pomain.SHIPCHG AS PO_Total ,
		SUM(ROUND((CostEach * Ord_qty *
			CASE WHEN Poitems.IS_TAX = 1 THEN 
					ISNULL(T.TaxRate,0.00)
			ELSE 
					0.00 
			END 
		)/100,2))+
			CASE WHEN Pomain.IS_SCTAX=1 THEN 
					ROUND((PoMain.ShipChg * PoMain.ScTaxPct)/100,2)
			ELSE 
					0.00 
			END    
  AS TaxTotal  
  FROM POITEMS INNER JOIN POMAIN ON Poitems.PONUM=pomain.ponum    
  OUTER APPLY     
  (SELECT linkadd,isnull(SUM(TAX_RATE),0.0000) as TaxRate    
   FROM @getReceivingTaxData INNER JOIN Pomain on Linkadd=i_link WHERE Pomain.Ponum=@poNum GROUP BY LinkAdd) T    
   WHERE Poitems.Ponum=@poNum     
  AND LCANCEL = 0    
  GROUP BY t.TaxRate,Pomain.IS_SCTAX ,pomain.SHIPCHG,pomain.SCTAXPCT     
  
 UPDATE dbo.POMAIN                             
 SET        
		POTOTAL = (SELECT PO_Total FROM @getPOTotalData),  
		POTAX = (SELECT TaxTotal FROM @getPOTotalData),
		--Calculated PO Total is update in change Hist Note
		CurrChange=REPLACE(@changeHistoryNote,'POTotalPlaceHolder',(SELECT cast(PO_Total as decimal(10,2)) FROM @getPOTotalData))
 WHERE                               
		POUNIQUE = @poUNIQUE                             
                        
END TRY                          
                          
BEGIN CATCH                          
 RAISERROR('Error occurred in updating PO Details. This operation will be cancelled.',1,1)  IF @@TRANCOUNT > 0                          
  ROLLBACK TRANSACTION;                          
END CATCH                             
IF @@TRANCOUNT > 0                          
    COMMIT TRANSACTION;                          
END 