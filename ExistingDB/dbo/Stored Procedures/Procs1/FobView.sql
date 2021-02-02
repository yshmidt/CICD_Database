

create proc [dbo].[FobView]   
AS
 SELECT  LEFT(TEXT,15) as FOB  FROM SUPPORT WHERE FIELDNAME ='FOB'
 ORDER BY Number





