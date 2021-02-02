-- =============================================  
-- Author: Shripati U   
-- Create date: 08/11/18  
-- Description: Get BOMChangeLog Details  
-- BOMChangeLogDetail  '_3SX0TLY16'  
-- 06/07/2019 Shrikant added left join with aspnet_Users table for getting username
-- 10/26/2018 Shrikant Added column ChangeInfo  
-- =============================================  
CREATE PROCEDURE [dbo].[BOMChangeLogDetail]   
 -- Add the parameters for the stored procedure here  
 @BOMParentKey CHAR(10)  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
-- 10/26/2018 Shrikant Added column ChangeInfo  
 SELECT b.*,i.PART_SOURC, i.PART_TYPE, i.PART_CLASS, i.CUSTNO, i.PART_NO, i.REVISION, i.CUSTPARTNO, i.CUSTREV, i.DESCRIPT, i.U_OF_MEAS,   
 au.UserName, ChangeInfo FROM dbo.BOMChangeLog b   
 JOIN dbo.INVENTOR i ON(b.UNIQ_KEY = i.UNIQ_KEY) JOIN dbo.aspnet_Profile ap  ON (b.ModifiedBy=ap.UserId)  
 -- 06/07/2019 Shrikant added left join with aspnet_Users table for getting username
 LEFT JOIN aspnet_Users au ON b.ModifiedBy=au.UserId
 WHERE  BOMPARENT=@BOMParentKey  
    
END  
  
  
  