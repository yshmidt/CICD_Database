-- ============================================================================================================  
-- Author:  Vijay G               
-- Create date: 09/09/2019           
-- DescriptiON: Insert and link the teplate with ECO      
-- 11/22/2019 : Sachin B -Insert the Regular Type Template routing only for the ECO
-- 12/04/2019 Vijay G Update default template and make default which user selected for ECO
-- ============================================================================================================ 
    
CREATE PROCEDURE [dbo].[InsertRecordInECORouting]      
(      
 @uniqKey CHAR(10)  ,    
 @uniqEcNo VARCHAR(10)    
)      
AS                    
BEGIN         
  DECLARE @ErrorMessage NVARCHAR(4000),      
  @ErrorSeverity INT,      
  @ErrorState INT       
SET NOCOUNT ON;        
BEGIN TRY       
    
INSERT INTO ECRoutingProductSetup (Uniq_key,uniquerout,isDefault,TemplateID,UniqEcNo)    
SELECT Uniq_key,uniquerout,rps.isDefault,rps.TemplateID,@uniqEcNo 
FROM RoutingProductSetup rps 
-- 11/22/2019 : Sachin B -Insert the Regular Type Template routing only for the ECO
INNER Join RoutingTemplate rt on rps.TemplateID = rt.TemplateID  
WHERE Uniq_Key=@uniqKey AND rt.TemplateType ='Regular'   
    
INSERT INTO [dbo].[ECQUOTDEPT]    
(  [UNIQ_KEY],[DEPT_ID],[RUNTIMESEC],[SETUPSEC],[NUMBER],[UNIQNUMBER],[STD_INSTR],[SPEC_INSTR],[PROC_NOTE],[REVDATE],    
   [REVINIT],[PEREVNO],[MARG_AMT],[TOT_AMOUNT],[MARG_PERC],[WCSETUPID],[STDIN_PICT],[SPEC_PICT],[CERTIFICAT],[OUTSFOOTNT],    
   [PARTPERUNT],[SERIALSTRT],[SPEC_NO],[uniqueRout],[IsOptional]    
)    
SELECT                
q.[UNIQ_KEY],[DEPT_ID],[RUNTIMESEC],[SETUPSEC],[NUMBER],[UNIQNUMBER],[STD_INSTR],[SPEC_INSTR],[PROC_NOTE],[REVDATE],    
[REVINIT],[PEREVNO],[MARG_AMT],[TOT_AMOUNT],[MARG_PERC],[WCSETUPID],[STDIN_PICT],[SPEC_PICT],[CERTIFICAT],[OUTSFOOTNT],    
[PARTPERUNT],[SERIALSTRT],[SPEC_NO],e.[New_Uniquerout],[IsOptional]    
FROM [dbo].[QUOTDEPT] q  
JOIN [dbo].ECRoutingProductSetup e ON e.uniqueRout=q.uniquerout AND e.UNIQ_KEY=q.Uniq_key  
WHERE q.UNIQ_KEY=@uniqKey AND q.uniqueRout<>''    
  
INSERT INTO ECWRKCKLST(UNIQ_KEY,DEPT_ACTIV,UniqNumber,NEW_UNIQNUMBER,NUMBER,CHKLST_TIT,WRKCKUNIQ,TemplateId,WCCheckPriority)      
SELECT WRKCKLST.UNIQ_KEY,DEPT_ACTIV,ECQUOTDEPT.UNIQNUMBER,ECQUOTDEPT.NEW_UNIQNUMBER,WRKCKLST.NUMBER,CHKLST_TIT,dbo.fn_GenerateUniqueNumber(),TemplateID,wccheckpriority        
FROM WRKCKLST 
INNER JOIN  ECQUOTDEPT ON WRKCKLST.UniqNumber=ECQUOTDEPT.UniqNumber    
WHERE WRKCKLST.UNIQ_KEY =@uniqKey 

-- 12/04/2019 Vijay G Update default template and make default which user selected for ECO
DECLARE @uniqRoutNo VARCHAR(10)
SELECT @uniqRoutNo=uniquerout FROM ECMAIN WHERE uniqEcNo= @uniqEcNo
UPDATE ECRoutingProductSetup SET isDefault=0 WHERE uniqEcNo= @uniqEcNo
Update ECRoutingProductSetup SET isDefault=1 WHERE uniqEcNo= @uniqEcNo AND uniqueRout=@uniqRoutNo         
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