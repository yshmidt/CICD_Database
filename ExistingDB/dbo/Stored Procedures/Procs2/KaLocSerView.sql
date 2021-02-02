create procedure dbo.KaLocSerView @lcUniqkalocate as char(10)=null
AS
SELECT Kalocser.uniqkalocser, Kalocser.uniqkalocate, Kalocser.serialno,
  Kalocser.serialuniq, Kalocser.is_overissued
 FROM 
     kalocser
 WHERE  Kalocser.uniqkalocate = ( @lcUniqkalocate )
 ORDER BY Kalocser.serialno