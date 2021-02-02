-- =============================================
-- Author:Satish B
-- Create date: 04/12/2017
-- Description:	Get Part Number AutoComplete Data When PO Number Is Present
-- GetPartNoAutoCompleteWhenPo '','0000000817'
-- =============================================
CREATE PROCEDURE GetPartNoAutoCompleteWhenPo
  @poUniq char(10),
  @rcvNumber char(10)

 AS
 BEGIN
	 SET NOCOUNT ON
	 DECLARE @poNum char(15)
	 IF @poUniq<>''
	   BEGIN
			SET @poNum=(SELECT PONUM FROM POMAIN WHERE POUNIQUE=@poUniq)
			IF @poNum=''
				BEGIN
					SET @poNum=(SELECT poMain.PONUM FROM POMAIN poMain 
					            INNER JOIN ReceiverHeader receiverHeader ON receiverHeader.ponum=poMain.PONUM
								WHERE receiverHeader.receiverHdrId=@poUniq )
				END
            SELECT (invt.Part_No  +'/'+invt.Revision) AS Part_No,invt.Uniq_Key FROM INVENTOR invt
			INNER JOIN POITEMS poItems ON poItems.UNIQ_KEY=invt.UNIQ_KEY
			WHERE poItems.PONUM=@poNum 
	   END
     ELSE
	   BEGIN
			 SELECT (invt.Part_No  +'/'+invt.Revision) AS Part_No,invt.Uniq_Key FROM INVENTOR invt
			INNER JOIN POITEMS poItems ON poItems.UNIQ_KEY=invt.UNIQ_KEY
			INNER JOIN porecdtl poRecDtl ON poRecDtl.uniqlnno=poItems.UNIQLNNO
			WHERE poRecDtl.receiverno=@rcvNumber
	   END
 END

 