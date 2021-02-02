-- =============================================
-- Author:Satish B
-- Create date: 04/12/2017
-- Description:	Get Packing List Number AutoComplete Data When Po number I spresent
-- GetPlNoAutoCompleteDataWhenPo ''
-- =============================================
CREATE PROCEDURE GetPlNoAutoCompleteDataWhenPo
  @key char(10),
  @value char(10)
  AS
  BEGIN
		 SET NOCOUNT ON
		 DECLARE @poNumFromPoItem char(15),@poNumFromPoMain char(15)
		 IF @key='poNumber'
			BEGIN
				SET @poNumFromPoItem=(SELECT PONUM FROM POITEMS WHERE UNIQLNNO=@value)
				IF @poNumFromPoItem=''
					BEGIN
						SET @poNumFromPoMain=(SELECT PONUM FROM POMAIN WHERE POUNIQUE=@value)
						SELECT ReceiverHdrId,RecPklNo,ReceiverNo,PONUM FROM receiverHeader WHERE PONUM=@poNumFromPoMain
					END
                ELSE
					BEGIN
						SELECT ReceiverHdrId,RecPklNo,ReceiverNo,PONUM FROM receiverHeader WHERE PONUM=@poNumFromPoItem
					END
			END
        ELSE IF @key='rcvNumber'
			BEGIN
				SELECT ReceiverHdrId,RecPklNo,ReceiverNo,PONUM FROM receiverHeader WHERE ReceiverHdrId=@value
			END
		 
  END
