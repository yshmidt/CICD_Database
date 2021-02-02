-- =============================================
-- Author:Satish B
-- Create date: 04/12/2017
-- Description:	Get Receiver Number AutoComplete Data When Po number I spresent
-- GetRecvNoAutoCompleteDataWhenPo ''
-- =============================================
CREATE PROCEDURE GetRecvNoAutoCompleteDataWhenPo
  @key char(10),
  @value char(10)
  AS
  BEGIN
		 SET NOCOUNT ON
		 DECLARE @poNumFromPoItem char(15),@poNumFromPoMain char(15)
		 IF @key='uniq_Key'
			BEGIN
				SELECT SUBSTRING(receiverHeader.ReceiverNo, PATINDEX('%[^0]%', receiverHeader.ReceiverNo+'.'), LEN(receiverHeader.ReceiverNo)) AS ReceiverNo,
				       receiverHeader.RecPklNo,receiverHeader.ReceiverHdrId,receiverHeader.PONUM 
				FROM receiverHeader receiverHeader
				INNER JOIN receiverDetail receiverDetail ON receiverDetail.receiverHdrId=receiverHeader.receiverHdrId
			END
        ELSE IF @key='poNumber'
			BEGIN
			 SET @poNumFromPoItem = (SELECT PONUM FROM POITEMS WHERE UNIQLNNO=@value);
				SELECT ReceiverHdrId,RecPklNo,SUBSTRING(ReceiverNo, PATINDEX('%[^0]%', ReceiverNo+'.'), LEN(ReceiverNo)) AS ReceiverNo,PONUM 
				FROM receiverHeader 
				WHERE PONUM=@poNumFromPoItem
			END
	    ELSE IF @key='plNumber'
			BEGIN
				SELECT ReceiverHdrId,RecPklNo,SUBSTRING(ReceiverNo, PATINDEX('%[^0]%', ReceiverNo+'.'), LEN(ReceiverNo)) AS ReceiverNo,PONUM 
				FROM receiverHeader 
				WHERE receiverHdrId =@value
			END
  END

  