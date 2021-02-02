-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: <10/03/2011>  
-- Description: Get Customer List assigned to a user  
-- All Active Customers assigned to a given user  
-- Modifications: 04/18/2014 DRP: NEEDED TO ADD ORDER BY CUSTNAME SO THEY DISPLAYED IN THE CORRECT ORDER ON SCREEN WITHIN THE WEBMANEX  
-- 05/07/14 DS Added external employee param  
-- 05/13/14 DS Added ability to not pass the ExternalEmp and have it get it from the userid  
-- 05/27/14 YS added ability to show inactive customers. New parameter showStatus can have the following values  
--- showStatus = 'Active' (default) - show only Active customers  
--- showStatus = 'Inactive' - show only Inactive customers  
--- showStatus = 'All' - show all customers  
-- 06/10/14 YS chnages to the way @ExternalEmp is assigned if parameter was null  
-- 06/10/14 YS add an empty customer and remove limitation for "~" customer when employee is internal and no restrictions assigned to the user  
-- 01/15/15 DRP: Added customer status to allow for filtering the customers by status  
-- 02/14/2020 Vijay G: increased size of custname column 
--- showStatus = 'Active' (default) - show only Active customers  
--- showStatus = 'Inactive' - show only Inactive customers  
--- showStatus = 'All' - show all customers  
-- =============================================  
CREATE PROCEDURE [dbo].[aspmnxSP_GetCustomers4User]  
 -- Add the parameters for the stored procedure here  
 @UserId uniqueidentifier=NULL,  
 @ExternalEmp bit = NULL,  
  @customerStatus char(8)='Active'  
 --@showStatus char(8)='Active'  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    ---1. this will generate user information  
    -- 2. show only assigned customers if users is external  
    -- 3. show all the customers if user is internal and no customers has been assigned    
   -- check if the users is internal or external  
   -- 02/14/2020 Vijay G: increased size of custname column 
   DECLARE @tCustomers Table (Custno char(10),CustName char(50))  
 IF @ExternalEmp IS NULL  
 BEGIN  
  --06/10/14 YS if userid is null (not provided), we need to make sure that we do not return all the customers  
  -- will assign 1 to @externalEmp that way no customers will be returned. if userid=null, the select below return no records, so no value assigned to  
  -- @externalEmp. To work around assign 1 prior to running the select  
  SET @ExternalEmp=1  
    SELECT @ExternalEmp = isnull(ExternalEmp,1) FROM aspnet_Profile WHERE UserId=@UserId  
 END  
   
   IF (@ExternalEmp =1) -- outside employee select only assigned customer  
    INSERT INTO @tCustomers SELECT Customer.Custno,Customer.Custname   
   FROM Customer INNER JOIN aspmnx_UserCustomers ON  aspmnx_UserCustomers.fkCustno=Customer.CUSTNO   
   WHERE fkUserId = @UserId   
   -- 05/27/14 YS added ability to show inactive customers  
   AND 1= CASE WHEN @customerStatus='Active' and Customer.[Status]='Active' THEN 1  
      WHEN @customerStatus = 'Inactive' and Customer.[STATUS] = 'Inactive' THEN 1   
      WHEN @customerStatus='All' THEN 1 ELSE 0 END  
  
 ELSE -- (@ExternalEmp =1)  
 BEGIN  
  INSERT INTO @tCustomers SELECT Customer.Custno,Customer.Custname   
   FROM Customer INNER JOIN aspmnx_UserCustomers ON  aspmnx_UserCustomers.fkCustno=Customer.CUSTNO   
   WHERE fkUserId = @UserId  
  IF @@ROWCOUNT = 0   
  BEGIN  
   -- get all the customers  
  
   INSERT INTO  @tCustomers SELECT Customer.Custno,Customer.Custname   
    FROM Customer  
   -- 06/10/14 YS remove restriction for '000000000~' customer and add an empty customer  
   --WHERE Customer.Custno<>'000000000~'   
   -- 05/27/14 YS added ability to show inactive customers  
   WHERE 1= CASE WHEN @customerStatus='Active' and Customer.[Status]='Active' THEN 1  
      WHEN @customerStatus = 'Inactive' and Customer.[STATUS] = 'Inactive' THEN 1   
      WHEN @customerStatus='All' THEN 1 ELSE 0 END  
   UNION  
   SELECT '' as custno,'' as custname  
  
   END -- @@ROWCOUNT=0  
 END -- (@ExternalEmp =1)  
 SELECT * FROM @tCustomers   
 order by CustName  
END