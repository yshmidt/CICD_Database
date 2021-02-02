-- =============================================  
-- Author:  David Sharp  
-- Create date: 8/2/2013  
-- Description: checks badgeCode uniqueness.  It will return the badgeCode if it is unique, or a new 10 char number if not.  
-- 10/4/13 SL Checked to see if badgecode exists
-- =============================================  
CREATE FUNCTION [dbo].[fn_CheckBadgeCode]   
(  
 -- Add the parameters for the function here  
 @badgeCode varchar(50)  
)  
RETURNS varchar(50)  
AS  
BEGIN  
 -- Declare the return variable here  
 DECLARE @Result varchar(50)=@badgeCode,@bCnt int  
  
 -- Add the T-SQL statements to compute the return value here  
 SELECT @bCnt = COUNT(*) FROM aspnet_Profile WHERE badgeCode = @badgeCode  
 
 --SLokhande 10/4/2013
 --IF @bCnt>0 SET @Result=dbo.fn_GenerateUniqueNumber() 
 -- We should check count >1
 IF @bCnt>1 SET @Result=dbo.fn_GenerateUniqueNumber()  
   
 --Added an extra case in the slim chance that the random number is already used.  
 SELECT @bCnt = COUNT(*) FROM aspnet_Profile WHERE badgeCode = @Result  
  
 --SLokhande 10/4/2013
 --IF @bCnt>0 SET @Result=dbo.fn_GenerateUniqueNumber()
 -- We should check count >1
 IF @bCnt>1 SET @Result=dbo.fn_GenerateUniqueNumber()  
 -- Return the result of the function  
 RETURN @Result  
  
END  