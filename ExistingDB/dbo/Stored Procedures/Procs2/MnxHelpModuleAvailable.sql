

CREATE PROCEDURE [dbo].[MnxHelpModuleAvailable]  
(  
  @ModuleId varchar(100)
)  
AS  
BEGIN  

	SELECT Top 1 ModuleId
	FROM MnxHelpModule 
	WHERE ModuleId=@ModuleId

END
