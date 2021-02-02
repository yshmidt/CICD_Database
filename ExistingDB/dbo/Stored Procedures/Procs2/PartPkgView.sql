

CREATE proc [dbo].[PartPkgView]    
AS
 SELECT left(text,15) as package	FROM Support WHERE Fieldname = 'PART_PKG' order by 1




