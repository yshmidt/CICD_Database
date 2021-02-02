/*Please verify the procedure before run*/
  
-- =============================================    
-- Author:  Aloha  
-- Create date: ??/??/????    
-- Description: Get the tutorial steps
-- 01/23/14 SL Added CssSelector column  
-- =============================================   
CREATE PROCEDURE [dbo].[MnxHelpTutotialStepsGet]    
(    
  @ModuleId varchar(100)  
)    
AS    
BEGIN    
    
SELECT MnxHelpTutorialSteps.HelpId,     
  MnxHelpTutorialSteps.ControlOrder,         
  MnxHelpTutorialSteps.Required,     
  MnxHelpTutorialSteps.CanAffectUI,     
  MnxHelpTutorialSteps.ModuleId,     
  MnxHelpModule.Description,     
  MnxHelpModule.LoadAllSteps,     
  MnxHelpModule.ShowOnStartUp,     
  MnxHelp.HelpKey,    
  MnxHelp.CssSelector, 
  MnxHelp.HeaderResourceKey,  
  MnxHelp.DescriptionResourceKey,     
  MnxHelp.FieldLength,     
  MnxHelp.Definition,     
  MnxHelp.DataBaseLocation    
FROM  MnxHelpTutorialSteps INNER JOIN    
      MnxHelpModule ON MnxHelpTutorialSteps.ModuleId = MnxHelpModule.ModuleId INNER JOIN    
      MnxHelp ON MnxHelpTutorialSteps.HelpId = MnxHelp.HelpId    
WHERE MnxHelpModule.ModuleId = @ModuleId  
ORDER BY  MnxHelpTutorialSteps.ControlOrder   
  
END  