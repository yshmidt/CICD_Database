-- =============================================  
-- Author:  <Author,,Name>  
-- Create date: <Create Date,,>  
-- Description: <Description,,>  
-- Modidifed: 08/01/17 YS moved part_class setup from "Support" table to "partClass" table  
-- Modidifed: 02/26/18: Vijay G: To get partclass on the basis of provided part class parameter.   
--- 04/12/18 YS get useipkey  
-- Modidifed: 02/26/2020: Vijay G: To get classPrefix,numberGenerator column value  

-- =============================================  
CREATE PROC [dbo].[Part_class_view]   
-- 02/26/18: Vijay G: Added partClass parameter   
@partClass NVARCHAR(8) = ''   
AS  
BEGIN  
-- 02/26/18: Vijay G: Get partclass on the basis of partclass parameter value. If parameter value is empty then get all part class list.  
IF @partClass <> ''  
 SELECT Part_class, Partclass.classDescription,classUnique,useIpkey ,classPrefix,numberGenerator 
 FROM PartClass WHERE Part_class LIKE '%'+ @partClass +'%'  
 ORDER BY part_class  
ELSE  
 SELECT Part_class, Partclass.classDescription,classUnique,useIpkey  ,classPrefix,numberGenerator 
 FROM PartClass  
 ORDER BY part_class  
END  