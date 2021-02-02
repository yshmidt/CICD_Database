-- [dbo].[MnxRptParamGetById]    '3a5ec2da-bc5d-4b8f-ab79-e41781c9f79c','YJ2CJ1CMTG'

-- =============================================  
-- Author:  David Sharp  
-- Create date: 8/10/2013  
-- Description: get parameter details by Id  
-- 03/03/14 DS separated Params from GroupParams for universal application  
-- 08/08/14 YS added bigData column to mnxParamSources table   
-- 10/13/14 Santosh L: Added a temporary table to store the result set.
-- 10/13/14 Santosh L: Check if default sql value is available.
-- 10/13/14 Santosh L: Fetch the default sql query, execute and update back to the temporary table.
 --07/24/18 Shivshankar P: Used to get wmReportsCust data
-- =============================================  
CREATE PROCEDURE [dbo].[MnxRptParamGetById]   
 -- Add the parameters for the stored procedure here  
 @paramId uniqueidentifier  
 ,@rptId varchar(50)=null  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
 DECLARE @pGroup VARCHAR(50)  

 SELECT @pGroup = paramGroup FROM mnxReports WHERE rptId=@rptId  
 IF(@pGroup IS NULL)
 SELECT @pGroup = paramGroup FROM wmReportsCust WHERE rptId=@rptId   -- 07/24/18 Shivshankar P: Used to get wmReportsCust data

    -- Insert statements for procedure here  
 -- 08/08/14 YS added bigData column to mnxParamSources table  
 -- 10/13/14 Santosh L added a temporary table to store the result set
 
  DECLARE @Rpt TABLE (rptparamid uniqueidentifier,paramgroup varchar(15),localizationKey varchar(50), paramname varchar(50),paramtype varchar(50),      
    columnNum int, selectParam char(1),hideFirst bit,onchange varchar(max),addressSp varchar(max),sequence int,sourceLink varchar(100),      
   defaultValue varchar(100),defaultValueSql bit,isFixed bit,cascadeId uniqueidentifier,parentParam varchar(50),finalParam bit,fieldWidth varchar(50),dataSource varchar(max),sourceType varchar(max),bigData bit)     
   INSERT INTO @Rpt    
   select p.rptparamid,paramgroup,p.localizationKey,p.paramname,p.paramType,columnNum,      
    selectParam,hideFirst,onchange,addressSp,sequence, p.sourceLink,      
    defaultValue,defaultValueSql,isFixed,cascadeId,parentParam,finalParam,fieldWidth  ,ps.dataSource,ps.sourceType ,ps.bigData 
  FROM MnxGroupParams g INNER JOIN MnxParams p ON g.fkParamId=p.rptParamId  
  LEFT OUTER JOIN MnxParamSources ps ON p.sourceLink=ps.sourceName     
  WHERE rptParamId =  @paramId   
  AND 1 = CASE WHEN @rptId is null THEN 1 ELSE CASE WHEN paramGroup=@pGroup THEN 1 ELSE 0 END END 
  
  DECLARE @retvalue table (retValue varchar(max)) 
  DECLARE @defaultVal nvarchar(max) 
  
 -- 10/13/14 Santosh L: Check if default sql value is available.
  If (Select DefaultValueSql From @Rpt) = 1
  BEGIN
	 -- 10/13/14 Santosh L: Fetch the default sql query, execute and update back to the temporary table.
     Select @defaultVal=defaultValue From @Rpt where rptParamId =  @paramId     
     INSERT INTO @retValue EXEC sp_executesql @defaultVal
     Update @Rpt set defaultValue = retValue from @retvalue where rptParamId =  @paramId
  END
  
  Select *from @Rpt
END 