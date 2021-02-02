-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: <12/22/2010>  
-- Description: <Convert qty> 
-- Modify: 10/07/2020 Shivshankar P > Return top 1 values after calculating @ResultVar when there are multiple Formula available in UNIT table 
-- =============================================  
CREATE FUNCTION dbo.fn_ConverQtyUOM  
(  
 -- Add the parameters for the function here  
 @pcPUOM char(4)=' ', -- purchase UOM  
 @pcSUOM char(4)=' ', -- stock UOM  
 @pnQty numeric(12,2) =0.00  -- Qty to convert  
)  
RETURNS numeric(12,2)  
AS  
BEGIN  
 -- Declare the return variable here  
 DECLARE @ResultVar numeric(12,2)  
 SET @ResultVar=@pnQty  
 -- Modify: 10/07/2020 Shivshankar P > Return top 1 values after calculating when there are multiple Formula available in UNIT table 
 -- Add the T-SQL statements to compute the return value here  
 SELECT TOP 1 @ResultVar=CASE WHEN [FROM]=@pcPUOM THEN ROUND(@pnQty*Formula,2)   
     ELSE ROUND(@pnQty/Formula,2) END   
  FROM UNIT WHERE ([FROM]=@pcPUOM AND [TO]=@pcSUOM ) OR ([FROM]=@pcSUOM AND [TO]=@pcPUOM)  
   
   
 -- Return the result of the function  
 RETURN ISNULL(@ResultVar,@pnQty)  
  
END  