-- =============================================  
-- Author:  <Yelena Shmidt>  
-- Create date: <10/27/2011>  
-- Description: <get drill down information for Cost Adjustment>  
-- Modification:  
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC 
-- 08/12/2020 Shivshankar P : Change the Inner to left join on WAREHOUS for the transaction are related to records from Unreconciled receipts
 ---08/12/20 YS added isnull for the warehouse short name
-- =============================================  
CREATE PROCEDURE [dbo].[DrillDownCostAdj]  
 -- Add the parameters for the stored procedure here  
 @UNIQ_UPDT as char(10)=' '  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
DECLARE @lFCInstalled bit  
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()  
  
-- 12/13/16 VL separate FC and non FC  
IF @lFCInstalled = 0  
  -- Insert statements for procedure here  
 SELECT [UPDTSTD].UNIQ_KEY,Inventor.PART_NO,Inventor.REVISION,
 ---08/12/20 YS added isnull for the warehouse short name
   Inventor.PART_SOURC,Inventor.DESCRIPT, isnull(Warehous.WAREHOUSE,space(10)) as warehouse ,  
     [QTY_OH],[CHANGEAMT],  
     [UPDTSTD].[MATL_COST],[UPDTSTD].[NEWMATLCST],  
     [UPDTSTD].[OLDMATLCST],[UPDTSTD].[OLDSTDCOST],[UPDTSTD].[NEWSTDCOST],  
     [UPDTSTD].RUNDATE ,[UPDTSTD].UPDTDATE ,  
     [UPDTSTD].[UniqWh],[UPDTSTD].[UNIQ_UPDT]  
     FROM [dbo].[UPDTSTD] 
	 INNER JOIN INVENTOR ON UPDTSTD.UNIQ_KEY =INVENTOR.UNIQ_KEY   
     -- 08/12/2020 Shivshankar P : Change the Inner to left join on WAREHOUS for the transaction are related to records from Unreconciled receipts
     LEFT JOIN WAREHOUS ON UPDTSTD.UniqWh = Warehous.UNIQWH      
     WHERE [UNIQ_UPDT]=@UNIQ_UPDT   
ELSE  
    -- Insert statements for procedure here  
 SELECT [UPDTSTD].UNIQ_KEY,Inventor.PART_NO,Inventor.REVISION,  
  ---08/12/20 YS added isnull for the warehouse short name
   Inventor.PART_SOURC,Inventor.DESCRIPT, isnull(Warehous.WAREHOUSE,space(10)) as warehouse ,  
     [QTY_OH],[CHANGEAMT],  
     [UPDTSTD].[MATL_COST],[UPDTSTD].[NEWMATLCST],  
     [UPDTSTD].[OLDMATLCST],[UPDTSTD].[OLDSTDCOST],[UPDTSTD].[NEWSTDCOST],  
     [UPDTSTD].RUNDATE ,[UPDTSTD].UPDTDATE ,  
     [UPDTSTD].[UniqWh],[UPDTSTD].[UNIQ_UPDT],  
     FF.Symbol AS Functional_Currency,  
     [CHANGEAMTPR],[UPDTSTD].[MATL_COSTPR],[UPDTSTD].[NEWMATLCSTPR],  
     [UPDTSTD].[OLDMATLCSTPR],[UPDTSTD].[OLDSTDCOSTPR],[UPDTSTD].[NEWSTDCOSTPR],PF.Symbol AS Presentation_Currency  
	 FROM [dbo].[UPDTSTD]   
     INNER JOIN Fcused PF ON UPDTSTD.PrFcused_uniq = PF.Fcused_uniq  
	 INNER JOIN Fcused FF ON UPDTSTD.FuncFcused_uniq = FF.Fcused_uniq  
     INNER JOIN INVENTOR ON UPDTSTD.UNIQ_KEY =INVENTOR.UNIQ_KEY   
	 -- 08/12/2020 Shivshankar P : Change the Inner to left join on WAREHOUS for the transaction are related to records from Unreconciled receipts
     LEFT JOIN WAREHOUS ON UPDTSTD.UniqWh =Warehous.UNIQWH     
     WHERE [UNIQ_UPDT]=@UNIQ_UPDT   
 END