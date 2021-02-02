-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: <09/07/2011>  
-- Description: Get Users information. Will return multiple data sets  
-- 3. All Active Suppliers and those that are assigned to a given user 
-- 07/24/2020 Sachin B Add the Order By Clause to sort supplier by SupName  
-- =============================================  
CREATE PROCEDURE [dbo].[aspmnxSP_GetUserSuppliers]  
 -- Add the parameters for the stored procedure here  
 @UserId UNIQUEIDENTIFIER=' '  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
      
 ----3. All active customers and those that are assigned to Given users  
 SELECT UniqSupno,Supname,ISNULL(Z.Assigned,CAST(0 AS BIT)) AS Assigned   
 FROM Supinfo 
 OUTER APPLY (SELECT CAST(1 AS BIT) AS Assigned FROM aspmnx_UserSuppliers WHERE fkUserId = @UserId AND fkUniqSupNo =Supinfo.UNIQSUPNO) AS Z    
 WHERE Status<>'INACTIVE'  
 AND Status<>'DISQUALIFIED'  
 ORDER BY SUPNAME  
   
END