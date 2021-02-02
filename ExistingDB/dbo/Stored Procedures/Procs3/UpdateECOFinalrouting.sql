-- Author:  Vijay G                   
-- Create date: 09/24/2019               
-- DescriptiON: This Procedure is used for the insert routing for the newly created assembly      
-- EXEC [UpdateECOFinalrouting] 'CTGAI3TY7B','VX9JJ1YLI6'  
--============================================================== 
CREATE PROCEDURE [dbo].[UpdateECOFinalrouting]          
(          
 @uniqKey CHAR(10)  ,        
 @uniqEcNo VARCHAR(10)        
)          
AS                        
BEGIN             
        
DECLARE @ErrorMessage NVARCHAR(4000),@ErrorSeverity INT,@ErrorState INT           
      
SET NOCOUNT ON;            
BEGIN TRANSACTION                         
BEGIN TRY           
      
 INSERT INTO RoutingProductSetup (Uniq_key,uniquerout,isDefault,TemplateID)        
 SELECT @uniqKey,[New_Uniquerout],isDefault,TemplateID       
 FROM ECRoutingProductSetup         
 WHERE UniqEcNo=@uniqEcNo        
        
 INSERT INTO [dbo].[QUOTDEPT]        
 (      
   [UNIQ_KEY],[DEPT_ID],[RUNTIMESEC],[SETUPSEC],[NUMBER],[UNIQNUMBER],[STD_INSTR],[SPEC_INSTR],[PROC_NOTE],[REVDATE],        
      [REVINIT],[PEREVNO],[MARG_AMT],[TOT_AMOUNT],[MARG_PERC],[WCSETUPID],[STDIN_PICT],[SPEC_PICT],[CERTIFICAT],[OUTSFOOTNT],        
   [PARTPERUNT],[SERIALSTRT],[SPEC_NO],[uniqueRout],[IsOptional]        
 )        
 SELECT                    
 @uniqKey,[DEPT_ID],[RUNTIMESEC],[SETUPSEC],[NUMBER],[NEW_UNIQNUMBER],[STD_INSTR],[SPEC_INSTR],[PROC_NOTE],[REVDATE],        
 [REVINIT],[PEREVNO],[MARG_AMT],[TOT_AMOUNT],[MARG_PERC],[WCSETUPID],[STDIN_PICT],[SPEC_PICT],[CERTIFICAT],[OUTSFOOTNT],        
 [PARTPERUNT],[SERIALSTRT],[SPEC_NO],eq.[uniqueRout],[IsOptional]        
 FROM [dbo].[ECQUOTDEPT] eq       
 JOIN ECRoutingProductSetup er ON er.uniq_key= eq.UNIQ_KEY AND er.[New_Uniquerout]= eq.uniqueRout       
 WHERE UniqEcNo=@uniqEcNo      
       
 INSERT INTO WRKCKLST(UNIQ_KEY,DEPT_ACTIV,UniqNumber,NUMBER,CHKLST_TIT,WRKCKUNIQ,TemplateId,WCCheckPriority)          
 SELECT @uniqKey,DEPT_ACTIV,ewrk.NEW_UNIQNUMBER,ewrk.NUMBER,CHKLST_TIT,ewrk.NEW_WRKCKUNIQ,ewrk.TemplateID,wccheckpriority            
 FROM ECWRKCKLST ewrk       
 JOIN  ECQUOTDEPT eq ON ewrk.NEW_UNIQNUMBER=eq.NEW_UNIQNUMBER        
 JOIN ECRoutingProductSetup er ON er.uniq_key= eq.UNIQ_KEY AND er.[New_Uniquerout]= eq.uniquerout       
 WHERE UniqEcNo=@uniqEcNo
 
 COMMIT TRANSACTION   
       
END TRY         
BEGIN CATCH                                    
 IF @@TRANCOUNT > 0           
  ROLLBACK TRANSACTION;                
     SELECT @ErrorMessage = ERROR_MESSAGE(),          
        @ErrorSeverity = ERROR_SEVERITY(),          
        @ErrorState = ERROR_STATE();          
  RAISERROR (@ErrorMessage,          
               @ErrorSeverity,         
               @ErrorState         
               );                              
END CATCH                
END