-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/01/2011
-- Description:	drill down Unreconciled account
-- Modification:
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownUNRECREC]
	-- Add the parameters for the stored procedure here
	@UniqRecRel as integer
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- 12/13/16 VL added to check if FC is installed or not, if yes, need to get the currency 
DECLARE @lFCInstalled bit
SELECT @lFCInstalled = dbo.fn_IsFCInstalled()

IF @lFCInstalled = 0
		-- Insert statements for procedure here
		select PORECRELGL.Trans_date,Porecrelgl.UNIQRECREL,Porecrelgl.LOC_UNIQ,
		Poitems.Ponum,Poitems.ITEMNO,POITEMs.POITTYPE,Porecrelgl.TRANSQTY,Porecrelgl.STDCOST,Porecrelgl.TOTALCOST,  
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.PART_NO ELSE Poitems.PART_NO  end as Part_no,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.Revision ELSE Poitems.Revision  end as Revision,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.DESCRIPT  ELSE Poitems.DESCRIPT  end as Descript,
		Porecloc.RECEIVERNO 
	from PORECRELGL INNER JOIN porecloc ON Porecrelgl.LOC_UNIQ =PORECLOC.LOC_UNIQ    
	INNER JOIN PORECDTL on Porecloc.FK_UNIQRECDTL =Porecdtl.UNIQRECDTL  
	INNER JOIN POITEMS on Porecdtl.UNIQLNNO=poitems.UNIQLNNO 
	LEFT OUTER JOIN Inventor on Poitems.uniq_key=Inventor.Uniq_key
	where Uniqrecrel=@UniqRecRel  
ELSE
		-- 12/13/16 VL added presentation and functional currency fields
		-- Insert statements for procedure here
		select PORECRELGL.Trans_date,Porecrelgl.UNIQRECREL,Porecrelgl.LOC_UNIQ,
		Poitems.Ponum,Poitems.ITEMNO,POITEMs.POITTYPE,Porecrelgl.TRANSQTY,Porecrelgl.STDCOST,Porecrelgl.TOTALCOST, FF.Symbol AS Functional_Currency,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.PART_NO ELSE Poitems.PART_NO  end as Part_no,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.Revision ELSE Poitems.Revision  end as Revision,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.DESCRIPT  ELSE Poitems.DESCRIPT  end as Descript,
		Porecloc.RECEIVERNO, Porecrelgl.STDCOSTPR,Porecrelgl.TOTALCOSTPR, PF.Symbol AS Presentation_Currency 
	from PORECRELGL 
		INNER JOIN Fcused PF ON PORECRELGL.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON PORECRELGL.FuncFcused_uniq = FF.Fcused_uniq	
	INNER JOIN porecloc ON Porecrelgl.LOC_UNIQ =PORECLOC.LOC_UNIQ    
	INNER JOIN PORECDTL on Porecloc.FK_UNIQRECDTL =Porecdtl.UNIQRECDTL  
	INNER JOIN POITEMS on Porecdtl.UNIQLNNO=poitems.UNIQLNNO 
	LEFT OUTER JOIN Inventor on Poitems.uniq_key=Inventor.Uniq_key
	where Uniqrecrel=@UniqRecRel 
END