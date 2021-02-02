-- =============================================  
-- Author:  <Yelena Shmidt>  
-- Create date: <06/22/2011>  
-- Description: <General JE module>  
-- Modification:  
-- 10/22/15 VL added Fcused_uniq  
-- 01/21/16 VL added new field AdjustEntry   
-- 03/09/17 VL added functional currency code  
-- 03/27/17 VL separate FC and non-FC code, and added currency field  
-- 06/19/17 VL added EnterCurrBy field   
-- 5/23/2019 Nilesh Sa Updated the Initial with Username
-- =============================================  
CREATE PROCEDURE [dbo].[GLJEHdrView]  
 -- Add the parameters for the stored procedure here  
 @pcUniqJeHead as char(10)=' '    
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
-- 03/27/17 VL separate FC and non-FC  
IF dbo.fn_IsFCInstalled() = 0  
  -- 01/21/16 VL added AdjustEntry  
  SELECT Gljehdr.je_no, Gljehdr.uniqjehead,   
   Gljehdr.transdate, Gljehdr.posteddt, Gljehdr.saveinit, Gljehdr.app_dt,  
   Gljehdr.reason, Gljehdr.status, Gljehdr.jetype, Gljehdr.period, Gljehdr.fy,  
   Gljehdr.posted, Gljehdr.reversed, Gljehdr.reverse, Gljehdr.revperiod,  
   Gljehdr.rev_fy, Gljehdr.trans_no, Gljehdr.savedate, Gljehdr.app_init,
   aspnet_users.UserName AS AppUserName, -- 5/23/2019 Nilesh Sa Updated the Initial with Username
   gljehdr.FCUSED_UNIQ,  
   Gljehdr.Adjustentry,  
   -- 03/09/17 VL added functional currency fields  
   Gljehdr.PRFCUSED_UNIQ, Gljehdr.FUNCFCUSED_UNIQ  
  FROM   
  gljehdr  
     -- 5/23/2019 Nilesh Sa Updated the Initial with Username
   LEFT OUTER JOIN aspnet_users ON gljehdr.SaveUserId = aspnet_users.UserId
  WHERE  Gljehdr.uniqjehead = ( @pcUniqJeHead )  
ELSE  
  -- 01/21/16 VL added AdjustEntry  
  SELECT Gljehdr.je_no, Gljehdr.uniqjehead,   
   Gljehdr.transdate, Gljehdr.posteddt, Gljehdr.saveinit, Gljehdr.app_dt,  
   Gljehdr.reason, Gljehdr.status, Gljehdr.jetype, Gljehdr.period, Gljehdr.fy,  
   Gljehdr.posted, Gljehdr.reversed, Gljehdr.reverse, Gljehdr.revperiod,  
   Gljehdr.rev_fy, Gljehdr.trans_no, Gljehdr.savedate, Gljehdr.app_init,
   aspnet_users.UserName AS AppUserName, -- 5/23/2019 Nilesh Sa Updated the Initial with Username
   gljehdr.FCUSED_UNIQ,  
   Gljehdr.Adjustentry,  
   -- 03/09/17 VL added functional currency fields  
   Gljehdr.PRFCUSED_UNIQ, Gljehdr.FUNCFCUSED_UNIQ, Gljehdr.Fchist_key, Fcused.Currency AS Currency, EnterCurrBy  
  FROM   
  gljehdr LEFT OUTER JOIN Fcused  
   ON Gljehdr.FCUSED_UNIQ = Fcused.FcUsed_Uniq  
      -- 5/23/2019 Nilesh Sa Updated the Initial with Username
      LEFT OUTER JOIN aspnet_users ON gljehdr.SaveUserId = aspnet_users.UserId
  WHERE  Gljehdr.uniqjehead = ( @pcUniqJeHead )  
END