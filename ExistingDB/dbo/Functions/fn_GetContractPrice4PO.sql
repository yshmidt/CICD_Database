-- =============================================
-- Author:		Vicky Lu	
-- Create date: <01/23/2015>
-- Description:	<Return contract price based on PO date, part, mfgr, Uniqsupno and qty>
---06/13/18 YS contract structure is changed
-- =============================================
CREATE FUNCTION [dbo].[fn_GetContractPrice4PO]
(
	-- Add the parameters for the function here
	@lcUniq_key char(10) = '',
	@lcPartmfgr char(8) = '', 
	@lcMfgr_pt_no char(30) = '', 
	@lcUniqSupno char(10) = '', 
	@ltPODate smalldatetime = NULL, 
	@lnQty numeric(10,2) = 0.00
	
)
RETURNS numeric(13,5)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @lnReturn numeric(13,5)
	SET @lnReturn = 0.00000
	
	DECLARE @lcMfgr_Uniq char(10), @lnMaxNo int, @lnMinNo int, @lnPrice numeric(13,5)
	DECLARE @ltContPric table (mfgr_uniq char(10), Quantity numeric(10,0), Price numeric(13,5), PriceFC numeric(13,5), nRow int)
	DECLARE @ltContPricFinal table (mfgr_uniq char(10), Quantity numeric(10,0), Price numeric(13,5), PriceFC numeric(13,5), nRow int, BeginQty numeric(10), EndQty numeric(10,0))

	SELECT @lcMfgr_uniq = Mfgr_uniq 
		FROM CONTMFGR inner join CONTRACT
		on CONTMFGR.Contr_uniq = Contract.Contr_uniq 
		AND PARTMFGR = @lcPartmfgr 
		AND Mfgr_pt_no = @lcMfgr_pt_no
		inner join contractheader h on h.contracth_unique=contract.contracth_unique
		AND h.UniqSupno = @lcUniqSupNo
		AND Contract.UNIQ_KEY = @lcUniq_key
		AND 1 = CASE WHEN STARTDATE IS NULL THEN 1 ELSE 
				CASE WHEN @ltPODate >= Startdate THEN 1 ELSE 0 END END
		AND 1 = CASE WHEN Expiredate IS NULL THEN 1 ELSE 
				CASE WHEN @ltPODate <= Expiredate THEN 1 ELSE 0 END END

	INSERT INTO @ltContPric (Mfgr_uniq, Quantity, PRICE, PriceFC, nRow)
		SELECT Mfgr_uniq, Quantity, PRICE, PriceFC, ROW_NUMBER() OVER (PARTITION BY Mfgr_uniq ORDER BY Quantity) AS nRow 
		FROM CONTPRIC WHERE MFGR_UNIQ = @lcMfgr_uniq

	SELECT @lnMaxNo = MAX(nRow), @lnMinNo = MIN(nRow) FROM @ltContPric

	;WITH ZBegQ AS (
		SELECT nRow+1 AS nRow, Quantity + 1 AS BegQty
			FROM @ltContPric
			WHERE nRow<>@lnMaxNo)
	INSERT INTO @ltContPricFinal 
		SELECT ltContPric.*, CASE WHEN ltContPric.nRow = @lnMinNo THEN 0 ELSE ZBegQ.BegQty END AS BeginQty,
			CASE WHEN ltContPric.nRow = @lnMaxNo THEN 9999999999 ELSE ltContPric.Quantity END AS EndQty
			FROM @ltContPric ltContPric LEFT OUTER JOIN ZBegQ
			ON ltContPric.nRow = ZBegQ.nRow
		
	SELECT @lnReturn = PRICE
		FROM @ltContPricFinal 
		WHERE @lnQty>=BeginQty 
		AND @lnQty <=EndQty

	-- Return the result of the function
	RETURN ISNULL(@lnReturn,0.00000)

END

