-- =============================================  
-- Author:  Sachin B  
-- Create date: 05/08/2018  
-- Description: This SP is Called from EWI Module For Assign Setup Default Template to Assembly Assembly Does not have any Template linked with them  
-- Modified:  
-- Sachin B: 09/24/2019: Fix the Issue for the While linking default template to assemly serialyes column for the STAG WC is true is assembly is serialized
-- =============================================  
CREATE PROCEDURE [dbo].[LinkSetupDefaultTemplateToAssembly]  
(  
 @uniqKey CHAR(10)  
)  
AS                
BEGIN     
   
SET NOCOUNT ON;    
                            
BEGIN TRY       
               
BEGIN TRANSACTION --transferTransaction   
  
DECLARE @ErrorMessage NVARCHAR(4000), -- declare variable to catch an error  
  @ErrorSeverity INT,  
  @ErrorState INT  
  
DECLARE @tuniquerout TABLE (uniquerout CHAR(10)) 
DECLARE @serialYes BIT = (SELECT SERIALYES FROM INVENTOR WHERE uniq_key =@uniqKey)
  
--Insert Data in routingProductSetup i.e. Assign regular Default Template to Assembly  
INSERT INTO routingProductSetup (Uniq_key,uniquerout,isDefault,TemplateID)  
OUTPUT inserted.uniquerout INTO @tuniquerout  
SELECT @uniqKey AS uniq_key,dbo.fn_GenerateUniqueNumber() AS uniquerout,1 AS isdefault,templateid   
FROM RoutingTemplate T WHERE t.TemplateType='Regular' AND t.IsDefault=1  
  
--Insert Data in Quotdept         
INSERT INTO Quotdept  (UNIQ_KEY,dept_id,Number,uniqueRout,UniqNumber)  
SELECT t.Uniq_key,d.DeptId,D.SequenceNo,t.uniquerout,dbo.fn_GenerateUniqueNumber() AS UniqNumber  
FROM routingProductSetup T   
INNER JOIN RoutingTemplateDetail D ON t.TemplateID=d.TemplateId  
INNER JOIN @tuniquerout K ON t.uniquerout=k.uniquerout  
  
--Assign Setup WC Checklist to Assembly  
INSERT INTO WRKCKLST(UNIQ_KEY,DEPT_ACTIV,UniqNumber,NUMBER,CHKLST_TIT,WRKCKUNIQ,TemplateId,WCCheckPriority)  
SELECT q.UNIQ_KEY,q.DEPT_ID,q.UNIQNUMBER,q.NUMBER,wcCkect.WCChkName,dbo.fn_GenerateUniqueNumber(),r.TemplateID,wcCkect.WCChkPriority    
FROM WCChkList wcCkect   
INNER JOIN QUOTDEPT q ON wcCkect.Dept_ID =q.Dept_ID AND UNIQ_KEY =@uniqKey  
INNER JOIN routingProductSetup r ON r.uniquerout =q.uniqueRout AND r.UNIQ_KEY =@uniqKey 

-- Sachin B: 09/24/2019: Fix the Issue for the While linking default template to assemly serialyes column for the STAG WC is true is assembly is serialized
IF(@serialYes=1) 
BEGIN
  UPDATE QUOTDEPT SET SERIALSTRT =1 
  WHERE DEPT_ID='STAG' AND uniqueRout IN (SELECT uniqueRout FROM @tuniquerout)
END
  
COMMIT TRANSACTION                
                
END TRY        
       
BEGIN CATCH                            
 IF @@TRANCOUNT > 0   
  ROLLBACK TRANSACTION;        
     SELECT @ErrorMessage = ERROR_MESSAGE(),  
        @ErrorSeverity = ERROR_SEVERITY(),  
        @ErrorState = ERROR_STATE();  
  RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );                      
END CATCH                         
END