-- =============================================                        
-- Author:  Aloha                        
-- Create date: 03/08/2014                        
-- Description: Get PO Total    
-- Modifications: 3/11/14 YS removed extra code                    
-- =============================================       
CREATE PROCEDURE [dbo].[GetPOTotal]
		@gcPonum char(15) = ''  
AS
BEGIN
	DECLARE @Tax_Rate	NUMERIC(5,4) = 0.000,
			@PO_Total	NUMERIC(5,4) = 0.000,
			@Tax_Total	NUMERIC(5,4) = 0.000,
			@ShipChg	NUMERIC(5,4) = 0.000

	DECLARE @temp TABLE(TAX_RATE NUMERIC(5,4),TAXDESC CHAR(25), TAX_ID CHAR(8), LINKADD CHAR(10), UNQSHIPTAX CHAR(10), TAXTYPE CHAR(1), RECORDTYPE CHAR(1))

	INSERT INTO @temp(TAX_RATE,TAXDESC, TAX_ID, LINKADD, UNQSHIPTAX, TAXTYPE, RECORDTYPE)
	EXEC ReceivingTaxView


	SELECT ISNULL(SUM(ROUND((COSTEACH * ORD_QTY),2)),0.00) + pomain.SHIPCHG AS PO_Total,isnull(T.TaxRate,0.0000) as TaxRate,
		SUM(ROUND((CostEach * Ord_qty * CASE WHEN Poitems.IS_TAX = 1 THEN isnull(T.TaxRate,0.00) ELSE 0.00 END )/100,2)) 
		+CASE WHEN Pomain.IS_SCTAX=1 THEN ROUND((PoMain.ShipChg * PoMain.ScTaxPct)/100,2) ELSE 0.00 END
		as TaxTotal ,
		Pomain.IS_SCTAX ,pomain.SHIPCHG ,pomain.SCTAXPCT 
		FROM POITEMS INNER JOIN POMAIN ON Poitems.PONUM=pomain.ponum
		OUTER APPLY 
		(SELECT linkadd,isnull(SUM(TAX_RATE),0.0000) as TaxRate
			FROM @temp INNER JOIN Pomain on Linkadd=i_link WHERE Pomain.Ponum=@gcPonum GROUP BY LinkAdd) T
		WHERE Poitems.Ponum=@gcPonum 
		AND LCANCEL = 0
		GROUP BY t.TaxRate,Pomain.IS_SCTAX ,pomain.SHIPCHG,pomain.SCTAXPCT  

	--SELECT	@Tax_Rate = ISNULL(TMP.TAX_RATE ,0.0000)
	--FROM	@temp TMP
	--JOIN	POMAIN PM WITH(NOLOCK)
	--ON		PM.I_LINK	= TMP.LINKADD
	--WHERE	PM.PONUM	= @gcPonum

	--SELECT	@PO_Total = ISNULL(SUM(ROUND((COSTEACH * ORD_QTY),2)),0.000)
	--FROM	POITEMS WITH(NOLOCK)
	--WHERE	PONUM		= @gcPonum 
	--AND		LCANCEL		= 0

	--SELECT	@Tax_Total	= ISNULL(SUM(ROUND((COSTEACH * ORD_QTY * @Tax_Rate )/100,2)),0.000) 
	--FROM	POITEMS WITH(NOLOCK)
	--WHERE	PONUM		= @gcPonum
	--AND		LCANCEL		= 0
	--AND		IS_TAX		= 1

	--SELECT	@Tax_Total = @Tax_Total + ISNULL(ROUND((Pomain.ShipChg * Pomain.ScTaxPct)/100,2),0.00),
	--		@ShipChg = Pomain.ShipChg
	--FROM	pomain  WITH(NOLOCK)
	--INNER JOIN supinfo  WITH(NOLOCK)
	--ON		Pomain.uniqsupno	= Supinfo.uniqsupno   
	--WHERE	Pomain.ponum		= @gcPonum
	--AND		Pomain.is_sctax		= 1
	--AND		Pomain.shipchg		<> 0.00


	--SELECT	@Tax_Total = @Tax_Total + ISNULL(ROUND((Pomain.ShipChg * Pomain.ScTaxPct)/100,2),0.00),
	--		@ShipChg = Pomain.ShipChg
	--FROM	pomain  WITH(NOLOCK)
	--INNER JOIN supinfo  WITH(NOLOCK)
	--ON		Pomain.uniqsupno	= Supinfo.uniqsupno   
	--WHERE	Pomain.ponum		= @gcPonum
	--AND		Pomain.is_sctax		=1
	--AND		Pomain.shipchg		<> 0.00

	--SELECT @PO_Total + @ShipChg AS PoTotal, @Tax_Total AS PoTax
END	