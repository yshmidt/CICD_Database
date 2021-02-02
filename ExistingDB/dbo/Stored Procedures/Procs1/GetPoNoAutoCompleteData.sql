-- =============================================
-- Author:Satish B
-- Create date: 04/12/2017
-- Description:	Get PO Number AutoComplete Data
-- GetPoNoAutoCompleteData
-- =============================================
CREATE PROCEDURE GetPoNoAutoCompleteData
 AS
 BEGIN
	 SET NOCOUNT ON
     SELECT POUNIQUE, SUBSTRING(PONUM, PATINDEX('%[^0]%', PONUM+'.'), LEN(PONUM)) AS PONUM
	 FROM POMAIN 
END

