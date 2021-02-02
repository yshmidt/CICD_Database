  
-- =============================================      
-- Author: Shivshankar P      
-- Create date: 04/29/2020     
-- Description: Validate InvtImportHeader data     
-- EXEC ValidateInvtImportHeader @importId ='F759F4CE-2B28-4BD9-95FB-F31EA950E7EB'      
-- =============================================  
CREATE PROCEDURE [dbo].[ValidateInvtImportHeader]         
 -- Add the parameters for the stored procedure here      
 @importId UNIQUEIDENTIFIER  
AS      
BEGIN      
 -- SET NOCOUNT ON added to prevent extra result sets from      
 -- interfering with SELECT statements.      
 SET NOCOUNT ON;  
     Update invt SET IsValidate=       
               CASE WHEN (NOT EXISTS (SELECT 1 FROM INVTHDEF WHERE TYPE ='R'  AND LTRIM(RTRIM(REASON)) =  LTRIM(RTRIM(invt.Reason)))       
                                          OR NOT EXISTS (SELECT  1 FROM SUPPORT WHERE FIELDNAME ='SHIPVIA'        
               AND  ((ISNULL(invt.Carrier,'') <> '' AND LTRIM(RTRIM(TEXT))  = LTRIM(RTRIM(invt.Carrier)))       
                   OR  (ISNULL(invt.Carrier,'') = ''  AND TEXT=TEXT))      
               OR  ISNUll(RecPklNo,'') ='')
			   OR ((invt.ImportType = 'S' OR invt.ImportType = 'C') AND (ISNUll(invt.CompanyName,'') ='' OR ISNUll(invt.CompanyNo,'') =''))) THEN 0 ELSE 1 END
     FROM InvtImportHeader invt where InvtImportId= @importId   
END