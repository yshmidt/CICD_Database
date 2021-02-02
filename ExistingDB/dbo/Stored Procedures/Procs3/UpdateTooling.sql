-- Author:  Vijay G                     
-- Create date: 09/30/2019                 
-- DescriptiON: Used to update tooling for new assembly for ECO           
--EXEC [UpdateECOFinalrouting] 'CTGAI3TY7B','VX9JJ1YLI6'     
CREATE PROCEDURE [dbo].[UpdateTooling]            
(            
 @uniqKey CHAR(10)  ,          
 @uniqEcNo VARCHAR(10)          
)            
AS                          
BEGIN               
          
  DECLARE @ErrorMessage NVARCHAR(4000),@ErrorSeverity INT,@ErrorState INT             
        
SET NOCOUNT ON;              
BEGIN TRY             
                
 INSERT INTO TOOLING(TOOLID,UNIQ_KEY,DEPT_ID,ToolsAndFixtureId,UNIQNUMBER,TemplateId,Description,CalibrationDate)            
 SELECT     
 dbo.fn_GenerateUniqueNumber(),  @uniqKey, en.DEPT_ID,ToolsAndFixtureId,NEW_UNIQNUMBER,er.TemplateID,' ',GETDATE()                                                  
 FROM ECNRE en       
 JOIN ECRoutingProductSetup er on en.UNIQECNO=er.UniqEcNo    
 JOIN  ECQUOTDEPT eq ON eq.DEPT_ID=en.DEPT_ID  AND eq.uniquerout=er.New_Uniquerout    
 WHERE en.UniqEcNo=@uniqEcNo        
    
END TRY           
BEGIN CATCH                                      
 IF @@TRANCOUNT > 0             
     SELECT @ErrorMessage = ERROR_MESSAGE(),            
        @ErrorSeverity = ERROR_SEVERITY(),            
        @ErrorState = ERROR_STATE();            
  RAISERROR (@ErrorMessage,            
               @ErrorSeverity,           
               @ErrorState           
               );                                
END CATCH            
END