-- =============================================
-- Author:Satish B
-- Create date: 04/12/2017
-- Description:	Get PO Number AutoComplete Data When Part Uniq Is Present
-- GetPoNoAutoCompleteWhenPartType '_0050KHV32'
-- =============================================
CREATE PROCEDURE GetPoNoAutoCompleteWhenPartType
  @uniqKey char(10)

 AS
 BEGIN
	 SET NOCOUNT ON
	 SELECT UNIQLNNO,SUBSTRING(PONUM, PATINDEX('%[^0]%', PONUM+'.'), LEN(PONUM)) AS PONUM
	 FROM POITEMS WHERE UNIQ_KEY=@uniqKey
 END
