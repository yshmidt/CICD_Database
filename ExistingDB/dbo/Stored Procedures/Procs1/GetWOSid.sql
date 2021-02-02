-- =============================================
-- Author:		Rajendra K 
-- Create date: <02/24/2017>
-- Description:	<Get Sid from WONO> 
-- Modification
   -- 06/08/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros)by existing function 'fremoveLeadingZeros'
   -- 10/31/2017 Rajendra K : Removed use of function fremoveLeadingZeros
   -- 10/31/2017 Rajendra K : Parameter name renamed as per naming conventions
-- =============================================
CREATE PROC [dbo].[GetWOSid]
@woNumber as char(10) 
AS
BEGIN
	SET NOCOUNT ON;	
	SELECT DISTINCT IP.IPKEYUNIQUE AS SID
				   ,(CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.PART_NO ELSE
				     I.PART_NO + ' / '+ I.REVISION END) AS PART_NO
				   ,I.UNIQ_KEY
	FROM IPKEY IP INNER JOIN INVENTOR I ON IP.UNIQ_KEY = I.UNIQ_KEY  WHERE I.USEIPKEY = 1 AND  I.UNIQ_KEY In 
				    (
					 SELECT DISTINCT I.Uniq_Key
					 FROM INVENTOR I
						  INNER JOIN KAMAIN K ON K.UNIQ_KEY=I.UNIQ_KEY 
						  INNER JOIN WOENTRY W ON W.WONO=K.WONO
						  WHERE K.WONO = @woNumber -- 10/31/2017 Rajendra K : Removed use of function fremoveLeadingZeros
						  -- 06/08/2017 -Rajendra K  : Replaced using PATINDEX(To remove leading zeros) by existing function 'fremoveLeadingZeros'
					)
END