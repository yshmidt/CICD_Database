-- =============================================
-- Author:		?
-- Create date: ?
-- Description:	
--- Modified: 07/12/17 YS modify for backword compatibility with the desktop. Rewrite the procedure 
-- Contract moduel was updated with the new structure
-- =============================================
CREATE PROCEDURE [dbo].[GetContractPrice4POView] 
	@lcUniq_key char(10) = '',
	@lcPartmfgr char(8) = '', 
	@lcMfgr_pt_no char(30) = '', 
	@lcUniqSupno char(10) = '', 
	@ltPODate smalldatetime = NULL, 
	@lnQty numeric(10,2) = 0.00

AS
BEGIN
	
	--DECLARE @lcMfgr_Uniq char(10), @lnMaxNo int, @lnMinNo int
	--DECLARE @ltContPric table (mfgr_uniq char(10), Quantity numeric(10,0), Price numeric(13,5), PriceFC numeric(13,5), nRow int)
	--DECLARE @ltContPricFinal table (mfgr_uniq char(10), Quantity numeric(10,0), Price numeric(13,5), PriceFC numeric(13,5), nRow int, BeginQty numeric(10), EndQty numeric(10,0))

	--SELECT @lcMfgr_uniq = Mfgr_uniq 
	--	FROM contractHeader H inner join [CONTRACT] C on h.ContractH_unique=c.contractH_unique
	--	 inner join CONTMFGR M ON C.Contr_uniq = M.Contr_uniq 
	--	WHERE m.PARTMFGR = @lcPartmfgr 
	--	AND m.Mfgr_pt_no = @lcMfgr_pt_no
	--	AND H.UniqSupno = @lcUniqSupNo
	--	AND C.UNIQ_KEY = @lcUniq_key
	--	AND (h.STARTDATE IS NULL or h.Startdate<=@ltPODate)
	--	and (h.[Expiredate] IS NULL or [Expiredate]>=@ltPODate )
		

	--INSERT INTO @ltContPric (Mfgr_uniq, Quantity, PRICE, PriceFC, nRow)
	--	SELECT Mfgr_uniq, Quantity, PRICE, PriceFC, ROW_NUMBER() OVER (PARTITION BY Mfgr_uniq ORDER BY Quantity) AS nRow 
	--	FROM CONTPRIC WHERE MFGR_UNIQ = @lcMfgr_uniq

	--SELECT @lnMaxNo = MAX(nRow), @lnMinNo = MIN(nRow) FROM @ltContPric

	--;WITH ZBegQ AS (
	--	SELECT nRow+1 AS nRow, Quantity + 1 AS BegQty
	--		FROM @ltContPric
	--		WHERE nRow<>@lnMaxNo)
	--INSERT INTO @ltContPricFinal 
	--	SELECT ltContPric.*, CASE WHEN ltContPric.nRow = @lnMinNo THEN 0 ELSE ZBegQ.BegQty END AS BeginQty,
	--		CASE WHEN ltContPric.nRow = @lnMaxNo THEN 9999999999 ELSE ltContPric.Quantity END AS EndQty
	--		FROM @ltContPric ltContPric LEFT OUTER JOIN ZBegQ
	--		ON ltContPric.nRow = ZBegQ.nRow
		
	--SELECT PRICE,PriceFC
	--	FROM @ltContPricFinal 
	--	WHERE @lnQty>=BeginQty 
	--	AND @lnQty <=EndQty
	---07/12/17 YS new code
	;with
	 tqtyRange
	 as
	 (
	select h.uniqsupno, h.contractH_unique,h.contractNote,h.startDate,h.expireDate,
	c.CONTR_UNIQ,c.UNIQ_KEY,m.PARTMFGR,m.MFGR_PT_NO,m.MFGR_UNIQ,
	p.PRICE ,p.PriceFC,pricepr,p.QUANTITY, ROW_NUMBER() over (order by quantity) as nrow,max(QUANTITY) over() as maxQty
	--INTO  #tqtyRange
	from contractHeader h inner join CONTRACT c on h.ContractH_unique=c.contractH_unique
	inner join CONTMFGR m on m.CONTR_UNIQ=c.CONTR_UNIQ
	inner join CONTPRIC p on p.MFGR_UNIQ=m.MFGR_UNIQ 
	where c.UNIQ_KEY=@lcUniq_key
	and m.PARTMFGR=@lcPartmfgr
	and m.MFGR_PT_NO=@lcMfgr_pt_no
	and h.uniqsupno=@lcUniqSupno 
	and (h.STARTDATE IS NULL or h.Startdate<=@ltPODate)
		and (h.[Expiredate] IS NULL or [Expiredate]>=@ltPODate ) 
		--order by QUANTITY
	),

		--;with
		CTE
		as (
			SELECT price,pricepr,pricefc,quantity, cast(nrow as numeric(10,0)) as startQty,QUANTITY AS endQty,nrow,maxQty 
		      FROM tqtyRange where nrow=1
			---select * from cte
			 UNION ALL
			 SELECT p.price,p.pricepr,p.pricefc,p.quantity, cast(c.endqty+1.00 as numeric(10,0)) as startQty,p.QUANTITY AS endQty,p.nrow ,p.maxQty
			FROM CTE c
			inner JOIN tqtyRange p ON c.nrow+1=p.nrow
			)
			select price,pricepr,pricefc from cte 
			where ( @lnqty between startQty and endqty ) or (@lnqty>maxQty and endQty=maxQty)

END


