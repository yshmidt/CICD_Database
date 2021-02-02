-- =============================================  
-- Author:  <Yelena Shmidt>  
-- Create date: <06-23-2011>  
-- Description: <Procedure used in JE>  
-- Modificatioin:  
-- 10/22/15 VL added Fcused_uniq  
-- 01/21/16 VL added new field AdjustEntry   
-- 03/09/17 VL added functional currency code  
-- 03/27/17 VL separate FC and non-FC code, and added currency field  
-- 06/19/17 VL added EnterCurrBy field   
-- 5/23/2019 Nilesh Sa Updated the Initial with Username
-- =============================================  
CREATE PROCEDURE [dbo].[GLJEHdrOView]  
 -- Add the parameters for the stored procedure here  
 @pcjeohkey as char(10)=' '   
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
-- 03/27/17 VL separate FC and non-FC  
IF dbo.fn_IsFCInstalled() = 0  
 -- 01/21/16 VL added AdjustEntry  
 SELECT Gljehdro.jeohkey, Gljehdro.je_no, Gljehdro.transdate,  
   Gljehdro.saveinit, Gljehdro.app_dt, Gljehdro.reason, Gljehdro.status,  
   Gljehdro.jetype, Gljehdro.reverse, Gljehdro.period, Gljehdro.fy,  
   Gljehdro.reversed, Gljehdro.revperiod, Gljehdro.rev_fy,  
   Gljehdro.app_init,
   aspnet_users.UserName AS AppUserName -- 5/23/2019 Nilesh Sa Updated the Initial with Username
   , Gljehdro.is_rel_gl, Gljehdro.FCUSED_UNIQ,  
   Gljehdro.Adjustentry  
  FROM   
   gljehdro  
   -- 5/23/2019 Nilesh Sa Updated the Initial with Username
   LEFT OUTER JOIN aspnet_users ON gljehdro.SaveUserId = aspnet_users.UserId
  WHERE  Gljehdro.jeohkey = ( @pcjeohkey )  
ELSE  
 -- 01/21/16 VL added AdjustEntry  
 SELECT Gljehdro.jeohkey, Gljehdro.je_no, Gljehdro.transdate,  
   Gljehdro.saveinit, Gljehdro.app_dt, Gljehdro.reason, Gljehdro.status,  
   Gljehdro.jetype, Gljehdro.reverse, Gljehdro.period, Gljehdro.fy,  
   Gljehdro.reversed, Gljehdro.revperiod, Gljehdro.rev_fy,  
   Gljehdro.app_init,
   aspnet_users.UserName AS AppUserName -- 5/23/2019 Nilesh Sa Updated the Initial with Username
   , Gljehdro.is_rel_gl, Gljehdro.FCUSED_UNIQ,  
   Gljehdro.Adjustentry,  
    -- 03/09/17 VL added functional currency fields  
   Gljehdro.PRFCUSED_UNIQ, Gljehdro.FUNCFCUSED_UNIQ, Gljehdro.Fchist_key, Fcused.Currency AS Currency, EnterCurrBy  
  FROM   
   gljehdro LEFT OUTER JOIN Fcused  
   ON GlJehdro.FCUSED_UNIQ = Fcused.FcUsed_Uniq  
   -- 5/23/2019 Nilesh Sa Updated the Initial with Username
   LEFT OUTER JOIN aspnet_users ON gljehdro.SaveUserId = aspnet_users.UserId
   WHERE  Gljehdro.jeohkey = ( @pcjeohkey )  
  
END