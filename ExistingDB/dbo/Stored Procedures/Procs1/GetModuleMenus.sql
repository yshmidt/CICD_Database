-- =============================================  
-- Author:  Sachin s  
-- Create date: 05/27/2016  
-- Description: Get module list by parentId  
-- GetModuleMenus 2  
-- 8/9/2016 Raviraj P : Added New isWorkflow for workflow manager  
-- 8/9/2016 Shiv P : Added New IsFilingCabinet for workflow manager  
-- 11/14/2016 Satish B :Addes new IsModuleShow for Show/hide Module on UI  
-- 09/19/2017 Shripati :Addes new IsPermission for Permission  
-- 5/23/2018 Raviraj P : Modified Modulename Based on ResourceKeyName available in MnxModule.ModuleDesc column  
-- 5/23/2018 Raviraj P : Modified Remove * selection and Select column  
-- 5/23/2018 Raviraj P : Added new parameter userId for localization  
-- 5/23/2018 Raviraj P : Added code for Localization with language id based on user  
-- 06/06/2018 Sachin B : Add Column IsShowChild   
-- =============================================  
CREATE PROCEDURE GetModuleMenus  
 -- Add the parameters for the stored procedure here  
 @parentid AS INT,  
 @userId AS UNIQUEIDENTIFIER = null -- 5/23/2018 Raviraj P : Added new parameter userId for localization  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    SELECT   
  ModuleId  
 ,ModuleName  
 ,ModuleDesc  
 ,Abbreviation  
 ,HaveChild  
 ,FileType  
 ,ModuleCss  
 ,FilePath   
 ,RowNum  
 ,isWorkflow -- 8/9/2016 Raviraj P : Added New isWorkflow for workflow manager  
 ,IsFilingCabinet -- 8/9/2016 Shiv P : Added New IsFilingCabinet for workflow manager  
 ,IsModuleShow  --11/14/2016 Satish B :Addes new IsModuleShow for Show/hide Module on UI  
    ,IsPermission  -- 09/19/2017 Shripati :Addes new IsPermission for Permission  
 ,IsShowChild
 ,RenderNumber -- 06/08/2019 Raviraj P : Added New RenderNumber for order parent menu by 
 FROM (  
  SELECT  
  -- 5/23/2018 Raviraj P : Modified Remove * selection and Select column  
    module.ModuleId  
   ,module.ModuleCss  
   ,module.Abbreviation  
   ,module.FilePath  
   ,module.FileType  
   ,module.HaveChild  
   ,module.IsFilingCabinet  
   ,module.IsPermission  
   ,module.isWorkflow  
   ,module.IsModuleShow  
   ,module.ModuleDesc  
   ,module.IsShowChild 
   ,module.RenderNumber 
  ,ISNULL(w.Translation,ISNULL(rsc.ManExValue,module.ModuleName)) AS ModuleName  
  ,ROW_NUMBER() OVER (ORDER BY ModuleOrder) AS RowNum  
  FROM MnxModuleRelationship relationship  
  JOIN MnxModule module ON module.ModuleId = relationship.ChildId  
  -- 5/23/2018 Raviraj P : Modified Modulename Based on ResourceKeyName available in MnxModule.ModuleDesc column  
  LEFT JOIN MnxResourceKey rsc ON module.ModuleDesc = rsc.ResourceKeyName  
  LEFT JOIN WmResourceTranslation w ON rsc.ResourceKeyId = w.ResourceKeyId   
  AND LanguageId =(CASE WHEN @userId IS NOT NULL THEN (SELECT LanguageId FROM aspnet_Profile WHERE UserId =  @userId)   
          WHEN @userId IS NULL OR @userId = (SELECT CAST(CAST(0 AS BINARY) AS UNIQUEIDENTIFIER)) THEN 1  
       END)  
  -- 5/23/2018 Raviraj P:Added code for Localization with language id based on user  
  Where parentid= @parentid  
 ) AS ModuleMenus  
END