-- =============================================
-- Author:		Rajendra K 
-- Create date: <02/24/2017>
-- Description:	<Get Sid from WONO> 
-- Modification
  -- 06/08/2017 Rajendra K : Replaced using PATINDEX(To remove leading zeros)by existing function 'fremoveLeadingZeros'
  -- 10/31/2017 Rajendra K : Removed use of function fremoveLeadingZeros
  -- 10/31/2017 Rajendra K : Parameter name renamed as per naming conventions
-- =============================================
CREATE PROC [dbo].[GetPartNoList]
@woNumber AS CHAR(10) 
AS
BEGIN	
	 SET NOCOUNT ON;
	 SELECT DISTINCT I.Uniq_Key
					,I.PART_NO + (CASE WHEN I.REVISION IS NULL OR I.REVISION = '' THEN I.REVISION ELSE '/'+ I.REVISION END) AS PART_NO
	 FROM INVENTOR I
		  INNER JOIN KAMAIN k ON k.UNIQ_KEY=I.UNIQ_KEY 
		  INNER JOIN WOENTRY w ON w.WONO=k.WONO
	WHERE k.WONO = @woNumber -- 10/13/2017 Rajendra K : Removed use of function fremoveLeadingZeros
	-- 06/08/2017 -Rajendra K  : Replaced using PATINDEX(To remove leading zeros) by existing function 'fremoveLeadingZeros'
END
