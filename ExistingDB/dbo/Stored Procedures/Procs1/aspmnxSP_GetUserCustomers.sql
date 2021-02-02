-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: <09/07/2011>  
-- Description: Get Users information. Will return multiple data sets  
-- . All Active Customers and those that are assigned to a given user
-- 07/24/2020 Sachin B Add the Order By Clause to sort customer by Name  
-- =============================================  
CREATE PROCEDURE [dbo].[aspmnxSP_GetUserCustomers]  
 -- Add the parameters for the stored procedure here  
 @UserId UNIQUEIDENTIFIER=' '  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    ----2. All active suppliers and those that are assigned to Given users  
 SELECT Custno,Custname,isnull(Z.Assigned,CAST(0 AS BIT)) AS Assigned   
 FROm Customer
 OUTER APPLY (SELECT CAST(1 as bit) as Assigned from aspmnx_UserCustomers WHERE fkUserId = @UserId AND fkCustno=Customer.CUSTNO) AS Z   
 WHERE Customer.Status<>'Inactive' AND Customer.Custno<>'000000000~'  
 ORDER BY custname 
   
END