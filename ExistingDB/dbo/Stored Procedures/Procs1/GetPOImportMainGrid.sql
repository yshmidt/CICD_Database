-- =============================================  
-- Author:Satish B  
-- Create date: 5/30/2018  
-- Description : Get po import main grid data  
-- 07/21/2020 Satyawan H: Modified PO status to uppercase
-- exec GetPOImportMainGrid '','','',1,100,1  
-- =============================================  
CREATE PROCEDURE GetPOImportMainGrid  
	@poNumber char(15)='',  
	@supplier char(30) ='',  
	@buyer char(10) ='',  
	@startRecord int =1,  
	@endRecord int =10,   
	@outTotalNumberOfRecord int OUTPUT  
AS  
BEGIN  
     SET NOCOUNT ON    
  SELECT COUNT(PONumber) AS RowCnt -- Get total counts   
    INTO #tImportData  
    FROM ImportPOMain   
     WHERE (@poNumber IS NULL OR @poNumber='' OR ImportPOMain.PONumber like '%'+RTRIM(@poNumber)+'%')  
        AND (@supplier IS NULL OR @supplier='' OR ImportPOMain.SUPPLIER like '%'+RTRIM(@supplier)+'%')  
        AND (@buyer IS NULL OR @buyer='' OR ImportPOMain.BUYER like '%'+RTRIM(@buyer)+'%')  
  
  SELECT POImportId   
  ,Upper(Status) Status -- 07/21/2020 Satyawan H: Modified PO status to uppercase 
  ,CompleteDate   
  ,CompletedBy   
  ,Message   
  ,IsValidated   
  ,PONumber   
  ,Supplier   
  ,Buyer   
  ,Priority   
  ,PODate   
  ,ConfTo  
  ,ShipChgAMT    
  ,IS_SCTAX    
  ,SC_TAXPCT    
  ,ShipCharge  
  ,ShipVia  
  ,Fob    
  ,LfreightInclude  
  ,PONote  
  ,Terms    
  ,CLINK  
  ,RLINK  
  ,BLINK  
  ,ILINK  
  ,Line.lineCount AS NetLineItem   
  FROM ImportPOMain  
  OUTER APPLY (select COUNT (Distinct(RowId)) AS lineCount from ImportPODetails where fkPOImportId = ImportPOMain.POImportId) Line  
  WHERE (@poNumber IS NULL OR @poNumber='' OR ImportPOMain.PONumber like '%'+RTRIM(@poNumber)+'%')  
        AND (@supplier IS NULL OR @supplier='' OR ImportPOMain.SUPPLIER like '%'+RTRIM(@supplier)+'%')  
        AND (@buyer IS NULL OR @buyer='' OR ImportPOMain.BUYER like '%'+RTRIM(@buyer)+'%')  
           AND ImportPOMain.Status<>'IMPORTED'  
     ORDER BY PONumber DESC   
  OFFSET(@startRecord-1) ROWS  
  FETCH NEXT @EndRecord ROWS ONLY;  
  SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tImportData)    
END                       