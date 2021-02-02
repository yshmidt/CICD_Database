-- =============================================  
-- Author:  David Sharp  
-- Create date: 7/23/2013  
-- Description: marks an import as validated  
-- 03/23/2018: Vijay G: Added the parameter @isRedFlag to update the isValidated value.  
-- 03/23/2018: Vijay G: Updated the isValidated column value by checking status.  
-- 11/02/2018 : Vijay G: Checking errors at part level , avl level and ref desg level  and all SP code done prviously 
-- =============================================  
CREATE PROCEDURE dbo.importBOMVldtnDone   
 -- Add the parameters for the stored procedure here  
 @importId uniqueidentifier,  
 @isRedFlag bit = 0  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 ----03/23/2018:Vijay G: Check the redflag parameter if 1 then set the isValidated as 0  
 --IF @isRedFlag = 1   
 -- UPDATE importBOMHeader SET isValidated = 0 WHERE importId = @importId  
 ----03/23/2018:Vijay G: Check any items of current assembly has status as redflag then set the isValidated as 0  
 --ElSE IF EXISTS( SELECT 1 FROM importBOMFields WHERE fkimportId = @importId AND status='i05red')  
 -- -- Insert statements for procedure here  
 -- UPDATE importBOMHeader SET isValidated = 0 WHERE importId=@importId  
 --ELSE  
 ----03/23/2018:Vijay G: If there is no any redflag then set the isValidated as 1  
 -- UPDATE importBOMHeader SET isValidated = 1 WHERE importId=@importId  

   -- 11/02/2018 : Vijay G: Checking errors at part level , avl level and ref desg level  and all SP code done prviously 
  Declare @cnt as int;    
  ;WITH importBomErrorCount AS (  
	 SELECT status  from importBOMFields  WHERE importBOMFields.fkImportId = @importId AND status ='i05red'  
	 UNION    
	 SELECT status  from importBOMAvl  WHERE fkImportId = @importId AND status ='i05red'  
	 UNION   
	 SELECT status  from importBOMRefDesg  WHERE fkImportId = @importId AND status ='i05red'  
   )SELECT @cnt = COUNT(Status) FROM importBomErrorCount 
	
	UPDATE importBOMHeader SET isValidated = CASE WHEN @cnt = 0 THEN 1 ELSE 0 END WHERE importId=@importId  
END  