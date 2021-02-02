

create proc [dbo].[OpenWorkOrdersView]    
AS
 SELECT woentry.wono FROM woentry WHERE OpenClos<>'Closed' AND OpenClos<>'Cancel' ORDER BY Wono



