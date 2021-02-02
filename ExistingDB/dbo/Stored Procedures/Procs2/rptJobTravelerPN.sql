-- =============================================  
-- Author:  Vicky  
-- Create date: 04/01/2014  
-- Description: Job Traveler Report  
-- Modified: 04/01/2014 VL: Create a new sp for Job Traveler report, requested by UEI  
-- 05/30/2014 DRP: added the product information to the results (part_no,revision,perpanel,descript,matltype).   
--				   Also had to change the @llDecimal from bit True/False to Yes/No.  I didn't want to do that change, but it was the only way to get it to work for the time 
--                 being on WebManex.  The CheckBoxes  
-- 11/23/2018 Sachin B: Add the Parameter @uniqueRout For Get Assembly Routing on the Basis of templates
-- [rptJobTravelerPN] 'BBT57SGAQ9','Yes','Z5O50CCZKX'   
-- =============================================  
CREATE PROCEDURE [dbo].[rptJobTravelerPN]   
  
@lcUniqkey char(10) = null,  --Product Number Uniq_key 
@llDecimal char(3) = 'Yes', --Yes:  display results in Decimal format, No: display the results in hour format  
@uniqueRout char(10) ='' ,
@userId uniqueidentifier= null   
  
AS  
BEGIN  
  
SET NOCOUNT ON;  

		SELECT part_no,Revision,perpanel,Descript,matltype,RTRIM(Quotdept.Dept_id) AS Dept_id,
		CASE WHEN @llDecimal = 'Yes' THEN STR(ROUND(Runtimesec/3600,3),7,3) ELSE dbo.fn_ConvertSecondsToHours(Runtimesec) END AS RunTime,  
		CASE WHEN @llDecimal = 'Yes' THEN STR(ROUND(SETUPSEC/3600,3),7,3) ELSE dbo.fn_ConvertSecondsToHours(SETUPSEC) END AS SetupTime,  
		Depts.Dept_name, Std_instr  
		FROM Quotdept, Depts,inventor  
		WHERE Depts.Dept_id = Quotdept.Dept_id  
			  AND Quotdept.Uniq_key = @lcUniqkey  
			  AND QUOTDEPT.UNIQ_KEY = inventor.UNIQ_KEY
			  -- 11/23/2018 Sachin B: Add the Parameter @uniqueRout For Get Assembly Routing on the Basis of templates 
			  AND Quotdept.uniqueRout = @uniqueRout   
			  ORDER BY Quotdept.Number  
  
   
END  
  