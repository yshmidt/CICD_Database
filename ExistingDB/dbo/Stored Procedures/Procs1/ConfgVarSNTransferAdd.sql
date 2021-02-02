 -- =============================================  
-- Author:  <>  
-- Create date: <>  
-- Description: <Used in InvtserSNTransfer SP>  
-- Modified:   
-- 08/25/14 Santosh Lokhande: Remove Uniq_key and Wono from where condition     
-- 08/28/15 VL increased qty numeric(9,2) to (12,2), Ext_cost numeric(12,5) to (25,5),Ext_cost_total numeric(13,5) to (25,5)  
-- 01/31/17 VL added functional currency code  
-- 09/02/17 Sachin b Add parameter transfer quantity and remove serialuniq  
-- 09/02/17 Sachin b remove join with invtser table because for manual tansfer we donot have serialno   
-- 10/05/17 Sachin b pass @TransferQty insted of 1 in stored procedure sp_RollupCost  
-- 09/28/2018 Sachin B Change Numeric data fields size from numeric(12,5) to numeric(13,5) for the following columns SetupScrap_Cost,Ext_costWithoutCEILING,SetupScrap_CostPR,Ext_costWithoutCEILINGPR  
-- 11/04/2019 Sachin B Fix the Issue While the transfer to FGI Put entry in the ConfgVar table when only this (ISNULL(ROUND((@TransferQty*@Matl_cost)-@ITotalXCost,5),0)<>0) calculation having nonzero value remove always true condition 1=1
-- =============================================    
CREATE PROCEDURE [dbo].[ConfgVarSNTransferAdd]      
(      
  @Wono VARCHAR(10),  
  -- 09/02/17 Sachin b Add parameter transfer quantity and remove serialuniq  
  @TransferQty int      
 --,@SerialUniq VARCHAR(10)      
 ,@from_dept_id  VARCHAR(4)      
 ,@to_dept_id  VARCHAR(4)      
 ,@Invtisu_no VARCHAR(10)      
 ,@Invtrec_no VARCHAR(10)      
)      
AS      
BEGIN   
--08/25/14 Santosh Lokhande: Remove Uniq_key and Wono from where condition    
      
 DECLARE @uniq_key char(10), @dDue_Date AS smalldatetime      
  ,@nStdBldQty numeric (8,0) = 0, @nBldQty AS numeric(7,0) = 0 --,@TransferQty as int = 1      
  ,@Matl_Cost AS numeric(13,5) = 0 ,@LaborCost AS numeric(13,5) = 0 ,@Overhead  AS numeric(13,5) = 0      
  ,@OtherCost2  AS numeric(13,5) = 0 ,@Other_Cost  AS numeric(13,5) = 0 ,@ITotalXCost AS numeric(13,5) = 0      
  ,@IRollupCost AS numeric(13,5) = 0 ,@GL_NBR char(13)  
  -- 01/31/17 VL added functional currency code  
  ,@Matl_CostPR AS numeric(13,5) = 0 ,@LaborCostPR AS numeric(13,5) = 0 ,@OverheadPR  AS numeric(13,5) = 0      
  ,@OtherCost2PR  AS numeric(13,5) = 0 ,@Other_CostPR  AS numeric(13,5) = 0 ,@ITotalXCostPR AS numeric(13,5) = 0      
  ,@IRollupCostPR AS numeric(13,5) = 0      
         
 SELECT  @uniq_key=woentry.uniq_key,      
   @dDue_Date=Woentry.Due_date,      
   @nStdBldQty= case       
    when inventor.UseSetScrp = 1 then inventor.StdBldQty      
    else 0      
    end,      
   @Matl_Cost =Inventor.Matl_Cost,      
   @LaborCost =Inventor.LaborCost,      
   @Overhead  =Inventor.Overhead,      
   @OtherCost2  =Inventor.OtherCost2,      
   @Other_Cost  =Inventor.Other_Cost,      
   @Wono = woentry.wono,     
   -- 01/31/17 VL added functional currency code  
   @Matl_CostPR =Inventor.Matl_CostPR,      
   @LaborCostPR =Inventor.LaborCostPR,      
   @OverheadPR  =Inventor.OverheadPR,      
   @OtherCost2PR  =Inventor.OtherCost2PR,      
   @Other_CostPR  =Inventor.Other_CostPR          
 FROM Woentry       
   INNER JOIN inventor on inventor.uniq_key = woentry.uniq_key     
   -- 09/02/17 Sachin b remove join with invtser table because for manual tansfer we donot have serialno   
   --INNER JOIN invtser on invtser.uniq_key = woentry.uniq_key      
 WHERE Woentry.wono = @Wono      
    --AND InvtSer.SerialUniq = @SerialUniq      
    
 --08/25/14 Santosh Lokhande: Remove Uniq_key and Wono from where condition   
 IF @from_dept_id ='FGI'      
 BEGIN      
  SELECT @GL_NBR =GL_NBR       
  FROM Invt_isu      
  WHERE Invtisu_no = @Invtisu_no    
      
 END      
       
 IF @to_dept_id ='FGI'      
 BEGIN      
  SELECT @GL_NBR =GL_NBR       
  FROM invt_rec      
  WHERE Invtrec_no = @Invtrec_no      
 END      
  
-- 08/28/15 VL increased qty numeric(9,2) to (12,2), Ext_cost numeric(12,5) to (25,5),Ext_cost_total numeric(13,5) to (25,5)  
--QtyReqWithoutCEILING numeric(9,2) to (16,2), Ext_cost_totalWithoutCEILING numeric(13,5) to (25,5)  
-- 01/31/17 VL added functional currency code  
-- 09/28/2018 Sachin B Change Numeric data fields size from numeric(12,5) to numeric(13,5) for the following columns SetupScrap_Cost,Ext_costWithoutCEILING,SetupScrap_CostPR,Ext_costWithoutCEILINGPR  
DECLARE @ZResult TABLE (Uniq_key char(10), Part_Sourc char(8), StdCost numeric(13,5),  
   Qty numeric(12,2), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), Phant_Make bit,  
   UniqBomNo char(10), Ext_cost numeric(25,5), SetupScrap_Cost numeric(13,5), Ext_cost_total numeric(25,5),  
   QtyReqTotal numeric(16,2), StdBldQty numeric(8,0), Ext_costWithoutCEILING numeric(13,5),  
   QtyReqWithoutCEILING numeric(16,2), Ext_cost_totalWithoutCEILING numeric(25,5), QtyReqTotalWithoutCEILING numeric(16,2),  
   -- 01/31/17 VL added functional currency code  
   StdCostPR numeric(13,5),Ext_costPR numeric(25,5), SetupScrap_CostPR numeric(13,5), Ext_cost_totalPR numeric(25,5),  
   Ext_costWithoutCEILINGPR numeric(13,5), Ext_cost_totalWithoutCEILINGPR numeric(25,5));  
  
 INSERT INTO @ZResult (Uniq_key, Part_Sourc, StdCost, Qty, U_of_meas, Scrap, SetupScrap, Phant_Make,        
     UniqBomNo, Ext_cost, SetupScrap_Cost, Ext_cost_total, QtyReqTotal, StdBldQty,         
     Ext_costWithoutCEILING, QtyReqWithoutCEILING, Ext_cost_totalWithoutCEILING,         
     QtyReqTotalWithoutCEILING,  
  -- 01/31/17 VL added functional currency code  
  StdCostPR, Ext_costPR, SetupScrap_CostPR, Ext_cost_totalPR, Ext_costWithoutCEILINGPR, Ext_cost_totalWithoutCEILINGPR  
  )    
 -- 10/05/17 Sachin b pass @TransferQty insted of 1 in stored procedure sp_RollupCost        
 exec sp_RollupCost @uniq_key,@dDue_Date,@nStdBldQty,@TransferQty      
   
 -- 01/31/17 VL added functional currency code     
 select  @IRollupCost = ISNULL(SUM(Ext_CostWithoutCeiling) + SUM(SetupScrap_Cost),0),        
 @ITotalXCost = SUM(Ext_Cost_TotalWithoutCeiling) + SUM(SetupScrap_Cost)*1,  
 @IRollupCostPR = ISNULL(SUM(Ext_CostWithoutCeilingPR) + SUM(SetupScrap_CostPR),0),        
 @ITotalXCostPR = SUM(Ext_Cost_TotalWithoutCeilingPR) + SUM(SetupScrap_CostPR)*1              
 from @ZResult      
      
 SELECT *FROM @ZResult      
 ---- Start Transfer from 'FGI' ---    
 -- 01/31/17 VL added functional currency code       
 SELECT @from_dept_id,@ITotalXCost,@TransferQty,@Matl_Cost,@LaborCost,@ITotalXCostPR,@Matl_CostPR,@LaborCostPR   
 if @from_dept_id = 'FGI'      
 BEGIN      
      
  if @ITotalXCost <> @TransferQty*@Matl_Cost       
  BEGIN      
    -- 01/31/17 VL added functional currency code, PrFcused_uniq and FuncFcused_uniq will be updated in trigger       
   INSERT INTO ConfgVar (Wono, Uniq_key, QtyTransf, StdCost, WipCost,Wip_gl_nbr,Variance,      
     TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime,StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono, @Uniq_key, @TransferQty, @Matl_cost, @IRollupCost,@GL_NBR, @IRollupCost - @Matl_cost,       
   ISNULL(ROUND(@ITotalXCost-(@TransferQty * @Matl_cost),5),0),@Invtisu_no,'ISS', 'CONFG', dbo.fn_GetCnfgGl('CONFG'),         
   dbo.fn_GenerateUniqueNumber(),    GETDATE(),  @Matl_costPR, @IRollupCostPR, @IRollupCostPR - @Matl_costPR, ISNULL(ROUND(@ITotalXCostPR-(@TransferQty * @Matl_costPR),5),0)      
  END      
      
  if  0 <> @LaborCost      
  begin  
  -- 01/31/17 VL added functional currency code, PrFcused_uniq and FuncFcused_uniq will be updated in trigger           
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Wip_gl_nbr,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono, @Uniq_key, @TransferQty,@LaborCost,0.00,@GL_NBR,      
    -(@LaborCost),ISNULL( -ROUND((@TransferQty*@LaborCost),5),0), @Invtisu_no,'ISS',        
    'LABOR', dbo.fn_GetCnfgGl('LABOR'), dbo.fn_GenerateUniqueNumber(), GETDATE(), @LaborCostPR,0.00, -(@LaborCostPR),ISNULL( -ROUND((@TransferQty*@LaborCostPR),5),0)      
  end      
      
  if @Overhead <> 0       
  BEGIN  
  -- 01/31/17 VL added functional currency code, PrFcused_uniq and FuncFcused_uniq will be updated in trigger           
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Wip_gl_nbr,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
    SELECT @Wono, @Uniq_key, @TransferQty, @Overhead, 0.00, @GL_NBR,      
     -(@Overhead),ISNULL( -ROUND((@TransferQty *@Overhead),5),0),  @Invtisu_no,'ISS','OVRHD', dbo.fn_GetCnfgGl('OVRHD'),          
     dbo.fn_GenerateUniqueNumber(), GETDATE(), @OverheadPR, 0.00, -(@OverheadPR),ISNULL( -ROUND((@TransferQty *@OverheadPR),5),0)  
  END      
      
  if @OtherCost2 <> 0      
  BEGIN   
  -- 01/31/17 VL added functional currency code, PrFcused_uniq and FuncFcused_uniq will be updated in trigger          
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Wip_gl_nbr,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty, @OtherCost2, 0.00, @GL_NBR,      
     -(@OtherCost2),ISNULL(-ROUND((@TransferQty*@OtherCost2),5),0), @Invtisu_no,'ISS','OTHER', dbo.fn_GetCnfgGl('OTHER'),         
     dbo.fn_GenerateUniqueNumber(), GETDATE(), @OtherCost2PR, 0.00, -(@OtherCost2PR),ISNULL(-ROUND((@TransferQty*@OtherCost2PR),5),0)      
  END        
      
  if @Other_Cost <> 0      
  BEGIN   
  -- 01/31/17 VL added functional currency code, PrFcused_uniq and FuncFcused_uniq will be updated in trigger          
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Wip_gl_nbr,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime,StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty, @Other_Cost ,0.00, @GL_NBR,      
    -(@Other_Cost), ISNULL(-ROUND((@TransferQty*@Other_Cost),5),0),@Invtisu_no,'ISS','USRDF', dbo.fn_GetCnfgGl('USRDF'),         
    dbo.fn_GenerateUniqueNumber(), GETDATE(), @Other_CostPR ,0.00, -(@Other_CostPR), ISNULL(-ROUND((@TransferQty*@Other_CostPR),5),0)      
  END      
      
 END       
      
 ---- END Transfer from 'FGI' ---      
      
 ----- Start Transfer FROM 'SCRP' --      
       
 IF @from_dept_id = 'SCRP'      
 BEGIN      
      
  if @ITotalXCost <> @Matl_Cost      
  BEGIN  
    -- 01/31/17 VL added functional currency code      
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono, @Uniq_key, @TransferQty, @Matl_cost,@IRollupCost,      
     @IRollupCost-@Matl_cost, ISNULL(ROUND(@ITotalXCost-(@TransferQty*@Matl_cost),5),0),        
    dbo.fn_GenerateUniqueNumber(),'  ','CONFG', dbo.fn_GetCnfgGl('CONFG'),dbo.fn_GenerateUniqueNumber(), GetDate(), dbo.fn_GetWIPGl(),  
 @Matl_cost,@IRollupCostPR, @IRollupCostPR-@Matl_costPR, ISNULL(ROUND(@ITotalXCostPR-(@TransferQty*@Matl_costPR),5),0)      
  END      
      
  if @LaborCost <> 0      
  BEGIN  
    -- 01/31/17 VL added functional currency code      
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key,@TransferQty,@LaborCost,0.00,-(@LaborCost),      
    ISNULL(-ROUND((@TransferQty*@LaborCost),5),0), dbo.fn_GenerateUniqueNumber(),'  ', 'LABOR',dbo.fn_GetCnfgGl('LABOR'),         
    dbo.fn_GenerateUniqueNumber(), GETDATE(), dbo.fn_GetWIPGl(),  
 @LaborCostPR,0.00,-(@LaborCostPR), ISNULL(-ROUND((@TransferQty*@LaborCostPR),5),0)      
  END      
      
  if @Overhead <> 0      
  BEGIN  
    -- 01/31/17 VL added functional currency code      
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty, @Overhead,0.00,-(@Overhead),      
    ISNULL(-ROUND((@TransferQty*@Overhead),5),0), dbo.fn_GenerateUniqueNumber(),'  ', 'OVRHD',dbo.fn_GetCnfgGl('OVRHD'),         
    dbo.fn_GenerateUniqueNumber(), GETDATE(), dbo.fn_GetWIPGl(),  
 @OverheadPR,0.00,-(@OverheadPR), ISNULL(-ROUND((@TransferQty*@OverheadPR),5),0)      
  END      
      
  if @OtherCost2 <> 0      
  BEGIN      
  -- 01/31/17 VL added functional currency code      
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,  
   TotalVar,InvtXfer_n, TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty, @OtherCost2,0.00,-(@OtherCost2),      
    ISNULL(-ROUND((@TransferQty*@OtherCost2),5),0),dbo.fn_GenerateUniqueNumber(),'  ','OTHER',dbo.fn_GetCnfgGl('OTHER'),         
    dbo.fn_GenerateUniqueNumber(), GETDATE(), dbo.fn_GetWIPGl(),  
 @OtherCost2PR,0.00,-(@OtherCost2PR), ISNULL(-ROUND((@TransferQty*@OtherCost2PR),5),0)       
  END      
      
  if @Other_Cost <> 0      
  BEGIN      
  -- 01/31/17 VL added functional currency code      
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
    TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty,@Other_Cost,0.00,-(@Other_Cost),      
    ISNULL(-ROUND((@TransferQty*@Other_Cost),5),0),dbo.fn_GenerateUniqueNumber(),'  ','USRDF',dbo.fn_GetCnfgGl('USRDF'),         
    dbo.fn_GenerateUniqueNumber(), GETDATE(), dbo.fn_GetWIPGl(),  
 @Other_CostPR,0.00,-(@Other_CostPR), ISNULL(-ROUND((@TransferQty*@Other_CostPR),5),0)      
  END      
      
 END      
 ----- END Transfer FROM 'SCRP' --      
      
 ----- START Transfer to 'FGI' --      
      
 IF @to_dept_id = 'FGI'      
 BEGIN 
  -- 11/04/2019 Sachin B Fix the Issue While the transfer to FGI Put entry in the ConfgVar table when only this (ISNULL(ROUND((@TransferQty*@Matl_cost)-@ITotalXCost,5),0)<>0) calculation having nonzero value remove always true condition 1=1     
  if ISNULL(ROUND((@TransferQty*@Matl_cost)-@ITotalXCost,5),0)<>0 --if 1-=1 -- If @ITotalXCost <> (@TransferQty*@Matl_Cost)      
  BEGIN  
  -- 01/31/17 VL added functional currency code       
   INSERT INTO ConfgVar (Wono, Uniq_key, QtyTransf, StdCost, WipCost,Wip_gl_nbr,Variance,      
    TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono, @Uniq_key, @TransferQty, @Matl_cost, @IRollupCost,@Gl_nbr, @Matl_Cost-@IRollupCost,       
     ISNULL(ROUND((@TransferQty*@Matl_cost)-@ITotalXCost,5),0),@InvtRec_no,'REC', 'CONFG', dbo.fn_GetCnfgGl('CONFG'),        
     dbo.fn_GenerateUniqueNumber(), GETDATE(),  
  @Matl_costPR, @IRollupCostPR, @Matl_CostPR-@IRollupCostPR, ISNULL(ROUND((@TransferQty*@Matl_costPR)-@ITotalXCostPR,5),0)  
  END      
      
  if @LaborCost <> 0      
  BEGIN  
  -- 01/31/17 VL added functional currency code       
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Wip_gl_nbr,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty,@LaborCost,0.00,@GL_NBR,      
     @LaborCost, ISNULL(ROUND((@TransferQty*@LaborCost),5),0), @InvtRec_no,'REC', 'LABOR',dbo.fn_GetCnfgGl('LABOR'),         
     dbo.fn_GenerateUniqueNumber(), GETDATE(),  
  @LaborCostPR,0.00,  @LaborCostPR, ISNULL(ROUND((@TransferQty*@LaborCostPR),5),0)         
  END      
      
  if @Overhead <> 0      
  BEGIN  
  -- 01/31/17 VL added functional currency code       
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Wip_gl_nbr,Variance,      
     TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty,@Overhead,0.00,@GL_NBR,          
     @Overhead,ISNULL(ROUND((@TransferQty*@Overhead),5),0),@InvtRec_no,'REC', 'OVRHD',dbo.fn_GetCnfgGl('OVRHD'),        
     dbo.fn_GenerateUniqueNumber(), GETDATE(),  
  @OverheadPR,0.00, @OverheadPR,ISNULL(ROUND((@TransferQty*@OverheadPR),5),0)         
  END      
      
  if @OtherCost2 <> 0      
  BEGIN  
  -- 01/31/17 VL added functional currency code       
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Wip_gl_nbr,Variance,      
     TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty, @OtherCost2,0.00,@GL_NBR,      
     @OtherCost2, ISNULL(ROUND((@TransferQty*@OtherCost2),5),0),@InvtRec_no,'REC','OTHER', dbo.fn_GetCnfgGl('OTHER') ,         
  dbo.fn_GenerateUniqueNumber(), GETDATE(),  
  @OtherCost2PR,0.00, @OtherCost2PR, ISNULL(ROUND((@TransferQty*@OtherCost2PR),5),0)         
  END      
      
  if @Other_cost <> 0      
  BEGIN      
   -- 01/31/17 VL added functional currency code     
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Wip_gl_nbr,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty,@Other_Cost,0.00,@GL_NBR,      
     @Other_Cost, ISNULL(ROUND((@TransferQty*@Other_Cost),5),0),@InvtRec_no,'REC', 'USRDF',dbo.fn_GetCnfgGl('USRDF') ,         
     dbo.fn_GenerateUniqueNumber(), GETDATE(),  
  @Other_CostPR,0.00, @Other_CostPR, ISNULL(ROUND((@TransferQty*@Other_CostPR),5),0)         
  END      
 END      
      
 --- END Transfer to 'FGI' --      
      
 --- START Transfer to 'SCRP' ---      
      
 IF @to_dept_id = 'SCRP'      
 BEGIN      
  if @ITotalXCost <> (@TransferQty*@Matl_Cost)      
  BEGIN   
  -- 01/31/17 VL added functional currency code        
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty,@Matl_cost,@IRollupCost,      
     @Matl_cost-@IRollupCost, ISNULL(ROUND(@TransferQty*@Matl_cost-@ITotalXCost,5),0),dbo.fn_GenerateUniqueNumber(),'  ', 'CONFG',         
     dbo.fn_GetCnfgGl('CONFG'), dbo.fn_GenerateUniqueNumber(),  GETDATE(), dbo.fn_GetWIPGl(),  
 @Matl_costPR,@IRollupCostPR, @Matl_costPR-@IRollupCostPR, ISNULL(ROUND(@TransferQty*@Matl_costPR-@ITotalXCostPR,5),0)        
  END      
      
  if @LaborCost <> 0      
  BEGIN  
  -- 01/31/17 VL added functional currency code         
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty,@LaborCost,0.00, @LaborCost,      
     ISNULL(ROUND((@TransferQty*@LaborCost),5),0), dbo.fn_GenerateUniqueNumber(),'  ', 'LABOR',  dbo.fn_GetCnfgGl('LABOR'),        
     dbo.fn_GenerateUniqueNumber(), GETDATE(), dbo.fn_GetWIPGl(),  
  @LaborCostPR,0.00, @LaborCostPR, ISNULL(ROUND((@TransferQty*@LaborCostPR),5),0)      
  END      
      
  if @Overhead <> 0      
  BEGIN  
  -- 01/31/17 VL added functional currency code         
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty,@Overhead,0.00, @Overhead,      
    ISNULL( ROUND((@TransferQty*@Overhead),5),0), dbo.fn_GenerateUniqueNumber(),'  ', 'OVRHD', dbo.fn_GetCnfgGl('OVRHD'),        
     dbo.fn_GenerateUniqueNumber(), GETDATE(), dbo.fn_GetWIPGl(),  
  @OverheadPR,0.00, @OverheadPR, ISNULL( ROUND((@TransferQty*@OverheadPR),5),0)      
  END      
      
  if @OtherCost2<> 0      
  BEGIN  
  -- 01/31/17 VL added functional currency code         
   INSERT INTO ConfgVar (Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
      TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key, @TransferQty,@OtherCost2,0.00, @OtherCost2,      
    ISNULL(ROUND((@TransferQty*@OtherCost2),5),0), dbo.fn_GenerateUniqueNumber(),'  ', 'OTHER',dbo.fn_GetCnfgGl('OTHER'),         
    dbo.fn_GenerateUniqueNumber(), GETDATE(), dbo.fn_GetWIPGl(),  
 @OtherCost2PR,0.00, @OtherCost2PR, ISNULL(ROUND((@TransferQty*@OtherCost2PR),5),0)      
  END      
      
  if @Other_Cost <> 0      
  BEGIN     
  -- 01/31/17 VL added functional currency code       
   INSERT INTO ConfgVar(Wono,Uniq_key,QtyTransf,StdCost,WipCost,Variance,      
     TotalVar,InvtXfer_n,TransfTble, VarType, Cnfg_gl_nb, UniqConf, DateTime, Wip_gl_nbr, StdCostPR, WipCostPR, VariancePR, TotalVarPR)       
   SELECT @Wono,@Uniq_key,@TransferQty,@Other_Cost,0.00, @Other_Cost,      
    ISNULL(ROUND((@TransferQty*@Other_Cost),5),0), dbo.fn_GenerateUniqueNumber(),'  ', 'USRDF',dbo.fn_GetCnfgGl('USRDF'),         
    dbo.fn_GenerateUniqueNumber(), GETDATE(), dbo.fn_GetWIPGl(),  
 @Other_CostPR,0.00, @Other_CostPR, ISNULL(ROUND((@TransferQty*@Other_CostPR),5),0)      
  END      
 END      
 --- END Transfer to 'SCRP' ---      
END