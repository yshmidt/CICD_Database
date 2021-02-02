
CREATE PROCEDURE GetPendingReceiptGridData
	@poNumber char(15)=' ',
	@uniqLnNo char(10)=' '
AS
BEGIN
	
	SELECT receiverHeader.recPklNo AS PackingListNo, dbo.fRemoveLeadingZeros(receiverHeader.receiverno) AS ReceiverNo, receiverDetail.Qty_rec AS Quantity,  'Receiving' AS Disposition
	FROM receiverHeader 
	JOIN receiverDetail ON receiverHeader.receiverHdrId = receiverDetail.receiverHdrId
	WHERE 	((isinspreq=1 AND isinspCompleted = 1) OR (isinspreq=0 AND isinspCompleted = 0)) AND isCompleted = 0 
	AND receiverHeader.ponum = @poNumber AND receiverDetail.uniqlnno = @uniqLnNo
	UNION
	SELECT receiverHeader.recPklNo AS PackingListNo, dbo.fRemoveLeadingZeros(receiverHeader.receiverno) AS ReceiverNo, receiverDetail.Qty_rec AS Quantity, 'Inspection' AS Disposition
	FROM receiverHeader 
	JOIN receiverDetail ON receiverHeader.receiverHdrId = receiverDetail.receiverHdrId
	WHERE isCompleted = 0 AND isinspReq = 1 AND isinspCompleted = 0 
	AND receiverHeader.ponum = @poNumber AND receiverDetail.uniqlnno = @uniqLnNo

END

