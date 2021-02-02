 -- =============================================
-- Author:Satish B
-- Create date: 04/12/2017
-- Description:	Get Po Number AutoComplete Data When PL Number Is Present
-- GetPoNoAutoCompleteWhenPartType '_0050KHV32'
-- =============================================
CREATE PROCEDURE GetPoNoAutoCompleteWhenPLNo
  @rcvHdrId char(10)

 AS
 BEGIN
	 SET NOCOUNT ON
	 SELECT ReceiverHdrId,SUBSTRING(PONUM, PATINDEX('%[^0]%', PONUM+'.'), LEN(PONUM)) AS PONUM,RecPklNo
	 FROM ReceiverHeader WHERE ReceiverHdrId=@rcvHdrId
 END

 