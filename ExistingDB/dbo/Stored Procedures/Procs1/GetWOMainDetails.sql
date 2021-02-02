-- =============================================        
-- Author:  Shripati U          
-- Create date: <08/26/2017>        
-- Description:Get Work Order list        
-- 09/27/2017 Shripati U-  Get the Data for Update Work Order         
-- 10/12/2017 Shripati U-  Get the work order closed user initials         
-- 01/04/2018 Shripati U-  Get the ReleasedBy             
-- 04/25/2018 Shripati U  Get WO Check List info Columns         
-- 05/15/2018 Shripati U  Add Cast on the boolean Parameters        
-- 06/21/2018 Shripati U  Get pd.COMPL_DTS,pd.START_DTS from PROD_DTS table       
-- 10/08/2018 Sachin B Get Due_Date in the Select Statement       
-- 10/30/2018 Shrikant B use ClosedDate column from WOENTRY table instead of PROD_DTS       
-- 12/05/2018 Shrikant B added column KitUniqWh      
-- 12/05/2018 Shrikant B added column WarehouseName for getting warehouse name based on Id       
-- 12/05/2018 Shrikant B added JOIN for getting warehouse name based on Id       
-- 12/10/2018 Shrikant B getting CompletedDate from PROD_DTS table      
-- 12/22/2018 Shrikant B added column WONO for getting latest saved work order number      
-- 12/26/2018 Shrikant B added column OPENCLOS for getting work order status on work order selection       
-- 03/15/2019 Shrikant B added column UNIQUELN for fixed capa 1356 allow canceled sales order      
-- 04/16/2019 Sachin B Add the BOM BOMCUSTNO in the Select Statement    
-- 04/11/2019 Shrikant B added column Is_rma for fixed capa 1357 cannot be changed from Rework if Is_rma and sono does not blank    
-- 04/11/2019 Shrikant B added JOIN for getting  sales order no based on ID    
-- 04/11/2019 Shrikant B added JOIN for getting Is_rma based on sales order no    
-- 04/24/2019 Shrikant B added column KITSTATUS for fixed capa 1357 cannot be changed from Rework if KITSTATUS  is in Progress     
-- 05/21/19 Shrikant modify the field ClosedBy from initials to the userName    
-- 08/22/2019 Satyawan H - Get the username on the basis of userid instead of directly saving username in ReleasedBy  
-- 08/22/2019 Satyawan H - Added Join with aspnet_users to get username for ReleasedBy userid 
-- 08/30/2019 Sachin B - Fixed the Issue the WO is not getting values convert innser join to left join
-- GetWOMainDetails '0000998583'  --  
-- =============================================        
CREATE PROCEDURE [dbo].[GetWOMainDetails]        
(        
 @WONO NVARCHAR(10)=''        
)        
AS        
BEGIN        
   SET NOCOUNT ON;          
SELECT         
 c.CUSTNO AS CustomerNumber,         
 c.CUSTNAME AS CustomerName,        
 i.PART_TYPE AS PartType,        
 i.PART_CLASS AS PartClass,        
 i.Part_No AS AssemblyNumber,        
 i.Revision AS Revision,        
 i.Descript AS [Description],        
 i.UNIQ_KEY AS UniqKey,     
 -- 04/16/2019 Sachin B Add the BOM BOMCUSTNO in the Select Statement    
 i.BOMCUSTNO,         
 p.PRJNUMBER AS ProjectNumber,        
 p.PRJUNIQUE AS ProjectUnique,        
 w.SONO  AS SONO,        
 w.kit AS Kit,        
 w.RELEDATE AS ReleasedDate,        
 -- 01/04/2018 Shripati U-  Get the ReleasedBy             
 --w.ReleasedBy,        
 -- 08/22/2019 Satyawan H - Get the username on the basis of userid instead of directly saving username in ReleasedBy  
 ISNULL(u.UserName,'') ReleasedBy,  
 w.WONote AS Note,        
 w.COMPLETE AS CompletedQty,        
 w.BLDQTY AS WOQty,        
 w.BALANCE AS Balance,        
 w.ORDERDATE AS OrderDate,       
-- 10/30/2018 Shrikant B use ClosedDate column from WOENTRY table instead of PROD_DTS      
-- 12/10/2018 Shrikant B getting CompletedDate from PROD_DTS table      
 w.COMPLETEDT AS ClosedDate,         
 ISNULL(pd.COMPL_DTS,w.COMPLETEDT) AS CompletedDate,        
 ISNULL(pd.START_DTS,w.START_DATE) AS StartDate,        
 w.JobType,        
 w.LFCSTITEM AS ForecastItem,        
 rt.TemplateName AS TemplateName,        
 w.uniquerout AS Uniquerout,       
-- 05/21/19 Shrikant modify the field ClosedBy from initials to the userName      
 au.UserName AS ClosedUser,         
 --04/25/2018 Shripati U  Get WO Check List info Columns         
 -- 05/15/2018 Shripati U  Add Cast on the boolean Parameters        
 CASE WHEN w.RoutingChk = 1 AND w.WrkInstChk = 1 AND w.BOMChk = 1 AND w.ECOChk  = 1 AND w.EquipmentChk  = 1 AND w.ToolsChk  = 1  THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsEnableWOCheckList ,        
 COUNT(1) OVER() AS TotalCount,      
 w.DUE_DATE AS DueDate,      
 w.KitUniqWh,  -- 12/05/2018 Shrikant B added column KitUniqWh      
 wh.WAREHOUSE AS WarehouseName, -- 12/05/2018 Shrikant B added column WarehouseName for getting warehouse name based on Id      
  -- 12/22/2018 Shrikant B added column WONO for getting latest saved work order number      
  w.WONO AS WorkOrder,      
 -- 12/26/2018 Shrikant B added column OPENCLOS for getting work order status on work order selection       
  w.OPENCLOS AS Status,      
  -- 03/15/2019 Shrikant B added column UNIQUELN for fixed capa 1356 allow canceled sales order      
  W.UNIQUELN       
 -- 04/11/2019 Shrikant B added column Is_rma for fixed capa 1357 cannot be changed from Rework if Is_rma and sono does not blank    
  ,ISNULL((Is_rma), 0) as IsRma,     
   -- 04/24/2019 Shrikant B added column KITSTATUS for fixed capa 1357 cannot be changed from Rework if KITSTATUS  is in Progress     
  KITSTATUS    
      
FROM WOENTRY w        
LEFT JOIN PROD_DTS pd ON w.WONO =pd.WONO        
INNER JOIN INVENTOR i ON w.UNIQ_KEY=i.UNIQ_KEY         
INNER JOIN CUSTOMER c ON w.CUSTNO=c.CUSTNO        
--10/12/2017 Shripati U  Get the work order closed user initials     
-- 05/21/19 Shrikant modify the field ClosedBy from initials to the userName     
--LEFT JOIN aspnet_Profile ap ON w.ClosedBy = ap.UserId         
LEFT JOIN aspnet_Users au ON w.ClosedBy = au.UserId         
LEFT JOIN routingProductSetup r ON w.uniquerout= r.uniquerout -- 09/27/2017 Shripati U  Get the Data for Update Work Order         
LEFT JOIN  routingtemplate rt ON r.TemplateID = rt.TemplateID        
LEFT JOIN PJCTMAIN p ON w.PRJUNIQUE=p.PRJUNIQUE AND c.CUSTNO=p.CUSTNO        
-- 12/05/2018 Shrikant B added JOIN for getting warehouse name based on Id     
LEFT JOIN WAREHOUS wh ON w.KitUniqWh = wh.UNIQWH    
-- 04/11/2019 Shrikant B added JOIN for getting  sales order no based on ID    
FULL OUTER JOIN sodetail sod ON  sod.UNIQUELN = w.UNIQUELN    
-- 04/11/2019 Shrikant B added JOIN for getting Is_rma based on sales order no    
FULL OUTER JOIN somain som ON som.SONO =  sod.SONO    
-- 08/22/2019 Satyawan H - Added Join with aspnet_users to get username for ReleasedBy userid  
-- 08/30/2019 Sachin B - Fixed the Issue the WO is not getting values convert innser join to left join
LEFT JOIN aspnet_Users u ON w.ReleasedBy = u.UserId  
WHERE w.WONO=@WONO          
           
END   
  