-- =============================================
-- Author:		Vicky Lu
-- Create date: 06/17/15
-- Description:	Supplier with FC information for FC installed
-- =============================================
CREATE PROC [dbo].[FCSupplierActiveView] AS 

SELECT DISTINCT SupName, fcused.symbol, UniqSupNo, shipbill.fcused_uniq, Supid
	FROM SupInfo, shipbill, fcused
	WHERE Status<>'INACTIVE'
	AND Status<>'DISQUALIFIED'
	AND shipbill.recordtype = 'R'
	AND shipbill.custno = SupInfo.supid
	AND shipbill.fcused_uniq = fcused.fcused_uniq
	ORDER BY SupName, fcused.symbol  