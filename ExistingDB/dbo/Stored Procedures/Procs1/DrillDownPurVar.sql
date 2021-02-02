-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 10/31/2011
-- Description:	drill down Purchase variance info for release
-- Modification:
-- 12/13/16 VL: added functional and presentation currency fields and separate FC and non FC
-- =============================================
CREATE PROCEDURE [dbo].[DrillDownPurVar]
	-- Add the parameters for the stored procedure here
	@VAR_KEY as char(10)=' '
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
		select pur_var.Trans_date,pur_var.VAR_KEY,pur_var.SDET_UNIQ,pur_var.fk_Uniqaphead,pur_var.SDET_UNIQ,
		Poitems.Ponum,Poitems.ITEMNO,POITEMs.POITTYPE,PUR_VAR.ACPT_QTY ,Pur_var.COSTEACH,Pur_var.STDCOST,Pur_var.VARIANCE,  
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.PART_NO ELSE Poitems.PART_NO  end as Part_no,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.Revision ELSE Poitems.Revision  end as Revision,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.DESCRIPT  ELSE Poitems.DESCRIPT  end as Descript,
		Porecloc.RECEIVERNO 
	from pur_var inner join sinvdetl on pur_var.sdet_uniq =sinvdetl.sdet_uniq
	INNER JOIN porecloc ON SINVDETL.LOC_UNIQ =PORECLOC.LOC_UNIQ    
	INNER JOIN POITEMS on sinvdetl.UNIQLNNO=poitems.UNIQLNNO 
	LEFT OUTER JOIN Inventor on Poitems.uniq_key=Inventor.Uniq_key
	where VAR_KEY=@VAR_KEY 
ELSE
		-- 12/13/16 VL: added functional and presentation currency fields
		-- Insert statements for procedure here
		select pur_var.Trans_date,pur_var.VAR_KEY,pur_var.SDET_UNIQ,pur_var.fk_Uniqaphead,pur_var.SDET_UNIQ,
		Poitems.Ponum,Poitems.ITEMNO,POITEMs.POITTYPE,PUR_VAR.ACPT_QTY ,Pur_var.COSTEACH,Pur_var.STDCOST,Pur_var.VARIANCE, FF.Symbol AS Functional_Currency,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.PART_NO ELSE Poitems.PART_NO  end as Part_no,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.Revision ELSE Poitems.Revision  end as Revision,
		CASE WHEN Poitems.UNIQ_KEY<>' ' THEN Inventor.DESCRIPT  ELSE Poitems.DESCRIPT  end as Descript,
		Porecloc.RECEIVERNO,
		Pur_var.COSTEACHPR,Pur_var.STDCOSTPR,Pur_var.VARIANCEPR, PF.Symbol AS Presentation_Currency 
	from pur_var 
		INNER JOIN Fcused PF ON pur_var.PrFcused_uniq = PF.Fcused_uniq
		INNER JOIN Fcused FF ON pur_var.FuncFcused_uniq = FF.Fcused_uniq	
	inner join sinvdetl on pur_var.sdet_uniq =sinvdetl.sdet_uniq
	INNER JOIN porecloc ON SINVDETL.LOC_UNIQ =PORECLOC.LOC_UNIQ    
	INNER JOIN POITEMS on sinvdetl.UNIQLNNO=poitems.UNIQLNNO 
	LEFT OUTER JOIN Inventor on Poitems.uniq_key=Inventor.Uniq_key
	where VAR_KEY=@VAR_KEY 
END