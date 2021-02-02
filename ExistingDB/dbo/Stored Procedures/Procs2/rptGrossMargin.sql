-- =============================================
-- Author:		David Sharp
-- Create date: 06/07/2018
-- Description:	Shows the Gross Margin information for all scheduled SO
-- Report Name:	Gross Margin
-- Modification:
-- 05/07/19 VL	SUM(Price) by Uniqueln, so if user set up othe charge(RecordType = 'O'), the price will include it 
-- 08/30/19 VL	Changed column GM% to GMPertage, don't user % to avoid the issue that new Manex cloud can not show columns in quick view
-- =============================================
CREATE PROCEDURE [dbo].[rptGrossMargin] 

	@userId uniqueidentifier=null 
AS
BEGIN

SET NOCOUNT ON;
				
	SELECT c.[CUSTNAME],d.[SONO],dd.[DUE_DTS],i.[PART_NO],i.[REVISION],dd.[QTY],i.[STDCOST],p.[PRICE],dd.[QTY]*p.[PRICE] [ORDERED], dd.[QTY]*i.[STDCOST] [COST],1-((dd.[QTY]*i.[STDCOST])/(dd.[QTY]*p.[PRICE])) [GMPercent]
		FROM dbo.[SODETAIL] d
			INNER JOIN dbo.[SOMAIN] s ON d.[SONO] = s.[SONO]
			INNER JOIN dbo.[CUSTOMER] c ON s.[CUSTNO] = c.[CUSTNO]
			INNER JOIN dbo.[INVENTOR] i ON d.[UNIQ_KEY] = i.[UNIQ_KEY]
			-- 05/07/19 VL	SUM(Price) by Uniqueln, so if user set up othe charge(RecordType = 'O'), the price will include it 
			--INNER JOIN dbo.[SOPRICES] p ON d.[UNIQUELN] = p.[UNIQUELN]
			INNER JOIN (SELECT ISNULL(SUM(Price),0) AS Price, Uniqueln FROM Soprices GROUP BY UNIQUELN) P ON d.[UNIQUELN] = p.[UNIQUELN]
			INNER JOIN dbo.[DUE_DTS] dd ON d.[UNIQUELN] = dd.[UNIQUELN]
		WHERE dd.[QTY] > 0 AND p.[PRICE] > 0

END