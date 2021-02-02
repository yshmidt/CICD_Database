  
-- =============================================  
-- Author:  <Yelena Shmidt>  
-- Create date: <03/11/2010>  
-- Description: <PoOnOrderView>  
-- Modified: 05/20/14 YS added itemno  
-- Modified: 06/09/2017 Rajendra K : Added Initials(Buyer)   
-- Modified: 05/23/2019 Sachin B : Change the join table aspnet_Profile to aspnet_Users for getting UserName  
-- Modified: 09/17/2020 Rajendra K : Added PoStatus in selection list
-- =============================================  
CREATE PROCEDURE [dbo].[PoOnOrderView]  
 -- Add the parameters for the stored procedure here  
 @gUniq_key char(10)=' '   
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    -- Modified: 05/20/14 YS added itemno  
  -- Modified: 05/23/2019 Sachin B : Change the join table aspnet_Profile to aspnet_Users for getting UserName  
 SELECT Poitschd.schd_date, Supinfo.supname, Pomain.ponum,Poitems.Itemno,Poitems.partmfgr,Poitems.Mfgr_pt_no,POITEMS.UNIQMFGRHD,    
   Poitems.costeach, Poitschd.balance, Poitschd.req_date,POITSCHD.LOCATION,POITSCHD.UNIQWH,ap.UserName AS Initials -- 06/09/2017 -Rajendra K : Added ap.Initials to get Buyer  
   ,pomain.POSTATUS-- Modified: 09/17/2020 Rajendra K : Added PoStatus in selection list   
 FROM pomain   
  LEFT JOIN aspnet_Users ap on pomain.aspnetBuyer = ap.userid,supinfo,poitschd,poitems -- 06/09/2017 Rajendra K : Added aspnet_profile table in join list to get Buyer  
 WHERE Pomain.ponum = Poitems.ponum  
    AND  Supinfo.uniqsupno = Pomain.uniqsupno   
    AND  Poitschd.uniqlnno = Poitems.uniqlnno  
    AND  Poitems.uniq_key = @gUniq_key  
    AND  Poitems.lcancel = 0  
    AND  Pomain.postatus <> 'CANCEL'  
    AND  Pomain.postatus <>  'CLOSED'  
    AND  Poitschd.balance >  0   
    ORDER BY Poitschd.schd_date  
END