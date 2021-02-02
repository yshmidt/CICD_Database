-- =============================================
-- Author:		Satyawan H
-- Create date: <05/29/2017>
-- Description:Get Added for Testing the Custom Report
-- =============================================
CREATE PROCEDURE [dbo].[GETPartinfowithLotcode]  
@userid uniqueidentifier
AS
BEGIN
select Part_no,revision,Lotcode,Expdate,Reference,PONum,warehouse,location from inventor i join invtmfgr mf on mf.uniq_key=i.uniq_key
join invtlot lot on lot.w_key=mf.w_key
join warehous wh on wh.uniqwh=mf.uniqwh
END						