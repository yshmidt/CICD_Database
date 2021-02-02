CREATE PROCEDURE [dbo].[LeadTimeCalc] 
	@pcUniq_key char(10),
    @pcType nvarchar(10),
	@pnReturnDays int OUTPUT
	
AS	
	SELECT  @pnReturnDays =
		CASE 
			WHEN @pcType = 'BUY' AND Pur_lUnit = 'DY' THEN Pur_ltime
			WHEN @pcType = 'BUY' AND Pur_lUnit = 'WK' THEN Pur_ltime * 5
			WHEN @pcType = 'BUY' AND Pur_lUnit = 'MO' THEN Pur_ltime * 20
			WHEN (@pcType = 'MAKE' OR @pcType = 'PHANTOM') AND Prod_lUnit = 'DY' THEN Prod_ltime
			WHEN (@pcType = 'MAKE' OR @pcType = 'PHANTOM') AND Prod_lUnit = 'WK' THEN  Prod_ltime*5
			WHEN (@pcType = 'MAKE' OR @pcType = 'PHANTOM') AND Prod_lUnit = 'MO' THEN  Prod_ltime*20
			WHEN @pcType = 'KIT' AND Kit_lUnit = 'DY' THEN Kit_lTime
			WHEN @pcType = 'KIT' AND Kit_lUnit = 'WK' THEN Kit_lTime * 5
			WHEN @pcType = 'KIT' AND Kit_lUnit = 'MO' THEN Kit_ltime * 20
		ELSE 0
		END  
	FROM Inventor WHERE Uniq_key=@pcUniq_key
	

