-- =============================================  
-- Author:  Rajendra k
-- Create date: <08/27/2020>  
-- Description: Get Supplier List assigned to a user  
-- =============================================  
CREATE PROCEDURE [dbo].[GetAspMnxUserSuppliers]   
 @UserId uniqueidentifier=NULL,  
 @ExternalEmp bit = NULL,  
 @supplierStatus char(8)='Active'  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;   
   DECLARE @tSupplier Table (UniqSupno char(10),SUPNAME char(50),R_LINK char(10),C_LINK char(10),Supid char(10),Fcused_Uniq char(10),Terms char(15))  
 IF @ExternalEmp IS NULL  
  -- will assign 1 to @externalEmp that way no customers will be returned. if userid=null, the select below return no records, so no value assigned to  
  -- @externalEmp. To work around assign 1 prior to running the select  
  set @ExternalEmp =1  
    SELECT @ExternalEmp = ExternalEmp FROM aspnet_Profile WHERE UserId=@UserId  
     
  
   IF (@ExternalEmp =1) -- outside employee select only assigned customer  
    INSERT INTO @tSupplier SELECT Supinfo.UniqSupno,Supinfo.SUPNAME, Supinfo.R_LINK,Supinfo.C_LINK,Supinfo.Supid,Supinfo.Fcused_Uniq ,Supinfo.Terms 
   FROm Supinfo INNER JOIN aspmnx_UserSuppliers  ON  aspmnx_UserSuppliers.fkUniqSupNo =Supinfo.UNIQSUPNO    
   WHERE fkUserId = @UserId   
   AND 1 = CASE WHEN @supplierStatus='Active' and (Supinfo.[Status]<>'INACTIVE' and Supinfo.[Status]<>'DISQUALIFIED') THEN 1  
      WHEN @supplierStatus='Inactive' and (Supinfo.[Status]='INACTIVE' OR Supinfo.[Status]='DISQUALIFIED')  THEN 1  
      WHEN @supplierStatus = 'All' THEN 1 ELSE 0 END  
 ELSE 
 BEGIN  
  INSERT INTO @tSupplier SELECT Supinfo.UniqSupno,Supinfo.SUPNAME, Supinfo.R_LINK,Supinfo.C_LINK,Supinfo.Supid,Supinfo.Fcused_Uniq ,Supinfo.Terms 
   FROm Supinfo INNER JOIN aspmnx_UserSuppliers  ON  aspmnx_UserSuppliers.fkUniqSupNo =Supinfo.UNIQSUPNO    
   WHERE fkUserId = @UserId   
  IF @@ROWCOUNT = 0   
  BEGIN  
   -- get all the customers  
   INSERT INTO  @tSupplier SELECT Supinfo.UniqSupno,Supinfo.SUPNAME, Supinfo.R_LINK,Supinfo.C_LINK,Supinfo.Supid,Supinfo.Fcused_Uniq ,Supinfo.Terms 
    FROM Supinfo  
    WHERE 1 = CASE WHEN @supplierStatus='Active' and (Supinfo.[Status]<>'INACTIVE' and Supinfo.[Status]<>'DISQUALIFIED') THEN 1  
      WHEN @supplierStatus='Inactive' and (Supinfo.[Status]='INACTIVE' OR Supinfo.[Status]='DISQUALIFIED')  THEN 1  
      WHEN @supplierStatus = 'All' THEN 1 ELSE 0 END   
  END -- @@ROWCOUNT=0  
 END -- (@ExternalEmp =1)  
 SELECT * FROM @tSupplier  
   
END