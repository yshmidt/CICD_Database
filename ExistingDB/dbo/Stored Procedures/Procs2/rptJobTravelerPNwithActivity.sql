  
  
-- =============================================  
-- Author:  Vicky  
-- Create date: 04/08/2014  
-- Description: Job Traveler with Activity Report  
-- Modified: 04/08/2014 VL: Create a new sp for Job Traveler with Activity report, requested by UEI  
-- 06/05/2014 DRP:  added the product information to the results (part_no,revision,perpanel,descript,matltype).  
--                  Also had to change the @llDecimal from bit True/False to Yes/No.  I didn't want to do that change, but it was the only way to get it to work for the
--                  time being on WebManex.  The CheckBoxes     
-- 11/27/2018 Sachin B: Add the Parameter @uniqueRout For Get Assembly Routing on the Basis of templates 
-- [rptJobTravelerPNwithActivity] '_1LR0NALBN'
-- =============================================  
CREATE PROCEDURE [dbo].[rptJobTravelerPNwithActivity]   
  
@lcUniqkey char(10) = null,  --Product Number Uniq_key   
@llDecimal char(3) = 'Yes',  --Yes:  display results in Decimal format, No: display the results in hour format  
@uniqueRout char(10) ='' ,
@userId uniqueidentifier= null  
  
AS  
BEGIN  
  
SET NOCOUNT ON;  

;WITH ZQuotdpdt AS  
(  
 SELECT Quotdpdt.Uniqnumber, Quotdpdt.Activ_id, Activity.Activ_name, Quotdpdt.Std_instr, Spec_instr, Quotdpdt.Numbera  
 FROM Quotdpdt, Activity  
 WHERE Activity.Activ_id = Quotdpdt.Activ_id  
   AND Quotdpdt.Uniq_key = @lcUniqkey  
   
)  
 SELECT part_no,Revision,perpanel,Descript,matltype,rtrim(Quotdept.Dept_id) as Dept_id, CASE WHEN @llDecimal = 'Yes' THEN STR(ROUND(Runtimesec/3600,3),7,3) ELSE dbo.fn_ConvertSecondsToHours(Runtimesec) END AS RunTime,  
   CASE WHEN @llDecimal = 'Yes' THEN STR(ROUND(SETUPSEC/3600,3),7,3) ELSE dbo.fn_ConvertSecondsToHours(SETUPSEC) END AS SetupTime,   
   Depts.Dept_name, Quotdept.STD_INSTR AS WC_Std_instr, Quotdept.Spec_instr AS WC_Spec_instr, Inventor.FeedBack, Quotdept.UniqNumber,   
   rtrim(ISNULL(ZQuotdpdt.Activ_id,SPACE(4))) AS Activ_id, ISNULL(ZQuotdpdt.Activ_name,SPACE(25)) AS Activ_name, isnull(ZQuotdpdt.Std_instr,CAST('' as text)) AS ACTV_Std_instr,   
   isnull(ZQuotdpdt.Spec_instr,CAST ('' as text)) AS ACTV_Spec_instr, Quotdept.Number, ISNULL(ZQuotdpdt.Numbera,0) AS Numbera  
 FROM Depts,Inventor,QUOTDEPT   
   LEFT OUTER JOIN ZQuotdpdt ON Quotdept.UNIQNUMBER = ZQuotdpdt.UNIQNUMBER  
 WHERE Depts.Dept_id = Quotdept.Dept_id  
   AND Quotdept.UNIQ_KEY = Inventor.uniq_key  
   AND Quotdept.Uniq_key = @lcUniqkey  
   -- 11/27/2018 Sachin B: Add the Parameter @uniqueRout For Get Assembly Routing on the Basis of templates 
   AND Quotdept.uniqueRout = @uniqueRout   
 ORDER BY Quotdept.Number, ZQuotdpdt.Numbera  
  
END